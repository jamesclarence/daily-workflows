var queue = require('queue-async'),
    nodemailer = require('nodemailer'),
    tvConfig = require('./../config.json'),
    tv = require('trackvia')(tvConfig),
    configs = require('./config.json'),
    CSV = require('comma-separated-values'),
    fs = require('fs'),
    _ = require('underscore'),
    tasks = queue(1),
    emailConfig = JSON.parse(fs.readFileSync('./email.config')),
    mailer = nodemailer.createTransport({
      service: 'Mandrill',
      auth: {
        user: emailConfig.username,
        pass: emailConfig.password
      }
    });

configs.forEach(function(config) {
  tasks.defer(runTask, config);
});

// Send notifications
tasks.awaitAll(function(err, data) {
  var mailOptions = {
    from: emailConfig.username,
    to: emailConfig.to,
    subject: emailConfig.subject,
    text: emailConfig.message
  };

  mailer.sendMail(mailOptions, function(error, info) {
    if(error) {
      console.log(error);
    } else {
      console.log('Message sent: ' + info.response);
    }
  });
});

function runTask(config, nextTask) {
  var input = [],
      q = queue();

  if (typeof config.source === 'string') config.source = [config.source];
  config.sources.forEach(function(source, index) {
    q.defer(loadSource, source);
  });
  q.awaitAll(combineSources);

  function loadSource(source, cb) {
    var output = '';

    if (source.type && source.type.toLowerCase() === 'trackvia') {
      var page = 1,
          results = [];
      getRecords(function(data) {
        output = data;
        fs.writeFile('./tmp/' + source.name + '.csv', output, function(err) {
          if (err) {
            cb(err, null);
          } else {
            cb(null, true);
          }
        });
      });
      function getRecords(cb) {
        tv.views(source.view, { limit: 100, page: page }, function(err, res) {
          if (err) throw err;
          if (res.records && res.records.length) {
            results = results.concat(res.records);
            page = page + 1;
            getRecords(cb);
          } else {
            results = _(results).chain()
              .map(function(item) { return item.fields; })
              .sortBy(function(item) { return -_(item).size(); })
              .value();
            var csv = new CSV(results, { header: true, cast: false }).encode()
                .replace(/"undefined"/g, '""')
                .replace(/<!--tvia_br--><br><!--tvia_br-->/g, '\n');
            cb(csv);
          }
        });
      }
    } else {
      var spawn = require('child_process').spawn,
          child = spawn('curl', [
            '-s', '--ssl-reqd', '-K', 'ftp.config' , source.url
          ], { maxBuffer: 200 * 1024 * 1024 });

      child.stdout.setEncoding('utf8');
      child.stderr.setEncoding('utf8');
      child.stdout.on('data', function (data) { output += data; });
      child.stderr.on('data', function (data) { cb(data, null); });
      child.on('exit', function (code, signal) {
        if (!output.length) {
          // TODO: retry downloading empty files after delay
        }
        fs.writeFile('./tmp/' + source.name + '.csv', output, function(err) {
          if (err) {
            cb(err, null);
          } else {
            cb(null, true);
          }
        });
      });
    }
  }

  function combineSources(err, data) {
    if (!err && !data) err = 'Sources returned no data.';
    if (err) throw err;
    runProcess();
  }

  function runProcess() {
    var spawn = require('child_process').spawn,
        args = [config.script],
        child = spawn('Rscript', args),
        output = '';

    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');
    child.stdout.on('data', function(data) {
      output += data;
    });
    child.stderr.on('data', function(data) {
      console.log(data);
    });
    child.on('error', function(data) {
      throw data;
    });
    child.on('exit', function(data) {
      sendOutput(output);
    });
  }

  function sendOutput(data) {
    var exec = require('child_process').exec;

    if (typeof config.outputFile === 'string') {
      fs.writeFile(config.outputFile, data, function(err) {
        if (err) throw err;

        var xlsFile = config.outputFile.replace(/\.csv$/, '.xls'),
            cmd = 'csv2xls "' + config.outputFile + '" -o "' + xlsFile + '"';

        console.log('Saved file: ' + config.outputFile);

        // Convert to XLS
        exec(cmd, function(stdout, stderr, err) {
          if (err) throw err;
          console.log('Saved file: ' + xlsFile);

          // Upload to FTPS
          var spawn = require('child_process').spawn,
              child = spawn('curl', [
                '-s', '--ssl-reqd',
                '-T', xlsFile,
                '-K', 'ftp.config',
                'ftp://camdenhie.careevolution.com/CCHPProcessed/'
              ], { maxBuffer: 200 * 1024 * 1024 }),
              output = '';
    
          child.stdout.setEncoding('utf8');
          child.stderr.setEncoding('utf8');
          child.stderr.on('data', function (data) { cb(data, null); });
          child.on('exit', function (code, signal) {
            console.log('Uploaded file: ' + xlsFile);
          });

        });
      })
      nextTask();
      return;
    }

    data = new CSV(data, { header: true, cast: false }).parse();

    switch (config.output.operation) {
      case 'add':
        tv.tables(config.output.table, function(err, res) {
          if (err) console.warn('Table loading error: ', err);
          var fields = res.coldefs.map(function(col) { return col.label; }),
              foreignKeys = {},
              key_q = queue(1),
              usedFields = [],
              errors = [];

          // Remove fields from data that aren't in the TV table
          data = _(data.map(function(item) {
            var out = {};
            fields.forEach(function(field) {
              if (item[field]) {
                out[field] = item[field];
                usedFields.push(field);
              }
            });
            return out;
          })).filter(function(o) {return _(o).size(); });

          // Find fields with foreign keys
          res.coldefs.forEach(function(col) {
            if (col.type === 'foreign_key') {
              foreignKeys[col.label] = col.foreign_key_id;
            }
          });

          // For each foreign key field that is actually used, get values
          _(foreignKeys).forEach(function(value, key) {
            if (usedFields.indexOf(key) >= 0) {
              key_q.defer(function(cb) {
                tv.tables(config.output.table, value, function(err, data) {
                  var o = {};
                  o[key] = data;
                  cb(err, o);
                });
              });
            }
          });

          key_q.awaitAll(function(err, keys) {
            if (err) console.warn('Foreign key loading error: ', err);
            keys = _(keys).reduce(function(item, memo) {
              return _(memo).extend(item);
            }, {});

            // Loop through data, and filter out records that don't match keys
            _(data).forEach(function(item, index) {
              _(keys).forEach(function(parentKeys, field) {
                if (parentKeys.indexOf(item[field]) < 0) {
                  var errorItem = _(item).clone();
                  errorItem['error_field'] = field;
                  errors.push(errorItem);
                  delete data[index];
                }
              });
            });
            data = _(data).compact();
            fs.writeFileSync(config.outputFile + '.records.csv', JSON.stringify(data));
            fs.writeFileSync(config.outputFile + '.errors.csv', JSON.stringify(errors));
            nextTask();
          });

/*
          tv.records({
            method: 'POST',
            table_id: config.output.table,
            data: data,
          }, function(err, res) {
            if (err) console.warn(err);
            console.log(res);
          });
*/
        });
        break;
      case 'update':
        break;
      case 'add-update':
        break;

    }
  }
}

process.on('exit', function() {
  // Remove temp files
  require('child_process').exec('srm -sr ./tmp/*');
  console.log('Cleaning up temp files');
});
