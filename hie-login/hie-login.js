var request= require('request').defaults({jar: true});
var keychain = require('keychain');
var fs = require('fs');
var config = require('./congfig.json');

// Get password from OSX Keychain
keychain.getPassword({ 
  account: config.user,
  service: config.domain,
  type: 'internet'
}, function(err, pass) {
  config.pass = pass;
  main();
});

function main() {
  var url = config.url;

  request(url, function (err, req) {
    var data = {
      __RequestVerificationToken: req.body.match(/<input name="__RequestVerificationToken" type="hidden" value="(.*)"/)[1],
      username: config.user,
      password: config.pass
    };
  
    request({
      method: 'POST',
      url: url,
      form: data,
    }, function(err, res) {
      fs.writeFile('./test.html', res.body, function(err, res) {
        // Gets to webpage with a form that's programmatically submitted.
        // Need to parse form and POST it's data
        console.log(err, res);
      });
    });
  
  });

}