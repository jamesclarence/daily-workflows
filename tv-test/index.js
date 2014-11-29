/* Dependencies */
var config = require('./../config');
var tv = require('../../node-trackvia/trackvia')(config);

tv.records({ method: 'DELETE', table_id: 5000004043, data:[5029082112, 5029082114]}, function(err, res) {
  if (err) console.warn(err);
  console.log(res);
});
