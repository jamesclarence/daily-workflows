var queue = require('queue-async'),
    tvConfig = require('./../config.json'),
    tv = require('trackvia')(tvConfig),
    configs = require('./config.json'),
    CSV = require('comma-separated-values'),
    fs = require('fs'),
    _ = require('underscore');

// Load files
configs.forEach(function(config) {
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
    if (typeof config.output === 'string') {
      fs.writeFile(config.output, data, function(err) {
        if (err) throw err;
        console.log('Saved file: ' + config.output);
      })
      return;
    }

    data = new CSV(data, { header: true, cast: false }).parse();

    switch (config.output.operation) {
      case 'add':
        tv.tables(config.output.table, function(err, res) {
          if (err) console.warn(err);
          var fields = res.coldefs.map(function(col) { return col.label; });

          data = _(data.map(function(item) {
            var out = {};
            fields.forEach(function(field) {
              if (item[field]) out[field] = item[field];
            });
            return out;
          })).filter(function(o) {return _(o).size(); });

          tv.records({
            method: 'POST',
            table_id: config.output.table,
            data: data,
          }, function(err, res) {
            if (err) console.warn(err);
            console.log(res);
          });
        });
        break;
      case 'update':
        break;
      case 'add-update':
        break;

    }
  }

});

process.on('exit', function() {
  // Remove temp files
  require('child_process').exec('srm -sr ./tmp/*');
  console.log('Cleaning up temp files');
});
