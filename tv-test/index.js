/* Dependencies */
var config = require('./../config');
var tv = require('trackvia')(config);

tv.tables('2000225584', function(err, res) {
  if (err) console.warn(err);
  console.log(res);
});
