/* Dependencies */
var config = require('./../config');
var tv = require('trackvia')(config);
var CSV = require('comma-separated-values');
var queue = require('queue-async');
var fs = require('fs');

// Load all apps
// Loop through apps
// Loop through tables
// Store coldefs
// Collect all keys
// Filter on unique: http://stackoverflow.com/questions/1960473/unique-values-in-an-array
// Save with CSV stringify

function getData() {
  var a_q = queue(1);
  var fields = [];

  tv.apps(function(err, apps) {
    if (err) console.warn(err);

    apps.forEach(function(app, index) {

      var app_name = app.name;
      a_q.defer(function(a_cb) {
        var app_index = index + 1;
        var app_length = apps.length;
        var t_q = queue(1);

        tv.apps(app.id, function(err, app) {
          if (err) console.warn(err);

          var tables = app.tables;
          tables.forEach(function(table, index) {

            t_q.defer(function(t_cb) {
              var table_index = index + 1;
              var table_length = tables.length;

              tv.tables(table.id, function(err, table) {
                if (err) console.warn(err);
                console.log(
                  'App ' + (app_index) + ' out of ' + app_length + 
                  ', Table ' + (table_index) + ' out of ' + table_length
                );

                table.coldefs.forEach(function(field) {

                  field.app_name   = app_name;
                  field.app_id     = table.app_id;
                  field.table_name = table.name;
                  field.table_id   = table.id;

                  fields.push(field);
                  t_cb();
                });
              });
            });
          });
          t_q.awaitAll(function(err, data) {
            a_cb(err, data);
          });
        });
      });
    });
    a_q.awaitAll(function(err, data) {
      if (err) console.warn(err);
      fs.writeFile('./data/all-fields.json', JSON.stringify(fields, null, 4),
      function(err) {
        if (err) console.warn(err);
        else console.log('JSON file saved.');
      });
      saveCSV(fields);
    });
  });

}

function saveCSV(data) {
  var keys = [];
  data.forEach(function(obj) {
    keys = keys.concat(Object.keys(obj));
  });
  keys = keys.filter(function(value, index, self) {
    return self.indexOf(value) === index;
  });

  var d = new CSV(data, { header: keys }).encode();
  fs.writeFile('./data/all-fields.csv', d, function(err) {
    if (err) console.warn(err);
    else console.log('CSV file saved.');
  });

}
getData();
