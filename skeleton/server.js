var app, express, fs, sugar;

process.env.ROOT = __dirname + '/static/';

process.env.development = true;

process.env.PORT = 3001;

sugar = require('sugar');

fs = require('fs');

express = require('express');

app = express();

app.response._render = app.response.render;

app.response.render = function(name, options, cb) {
  options.view = name;
  if (name.indexOf('server/') === 0) {
    name = 'app/views/templates';
  } else {
    name = 'public/assets/templates';
  }
  return this._render(name, options, cb);
};

app.set('view engine', 'js');

app.set('views', process.env.ROOT);

app.engine('js', function(path, options, cb) {
  var render;
  render = function(str) {
    eval('templates=' + str);
    return cb(null, templates(options.view, options));
  };
  return fs.readFile(path, 'utf8', function(err, templates) {
    if (path.indexOf('static/app/views/templates.js') !== -1) {
      return fs.readFile(process.env.ROOT + 'public/assets/templates.js', 'utf8', function(err, shared_templates) {
        templates = templates.split("\n");
        templates.splice(-2, 0, shared_templates.split("\n").slice(2, -2).join("\n"));
        return render(templates.join("\n"));
      });
    } else {
      return render(templates);
    }
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
