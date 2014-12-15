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
    if (typeof source !== 'string') {
      source.forEach(function(source) {
        q.defer(loadSource, source, index);
      });
    } else {
      q.defer(loadSource, source, 0);
    }
  });
  q.awaitAll(combineSources);

  function loadSource(source, index, cb) {
    var output = { key: index, items: [] };

    if (typeof source === 'object') {
      if (source.type.toLowerCase() === 'trackvia') {
        var page = 1,
            results = [];
        getRecords(function(data) {
          output.items = data;
          cb(null, output)
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
      }
    } else {
      var spawn = require('child_process').spawn,
          child = spawn('curl', [
            '-s', '--ssl-reqd', '-K', 'ftp.config' , source
          ], { maxBuffer: 200 * 1024 * 1024 });

      child.stdout.setEncoding('utf8');
      child.stderr.setEncoding('utf8');
      child.stdout.on('data', function (data) {
        if (output.items && output.items.push) output.items.push(data);
      });
      child.stderr.on('data', function (data) { cb(data, null); });
      child.on('exit', function (code, signal) {
        output.items = output.items.join('');
        cb(null, output);
      });
    }
  }

  function combineSources(err, data) {
    if (!err && (!data || !data.length)) err = 'Sources returned no data.';
    if (err) throw err;
    var output = data.reduce(function(memo, result) {
          var lines = result.items.split('\n'),
              headers = lines.shift();

          memo[result.key] = memo[result.key] || [headers];
          memo[result.key].push(lines);
          return memo;
        }, []);

    output.forEach(function(arg, i) {
      output[i] = arg.join('\n');
    });

    runProcess(output);
  }

  function runProcess(data) {
    var spawn = require('child_process').spawn,
        data = JSON.stringify(data),
        args = [config.script],
        child = spawn('Rscript', args),
        output = [];

    child.stdin.write(data + '\n');
    child.stdin.end();

    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');
    child.stdout.on('data', function(data) {
      output.push(data);
    });
    child.stderr.on('data', function(data) {
      console.log(data);
    });
    child.on('error', function(data) {
      throw data;
    });
    child.on('exit', function(data) {
      sendOutput(output.join(''));
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
