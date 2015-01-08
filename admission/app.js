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

  // TODO: Inline error images
  // TODO: Send console output in email

  var mailOptions = {
    from: emailConfig.username,
    to: emailConfig.to,
    subject: emailConfig.subject,
    text: emailConfig.message
  };

  mailer.sendMail(mailOptions, function(error, info) {
    if(error) {
      console.log(error);
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
    var output = '',
        downloadRetries = 0,
        page = 1,
        results = [];

    if (source.type && source.type.toLowerCase() === 'trackvia') {
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
      downloadFile();
    }

    function downloadFile() {
      downloadRetries++;

      var spawn = require('child_process').spawn,
          child = spawn('curl', [
            '-s', '--ssl-reqd', '-K', 'ftp.config' , source.url
          ], { maxBuffer: 200 * 1024 * 1024 });
      child.stdout.setEncoding('utf8');
      child.stderr.setEncoding('utf8');
      child.stdout.on('data', function (data) { output += data; });
      child.stderr.on('data', function (data) { cb(data, null); });
      child.on('exit', function (code, signal) {
        if (!output.length && downloadRetries < 5) {
          downloadFile();
        } else if (!output.length) {
          cb('File downloaded from FTP is empty. Is the FTP available?', null);
        } else {
          fs.writeFile('./tmp/' + source.name + '.csv', output, function(err) {
            if (err) {
              cb(err, null);
            } else {
              cb(null, true);
            }
          });
        }
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

      // Save CSV file
      fs.writeFile(config.outputFile, data, function(err) {
        if (err) throw err;

        var xlsFile = config.outputFile.replace(/\.csv$/, '.xls'),
            cmd = 'csv2xls "' + config.outputFile + '" -o "' + xlsFile + '"';

        console.log('Saved file: ' + config.outputFile);

        // Save copy as XLS
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
            console.log('Uploaded file to FTP: ' + xlsFile);

            // Upload to TrackVia
            var child = spawn('casperjs', [
                  './tv-upload.js',
                  config.output.table,
                  config.outputFile.replace(/\.csv$/, '.xls'),
                  config.output.fields
                ]),
                scriptName = config.script.split('/')[1].replace(/\.R$/, ''),
                out = '',
                err = ''
          
            console.log('Uploading ' + scriptName + ' to table: ' + config.output.tableName);
          
            child.stdout.setEncoding('utf8');
            child.stderr.setEncoding('utf8');
            child.stdout.on('data', function (data) { console.log(data); });
            child.stderr.on('data', function (data) {
              err += data;
              console.warn(data);
            });
            child.on('exit', function (code, signal) {
              console.log('------');
              if (err.length) {
                nextTask(err, null);
              } else {
                nextTask(null, true);
              }
            });
          });

        });
      });
    }

  }
}

process.on('exit', function() {
  // Remove temp files
  // Should also remove output files
  require('child_process').exec('srm -sr ./tmp/*');
  console.log('Cleaning up temp files');
});
