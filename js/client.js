// Generated by CoffeeScript 1.4.0
var CoffeeShopClient, app, global, module, require, __exported__,
  __slice = [].slice;

app = new (CoffeeShopClient = (function() {
  var end;

  function CoffeeShopClient() {}

  CoffeeShopClient.prototype.bootstrap = function(env, options) {
    var prev_uri,
      _this = this;
    this.ENV = env || 'production';
    this.options = options || {};
    this.options.debug = options.debug || this.ENV !== 'production';
    this.options.trace = options.trace || false;
    this.options.started = new Date();
    this.options.renderTo = options.renderTo || 'body';
    prev_uri = '';
    $(window).hashchange(function() {
      var uri;
      uri = document.location.hash.substr(2);
      if (uri !== prev_uri) {
        $(_this.options.renderTo).empty();
        return _this.emit('hashchange', uri);
      }
    });
    this.on('ready', function() {
      _this.log('app ready.');
      return _this.emit('hashchange', document.location.hash.substr(2) || '/');
    });
    return this.emit('ready');
  };

  CoffeeShopClient.prototype.log = function(o) {
    var current;
    if (this.options.debug && console) {
      current = new Date();
      console.log(typeof o === 'string' ? "[" + ((current - this.options.started) / 1000) + "s] " + o : o);
      if (this.options.trace) {
        return console.trace();
      }
    }
  };

  CoffeeShopClient.prototype.events = {};

  CoffeeShopClient.prototype.on = function(event, cb) {
    this.events[event] = this.events[event] || [];
    return this.events[event].push(cb);
  };

  CoffeeShopClient.prototype.emit = function() {
    var args, event, k, _results;
    event = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    _results = [];
    for (k in this.events[event]) {
      _results.push(this.events[event][k].apply(null, args));
    }
    return _results;
  };

  CoffeeShopClient.prototype.removeAllListeners = function(event) {
    return delete this.events[event];
  };

  CoffeeShopClient.prototype.request = {
    url: ''
  };

  CoffeeShopClient.prototype.response = {
    locals: {},
    navigate: function(uri) {
      return document.location.href = '#!' + uri;
    },
    activate: function(widget) {},
    send: end = function(s) {
      return $('body').append(s);
    },
    end: end,
    render: function(file, options) {
      return this.send("would render view template \"" + file + "\" with options: " + (JSON.stringify(options, null, 2)));
    },
    activate: function(file, options) {
      var e, k, scope, widget;
      app.log("activating widget \"" + file + "\" with options: " + (JSON.stringify(options, null, 2)));
      widget = require("widgets/" + file)(app);
      e = $(widget.e).appendTo(options.within);
      scope = {};
      for (k in widget.elements) {
        scope[k] = $(widget.elements[k], e);
      }
      for (k in widget.events) {
        $(e).bind(k, widget.events[k]);
      }
      return e;
    }
  };

  CoffeeShopClient.prototype.get = function() {
    var cb, middlewares, uri, _i,
      _this = this;
    uri = arguments[0], middlewares = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), cb = arguments[_i++];
    return this.on('hashchange', function(url) {
      var flow, k, next, params, req, res;
      _this.log("route! uri is " + uri + " and url is " + url);
      _this.request.url = url;
      req = _this.request;
      res = _this.response;
      next = function() {
        var args, err;
        err = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        _this.log("Could not GET " + url);
        if (err) {
          _this.log(err);
        }
      };
      if ((params = req.url.match(new RegExp("^" + uri + "$"))) === null) {
        return next();
      }
      req.params = params.slice(1);
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

  CoffeeShopClient.prototype.render = function(template_fn, locals) {
    var engine;
    if (locals == null) {
      locals = {};
    }
    engine = new CoffeeTemplates({
      format: false,
      globals: require('helpers/templates')()
    });
    return engine.render(template_fn, locals);
  };

  return CoffeeShopClient;

})());

__exported__ = {};

module = {};

require = function(file) {
  return __exported__[file];
};

global = {
  exports: function(file, o) {
    return __exported__[file] = o;
  }
};
