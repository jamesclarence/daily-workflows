var casper = require('casper').create({
    verbose: true,
    logLevel: "debug"
});


casper.start('https://www.google.com', function() {
    this.echo(this.fetchText('h2'));
});


casper.thenOpen('https://secure.trackvia.com/app/login', function() {
    this.echo(this.fetchText('h1'));
});


casper.run();