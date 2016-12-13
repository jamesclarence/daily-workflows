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
      'action=upload&datasetid=' + tableID + '&projectid=5000000580&dowhat=both',
    waitURL = 'https://secure.trackvia.com/app/status/wait?url=https%3A%2F%2Fsecure.trackvia.com%2Fapp%2Fimport%3Fdatasetid%3D' + tableID + '%26action%3Dcomplete&title=Importing+file...';

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

// Navigation tasks
function run() {
  retries++;

  // Limit retries
  if (retries >= retriesMax) {
    setTimeout(function() {
      casper.die('Error: Timed out uploading to TrackVia. ' +
        'Tried ' + retriesMax + ' times. Is TrackVia available?', 1);
    }, 0);
    return;
  }

  // Upload spreadsheet
  casper.thenOpen(uploadURL, function() {
    this.fill('form#main', { 'spreadsheetfile': file }, true);
  });

  // Match upload fields
  casper.then(function() {
    casper.waitForSelector('form#main table tbody tr td:first-child', function loadTableFinished() {

      var sel = 'form#main table tbody tr td:first-child',
          ids = this.getElementsInfo(sel).map(function(el) {
            return el.text.replace('\n', '');
          }),
          matches = fields.map(function(field) {
            return 'col-' + ids.indexOf(field);
          });

      casper.fill('form#main', { matches: matches }, true);

      // Test for upload error
      casper.then(function() {
        var error = casper.fetchText('.container_err_msg').trim();
        if (error) setTimeout(function() { casper.die('Error: ' + error); }, 0);
      });

      // If TrackVia doesn't redirect to waiting page after 10 seconds,
      // do it manually.
      setTimeout(function() {
        if (casper.getCurrentUrl().indexOf('title=Importing+file') === -1) {
          casper.open(waitURL);
        }
      }, 1000 * 10);

      // Wait for completed page
      casper.waitForUrl(/&action=complete$/, function importingFinished() {

        var text = casper.fetchText('#container-main')
          .trim()
          .replace('Click to return to Table Overview page.', '');

        casper.echo(text);

        setTimeout(function() {
          casper.exit(0);
        }, 0);

      });

    });

  });

}
