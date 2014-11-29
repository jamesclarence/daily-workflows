/* Dependencies */
var config = require('./../config');
var tv = require('trackvia')(config);

/*
- specify table_id and field to match
- download all records in table
- save ids from intersection of records
- save list of diference of records
- update matched ids
- add new records
*/

sync('5000004043', 'Email');

function sync(table_id, field_name, data) {
  tv.tables(table_id, function(err, res) {
    if (err) console.warn(err);
    var view_id = res.views[0].id;
    tv.views(view_id, function(err, res) {
      if (err) console.warn(err);
      var records = res.records;
      var remoteRecords = {};
      records.forEach(function(item) {
        var id = item.id;
        var match = item.fields[field_name];
        remoteRecords[match] = id;
      });
      console.log(remoteRecords);
    });
  })
}