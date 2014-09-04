/* Dependencies */
var config = require('./../config');
var tv = require('trackvia')(config);

tv.tables('5000002278', function(err, res) {
  if (err) console.warn(err);
  console.log(res);
});
