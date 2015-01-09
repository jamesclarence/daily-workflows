var process = require('system'),
    casper = require('casper').create({
      timeout: 1000 * 60 * 60,
      waitTimeout: 1000 * 60 * 60,
      viewportSize: { width: 800, height: 600 },
      onTimeout: run,
      onError: function() { this.capture('tmp/error' + tableID + '.jpg'); }
    }),
    config = {
      user: process.env.TV_USER,
      password: process.env.TV_PASSWORD
    },
    retries = 0,
    retriesMax = 5,
    args = casper.cli.args,
    tableID = args[0],
    file = args[1],
    fields = args[2].split(','),
    uploadURL = 'https://secure.trackvia.com/app/import?' +
      'action=upload&datasetid=' + tableID + '&projectid=5000000580&dowhat=both';

// Load the page
casper.start('https://secure.trackvia.com/app/login', function() {

  casper.capture('tmp/0.jpg');

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

// Navigation tasks
function run() {
  retries++;

  // Limit retries
  if (retries >= retriesMax) {
    setTimeout(function() {
      casper.die('Timed out uploading to TrackVia. \
        Tried ' + retriesMax + ' times. Is TrackVia available?', 1);
    }, 0);
    return;
  }

  // Upload spreadsheet
  casper.thenOpen(uploadURL, function() {
    this.fill('form#main', { 'spreadsheetfile': file }, true);
    casper.capture('tmp/1.jpg');

  })

  // Match upload fields
  casper.waitForSelector('form#main table tbody tr td:first-child', function() {
    casper.capture('tmp/2.jpg');

    var sel = 'form#main table tbody tr td:first-child',
        ids = this.getElementsInfo(sel).map(function(el) {
          return el.text.replace('\n', '');
        }),
        matches = fields.map(function(field) {
          return 'col-' + ids.indexOf(field);
        });
    this.fill('form#main', { matches: matches }, true);
    casper.capture('tmp/3.jpg');

  });

  // Upload or capture errors
  casper.then(function() {
    casper.capture('tmp/4.jpg');

    if (this.fetchText('h1') === 'Internal Server Error') {
      this.capture('tmp/error' + tableID + '.jpg');
      setTimeout(function() {
        casper.die('Internal server error.', 1);
      }, 0);
    }
    if (this.getElementInfo('.container_err_msg').text.length > 0) {
      this.capture('tmp/error' + tableID + '.jpg');
      setTimeout(function() {
        casper.die('Error uploading file.', 1);
      }, 0);
    }
    casper.capture('tmp/5.jpg');

    setTimeout(function() {
      console.log(window.location.href);
      casper.capture('tmp/5a.jpg');
      if (window.location.href === 'https://secure.trackvia.com/app/import') {
        casper.die('Failed to load file.', 1);
        casper.capture('tmp/error5.jpg');
      }
    }, 30 * 1000);


  });

  // Wait until upload finishes
  casper.waitForUrl(/&action=complete$/, function() {
    casper.capture('tmp/6.jpg');

    var text = this.fetchText('#container-main')
      .trim()
      .replace('Click to return to Table Overview page.', '');

    this.echo(text);
    casper.capture('tmp/7.jpg');
  }, function() {
    this.echo('Timed out waiting for upload');
  });
}
