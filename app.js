var queue = require('queue-async'),
    nodemailer = require('nodemailer'),
    tvConfig = {
      username: process.env.TV_USER,
      password: process.env.TV_PASSWORD,
      client_id: process.env.TV_CLIENT_ID,
      client_secret: process.env.TV_CLIENT_SECRET
    },
    ftpAuth = process.env.FTP_USER + ':' + process.env.FTP_PASSWORD,
    tv = require('trackvia')(tvConfig),
    configs = require('./config.json'),
    CSV = require('comma-separated-values'),
    fs = require('fs'),
    _ = require('underscore'),
    tasks = queue(1),
    emailConfig = {
      to: process.env.EMAIL_TO,
      host: 'smtp.mandrillapp.com',
      username: process.env.EMAIL_USER,
      password: process.env.EMAIL_PASSWORD,
      subject: '[CCHP Automation] Files Updated',
      message: "<p>The automation script just finished. Here's the log:</p><p>------</p>"
    },
    mailer = nodemailer.createTransport({
      service: 'Mandrill',
      auth: {
        user: emailConfig.username,
        pass: emailConfig.password
      }
    }),
    images = [],
    logs = '',
    log = console.log,
    timeout = 1000 * 30; // 30 seconds

// Capture console.log
console.log = function(){
  logs += '<p>' + Array.prototype.slice.call(arguments).join(' ') + '</p>';
  log.apply(this, arguments)
}

// Queue config tasks
configs.forEach(function(config) {
  tasks.defer(runTask, config);
});

// Send notifications
tasks.awaitAll(function(err, data) {

  if (err) {
    console.warn(err);
  }

  var subject = (images.length) ? 'Import Error: ' + emailConfig.subject :
                                  'Success: ' + emailConfig.subject;

  var mailOptions = {
    from: emailConfig.username,
    to: emailConfig.to,
    subject: subject,
    attachments: images,
    html: emailConfig.message + logs 
  };

  mailer.sendMail(mailOptions, function(error, info) {
    if (error) {
      console.log(error);
    }
  });
});

// Process for each task
function runTask(config, nextTask) {
  var input = [],
      q = queue();

  // Load each source
  if (typeof config.source === 'string') config.source = [config.source];
  config.sources.forEach(function(source, index) {
    q.defer(loadSource, source);
  });
  q.awaitAll(combineSources);

  // Process for loading source files
  function loadSource(source, cb) {
    var output = '',
        downloadRetries = 0,
        page = 1,
        results = [];

    // Download records from TrackVia
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

    // Download files from FTP server
    function downloadFile() {
      downloadRetries++;
      output = '';

      var spawn = require('child_process').spawn,
          child = spawn('curl', [
            '-s', '--ssl-reqd', '-u', ftpAuth , source.url
          ], { maxBuffer: 200 * 1024 * 1024 });
      child.stdout.setEncoding('utf8');
      child.stderr.setEncoding('utf8');
      child.stdout.on('data', function (data) { output += data; });
      child.stderr.on('data', function (data) { cb(data, null); });
      child.on('exit', function (code, signal) {
        if (!output.length && downloadRetries < 5) {
          setTimeout(downloadFile, timeout);
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

  // Handle errors in source files
  function combineSources(err, data) {
    if (!err && !data) err = 'Sources returned no data.';
    if (err) throw err;
    runProcess();
  }

  // Run R script on source files
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

  // Handle output from R script
  function sendOutput(data) {
    var exec = require('child_process').exec;

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
              '-u', ftpAuth,
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
          child.stdout.on('data', function (data) {
            console.log(data.replace(/\[37;41;1m/, '').replace(/\[0m/, ''));
          });
          child.stderr.on('data', function (data) {
            err += data;
            console.warn(data);
          });
          child.on('exit', function (code, signal) {
            var errImg = 'tmp/error' + config.output.table + '.jpg';

            if (fs.existsSync(errImg)) {
              images.push({
                filename: config.output.table + '.jpg',
                path: errImg,
                cid: config.output.table
              });
              console.log('<img src="cid:' + config.output.table + '"/>');
            }

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

process.on('exit', function() {
  // Remove temp and output files
  require('child_process').exec('srm -sr ./tmp/*');
  require('child_process').exec('srm -sr ./output/*');
  console.log('Cleaning up temp files');
});
