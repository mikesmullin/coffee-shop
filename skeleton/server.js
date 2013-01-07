var app, async, cb, express, flow, fs, path, server, sugar,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

path = require('path');

fs = require('fs');

sugar = require('sugar');

express = require('express');

async = require('async2');

app = express();

server = undefined;

cb = function() {};

module.exports = function(f) {
  return cb = f;
};

flow = new async;

flow.serial(function(next) {
  var require_fresh;
  app.PORT = process.env.PORT || 3001;
  app.ENV = process.env.ENV || 'development';
  app.STATIC = path.join(__dirname, 'static', path.sep);
  app.PUBLIC = path.join(app.STATIC, 'public', path.sep);
  app.ASSETS = path.join(app.PUBLIC, 'assets', path.sep);
  app.APP = path.join(app.STATIC, 'app', path.sep);
  app.SERVER_CONTROLLERS = path.join(app.APP, 'controllers', path.sep);
  app.SERVER_MODELS = path.join(app.APP, 'models', path.sep);
  app.SERVER_HELPERS = path.join(app.APP, 'helpers', path.sep);
  app.SHARED_HELPERS = path.join(app.ASSETS, 'helpers', path.sep);
  app.set('title', 'Cooper Fit Life');
  require_fresh = function(a) {
    delete require.cache[require.resolve(a)];
    return require(a);
  };
  app.locals(require_fresh(app.SHARED_HELPERS + 'templates'));
  app.response._render = app.response.render;
  app.response.render = function(name, options, cb) {
    options = options || {};
    options.view = name;
    options.layout = options.layout ? path.join('shared', 'layouts', options.layout) : path.join('shared', 'layouts', 'application');
    if (name.indexOf('server' + path.sep) === 0) {
      name = path.join('app', 'views', 'templates');
    } else {
      name = path.join('public', 'assets', 'templates');
    }
    return this._render(name, options, cb);
  };
  app.set('view engine', 'js');
  app.set('views', app.STATIC);
  app.engine('js', function(file, options, cb) {
    var render;
    fs.readFile(file, 'utf8', function(err, templates) {
      if (file.indexOf(path.join('static', 'app', 'views', 'templates.js')) !== -1) {
        return fs.readFile(app.ASSETS + 'templates.js', 'utf8', function(err, shared_templates) {
          templates = templates.split("\n");
          templates.splice(-2, 0, shared_templates.split("\n").slice(2, -2).join("\n"));
          return render(templates.join("\n"));
        });
      } else {
        return render(templates);
      }
    });
    return render = function(js) {
      eval(js);
      return cb(null, templates(options.view, options));
    };
  });
  app.use(express["static"](app.PUBLIC));
  return next();
});

flow.serial(function(next) {
  var db_file, sql;
  sql = require('node-sqlite-purejs');
  return sql.open(db_file = "" + app.STATIC + "db/" + app.ENV + ".sqlite", {}, function(err, db) {
    if (err) {
      throw err;
    }
    app.db = db;
    console.log("opened db " + db_file);
    app.require_model = function(file) {
      var Model;
      Model = require(app.SERVER_MODELS + file);
      Model.prototype.execute_sql = function(q, cb) {
        console.log("executing sql: " + q);
        return app.db.exec(q, cb);
      };
      return Model;
    };
    app.model = function(file) {
      return new (app.require_model(file));
    };
    return next();
  });
});

flow.serial(function(next) {
  var SQLiteStore;
  app.use(express.cookieParser());
  app.use(express.bodyParser());
  app.use(function(req, res, done) {
    console.log("" + req.method + " \"" + req.url + "\" for " + req.ip + " at " + (Date.create().iso()));
    if (JSON.stringify(req.body) !== '{}') {
      console.log("POSTDATA ", req.body);
    }
    return done();
  });
  app.use(express.methodOverride());
  app.use(express.session({
    key: require(path.join(__dirname, 'package.json')).name + '.sid',
    secret: "<REPLACE WITH YOUR KEYBOARD CAT HERE>",
    cookie: {
      path: '/',
      maxAge: 1000 * 60 * 30
    },
    store: new (SQLiteStore = (function(_super) {

      __extends(SQLiteStore, _super);

      function SQLiteStore() {
        return SQLiteStore.__super__.constructor.apply(this, arguments);
      }

      SQLiteStore.prototype.get = function(session_id, cb) {
        return app.model('session').select('data').where({
          session_id: session_id
        }).first(function(err, session) {
          if (err) {
            return cb(err);
          }
          return cb(null, session ? JSON.parse(session.data) : void 0);
        });
      };

      SQLiteStore.prototype.set = function(session_id, data, cb) {
        var session;
        session = app.model('session');
        return session.select('id').where({
          session_id: session_id
        }).first(function(err, result) {
          if (err) {
            return cb(err);
          }
          if (result) {
            session.id = result.id;
          }
          session.session_id = session_id;
          session.data = JSON.stringify(data);
          return session.save(function(err) {
            if (err) {
              return cb(err);
            }
            return cb(null);
          });
        });
      };

      return SQLiteStore;

    })(express.session.Store))
  }));
  app.use(require('connect-flash')());
  app.use(function(req, res, next) {
    res.locals._csrf = req.session._csrf;
    res.locals.flash = {
      alert: req.flash('error'),
      notice: req.flash('notice')
    };
    res.locals.current_user = req.user;
    return next();
  });
  app.require_auth = function(req, res, next) {
    if (req.isAuthenticated()) {
      return next();
    }
    return res.redirect("/");
  };
  return next();
});

flow.go(function() {
  require(app.SERVER_CONTROLLERS + 'application')(app);
  if (!process.env.BOOTSTRAP) {
    server = app.listen(app.PORT);
    console.log("listening on http://localhost:" + app.PORT + "/");
    process.on('SIGINT', function() {
      console.log("caught SIGINT. will attempt safe shutdown...");
      return server.close();
    });
  }
  return process.nextTick(function() {
    return cb(app);
  });
});
