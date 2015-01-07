var casper = require('casper').create(),
    config = require('/tvconfig.json');

// Temp variables
var tableID = '5000004646',
    file = '../admission/output/D4-CMMI-Readmissions.xls',
    fields = ['UniqueID', 'AdmitDate', 'VisitType', 'Facility'],
    uploadURL = 'https://secure.trackvia.com/app/import?action=upload&datasetid=' + tableID + '&projectid=5000000580&dowhat=both';

// Load the page
casper.start('https://secure.trackvia.com/app/login');

// Set page size
casper.viewport(1024, 768);

// Log in
casper.then(function() {
  this.fill('form#webform-client-form-298', {
    'username': config.user,
    'password': config.password
  }, true);
});

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
  var sel = 'form#main [value="Import anyway →"]';
  if (this.exists(sel)) {
    this.click(sel);
    this.capture('warning.jpg');
  } else {
    this.capture('error.jpg');
    this.exit();
  }
});

// Wait until upload finishes
casper.waitForUrl(/&action=complete$/, function() {
  var text = this.fetchText('#container-main')
    .trim()
    .replace('Click to return to Table Overview page.', '');
  this.capture('finished.jpg');
  this.echo(text);
}, function() {
  this.echo('Timed out waiting for upload');
}, 1000 * 60 * 60);

casper.run();

/*
 - dont import anway
 - instead send error and start over
 - use arguments for shelling out from main script
 - set up loop
*/
