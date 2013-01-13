// Generated by CoffeeScript 1.4.0
var CoffeeShopServer,
  __slice = [].slice;

module.exports = CoffeeShopServer = function() {
  var app, async, connect, flow, k, method, methods, path, routes, _fn, _ref,
    _this = this;
  global.exports = function(file, o) {
    return o;
  };
  process.on('uncaughtException', function(err) {
    if (err.code === 'EADDRINUSE') {
      process.stderr.write("FATAL: port is already open. kill all node processes and try again.");
      return process.exit(1);
    }
  });
  connect = require('connect');
  app = connect();
  path = require('path');
  async = require('async2');
  routes = {};
  app.ENV = process.env.NODE_ENV = process.env.NODE_ENV || 'development';
  app.PORT = process.env.PORT || 3001;
  app.STATIC = path.join(process.cwd(), 'static', path.sep);
  app.PUBLIC = path.join(app.STATIC, 'public', path.sep);
  app.ASSETS = path.join(app.PUBLIC, 'assets', path.sep);
  app.APP = path.join(app.STATIC, 'app', path.sep);
  app.CONFIG = path.join(app.STATIC, 'config', path.sep);
  app.SERVER_CONTROLLERS = path.join(app.APP, 'controllers', path.sep);
  app.SHARED_CONTROLLERS = path.join(app.ASSETS, 'controllers', path.sep);
  app.SERVER_MODELS = path.join(app.APP, 'models', path.sep);
  app.SERVER_HELPERS = path.join(app.APP, 'helpers', path.sep);
  app.SHARED_HELPERS = path.join(app.ASSETS, 'helpers', path.sep);
  app.SERVER_VIEWS = path.join(app.APP, 'views', path.sep);
  app.SERVER_LAYOUTS = path.join(app.VIEWS, 'layouts', path.sep);
  _ref = methods = ['GET', 'POST', 'PUT', 'DELETE'];
  _fn = function(method) {
    return app[method.toLowerCase()] = function() {
      var cb, middlewares, options, uri, _i;
      uri = arguments[0], middlewares = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), cb = arguments[_i++];
      options = {};
      for (k in middlewares) {
        if (!(typeof middlewares[k] === 'object')) {
          continue;
        }
        options = middlewares[k];
        continue;
      }
      if (uri === '/') {
        routes['root'] = '/';
      } else if (options.as) {
        routes[options.as] = uri;
      } else {
        options.as = uri.replace(/[^a-zA-Z+_-]+/g, '_').replace(/(^_|_$)/g, '');
        routes[options.as] = routes[options.as] || uri;
      }
      return app.use(function(req, res, next) {
        var flow, params;
        if (!(req.method === method && (params = req.url.match(new RegExp("^" + uri + "$"))) !== null)) {
          return next();
        }
        req.params = params.slice(1);
        app.response.send = res.send = res.end;
        flow = async.flow(req, res);
        for (k in middlewares) {
          if (typeof middlewares[k] === 'function') {
            (function(middleware) {
              return flow.serial(function(req, res, next) {
                return middlewares[k](req, res, function(err, warning) {
                  if (err === false) {
                    return res.end(warning);
                  } else {
                    return next(err, req, res);
                  }
                });
              });
            })(middlewares[k]);
          }
        }
        return flow.go(function(err, req, res) {
          if (err) {
            return next(err);
          }
          return cb(req, res);
        });
      });
    };
  };
  for (k in _ref) {
    method = _ref[k];
    _fn(method);
  }
  app.request = {};
  app.response = {
    locals: {}
  };
  app.use(function(req, res, next) {
    res.locals = {};
    res.navigate = function(uri) {
      return res.redirect(uri);
    };
    res.url = {
      join: function() {
        var parts;
        parts = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return parts.join('/');
      }
    };
    res.render = function(file, options) {
      return res.send("would render view template \"" + file + "\" with options: " + (JSON.stringify(options, null, 2)));
    };
    res.activate = function(file, options) {
      return res.send("would activate widget \"" + file + "\" with options: " + (JSON.stringify(options, null, 2)));
    };
    for (k in app.request) {
      req[k] = app.request[k];
    }
    for (k in app.response) {
      res[k] = app.response[k];
    }
    return next();
  });
  app.locals = function(o) {
    var _results;
    _results = [];
    for (k in o) {
      _results.push(app.response.locals[k] = app.response.locals[k] || o[k]);
    }
    return _results;
  };
  if (process.env.NODE_ENV === 'development') {
    app.get('/shop/routes', function(req, res) {
      return res.send(JSON.stringify(routes, null, 2));
    });
  }
  flow = new async;
  app.bootstrap = function() {
    return flow.go(function() {
      var server;
      if (typeof app.BOOTSTRAP === 'function') {
        return process.nextTick(function() {
          return app.BOOTSTRAP(app);
        });
      } else {
        server = app.listen(app.PORT, function() {
          return console.log("worker " + process.pid + " listening on http://localhost:" + app.PORT + "/");
        });
        return process.on('uncaughtException', function(err) {
          process.stderr.write("\nWARNING: handle your exceptions better: \n\n" + err.stack + "\n\n");
          if (server) {
            server.close();
          }
          return process.exit(1);
        });
      }
    });
  };
  return {
    app: app,
    connect: connect,
    flow: flow
  };
};
