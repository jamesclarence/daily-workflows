var process = require('system'),
    casper = require('casper').create({
      timeout: 1000 * 60 * 30,
      waitTimeout: 1000 * 60 * 30,
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
    timeout = 1000 * 30,
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
  });

  // Match upload fields
  casper.waitForSelector('form#main table tbody tr td:first-child', function loadTableFinished() {
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

  }, function loadTableTimedout() {
    setTimeout(run, timeout);
  }, 1000 * 60 * 30);

  casper.waitForText('Importing file...', function importingFinished() {
    casper.capture('tmp/4.jpg');
  }, function importingTimedout() {
    casper.capture('tmp/error' + tableID + '.jpg');
    setTimeout(function() {
      casper.die('Upload timed out. Check to see if the update finished.', 1);
    }, 0);
  }, 1000 * 60 * 10);

  // Wait until upload finishes
  casper.waitForUrl(/&action=complete$/, function importingFinished() {
    casper.capture('tmp/5.jpg');

    var text = this.fetchText('#container-main')
      .trim()
      .replace('Click to return to Table Overview page.', '');

    this.echo(text);
  }, function importingTimedout() {
    setTimeout(run, timeout);
  }, 1000 * 60 * 30);
}
