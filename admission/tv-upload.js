var casper = require('casper').create({
      timeout: 1000 * 60 * 60,
      waitTimeout: 1000 * 60 * 60,
      viewportSize: { width: 800, height: 600 },
      onTimeout: run,
      onError: function() { this.capture('images/error.jpg'); }
    }),
    config = require('/tvconfig.json'),
    args = casper.cli.args,
    retries = 0,
    retriesMax = 5;

// Temp variables
var tableID = args[0],
    file = args[1],
    fields = args[2].split(','),
    uploadURL = 'https://secure.trackvia.com/app/import?action=upload&datasetid=' + tableID + '&projectid=5000000580&dowhat=both';

// Load the page
casper.start('https://secure.trackvia.com/app/login', function() {

  // Log in
  casper.then(function() {
    this.fill('form#webform-client-form-298', {
      'username': config.user,
      'password': config.password
    }, true);
  });

  run();
});

// Start script
casper.run();

function run() {
  retries++;
  if (retries >= retriesMax) {
    setTimeout(function() {
      casper.die('Timed out uploading to TrackVia. Tried ' + retriesMax + ' times. Is TrackVia available?', 1);
    }, 0);
    return;
  }

  // Upload spreadsheet
  casper.thenOpen(uploadURL, function() {
    this.fill('form#main', { 'spreadsheetfile': file }, true);
  })

  // Match upload fields
  casper.then(function() {
    var sel = 'form#main table tbody tr td:first-child',
        ids = this.getElementsInfo(sel).map(function(el) {
          return el.text.replace('\n', '');
        }),
        matches = fields.map(function(field) {
          return 'col-' + ids.indexOf(field);
        });
    this.fill('form#main', { matches: matches }, true);
  });

  // Upload or capture errors
  casper.then(function() {
    // this.capture('images/next-' + (new Date().toString()) + '.jpg');

    if (this.fetchText('h1') === 'Internal Server Error') {
      this.capture('images/error.jpg');
      setTimeout(function() {
        casper.die('Internal server error.', 1);
      }, 0);
    }
    var sel = 'form#main input[type="submit"]';
    if (this.exists(sel)) {
      this.capture('images/error.jpg');
      setTimeout(function() {
        casper.die('Error uploading file.', 1);
      }, 0);
    }
  });

  // Wait until upload finishes
  casper.waitForUrl(/&action=complete$/, function() {
    var text = this.fetchText('#container-main')
      .trim()
      .replace('Click to return to Table Overview page.', '');

    // this.capture('images/finished-' + (new Date().toString()) + '.jpg');

    this.echo(text);
  }, function() {
    this.echo('Timed out waiting for upload');
  });
}
