var app, connect, fetch, flow, require_fresh, _ref;

_ref = require('coffee-shop').Server(), app = _ref.app, connect = _ref.connect, fetch = _ref.fetch, flow = _ref.flow;

app.use(connect.logger('dev'));

app.use(connect["static"](app.PUBLIC));

app.use(connect.methodOverride());

app.use(connect.cookieParser());

app.use(connect.bodyParser());

flow.serial(function(next) {
  var db_config, db_name, mysql;
  mysql = require('mysql');
  db_config = require(app.CONFIG + 'database.json')[process.env.NODE_ENV];
  db_name = db_config.database;
  delete db_config.database;
  app.db = mysql.createConnection(db_config);
  app.db.on('error', function(err) {
    if (err.code === 'ER_BAD_DB_ERROR') {
      return process.stderr.write("WARNING: could not locate database \"" + db_config.database + "\"\n");
    } else {
      throw err;
    }
  });
  return app.db.connect(function() {
    return app.db.query("USE `" + db_name + "`;", function() {
      app.require_model = function(file) {
        var Model;
        Model = require(app.SERVER_MODELS + file);
        Model.prototype.execute_sql = function(q, cb) {
          console.log("executing sql: " + q);
          return app.db.query(q, cb);
        };
        return Model;
      };
      app.model = function(file) {
        return new (app.require_model(file));
      };
      app.use(connect.session({
        key: require(path.join(__dirname, 'package.json')).name + '.sid',
        secret: "<REPLACE WITH YOUR KEYBOARD CAT HERE>",
        cookie: {
          path: '/',
          maxAge: 1000 * 60 * 30
        }
      }));
      return next();
    });
  });
});

flow.serial(function(next) {
  var LocalStrategy, passport;
  passport = require('passport');
  passport.serializeUser(function(user, done) {
    return done(null, user.id);
  });
  passport.deserializeUser(function(id, done) {
    return app.model('user').find(id, done);
  });
  LocalStrategy = require('passport-local').Strategy;
  passport.use(new LocalStrategy({
    usernameField: 'auth_key',
    passwordField: 'password'
  }, function(auth_key, password, done) {
    return app.model('user').select('id', 'email', 'password_digest').where({
      email: auth_key
    }).first(function(err, user) {
      return done(err(err ? session.save(function(err) {
        if (err) {
          return cb(err);
        }
        return cb(null);
      }) : void 0));
      if (!user) {
        return done(null, false, {
          message: 'Incorrect username.'
        });
      }
      if (!user.valid_password(password)) {
        return done(null, false, {
          message: 'Incorrect password.'
        });
      }
      return done(null, user);
    });
  }));
  app.passport = passport;
  app.use(passport.initialize());
  app.use(passport.session());
  app.require_auth = function(req, res, next) {
    if (req.isAuthenticated()) {
      return next();
    }
    return res.redirect("/");
  };
  app.use(require('connect-flash')());
  app.use(function(req, res, next) {
    res.locals.flash = {
      alert: req.flash('error'),
      notice: req.flash('notice')
    };
    res.locals.current_user = res.current_user = req.user;
    return next();
  });
  return next();
});

require_fresh = function(a) {
  delete require.cache[require.resolve(a)];
  return require(a);
};

app.locals(require_fresh(app.SHARED_HELPERS + 'templates'));

app.response.render = function(name, options) {
  if (options == null) {
    options = {};
  }
  options.view = 'views/' + name;
  options.layout = 'views/' + app.SERVER_LAYOUTS + (options.layout || 'application');
  return require('fs').readFile(app.SERVER_VIEWS + 'templates.js', 'utf8', function(err, js) {
    var k, out;
    if (err) {
      return process.stderr.write(err.stack);
    }
    eval(js);
    options.locals = options.locals || {};
    options.locals.layout = options.layout;
    for (k in app.response.locals) {
      options.locals[k] = app.response.locals[k];
    }
    out = templates(options.view, options.locals);
    return app.response.send(out);
  });
};

flow.serial(function() {
  return fetch(app.SERVER_CONTROLLERS + 'application', app, this);
});

flow.serial(function() {
  return fetch(app.SERVER_CONTROLLERS + 'users', app, this);
});

flow.serial(function() {
  return fetch(app.SHARED_CONTROLLERS + 'application', app, this);
});

flow.serial(function() {
  return fetch(app.SHARED_CONTROLLERS + 'users', app, this);
});

module.exports = function(cb) {
  return app.BOOTSTRAP = cb;
};

app.bootstrap();
