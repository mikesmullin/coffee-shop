var app, express, sugar;

process.env.ROOT = __dirname + '/static/';

process.env.development = true;

process.env.PORT = 3001;

sugar = require('sugar');

express = require('express');

app = express();

app.engine('html', function(path, options, cb) {
  return fs.readFile(path, 'utf8', function(err, str) {
    return cb(err, str);
  });
});

app.use(function(req, res, done) {
  console.log("" + req.method + " \"" + req.url + "\" for " + req.ip + " at " + (Date.create().iso()));
  return done();
});

app.use(express["static"](process.env.ROOT + 'public/'));

require(process.env.ROOT + 'app/controllers/application')(app);

app.listen(process.env.PORT);

console.log("listening on http://localhost:" + process.env.PORT + "/");
