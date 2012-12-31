// Generated by CoffeeScript 1.4.0
var CoffeeShop, all, concat, sig, sugar, word, y,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

sugar = require('sugar');

module.exports = CoffeeShop = (function() {

  function CoffeeShop() {}

  CoffeeShop.Table = (function() {

    function _Class() {
      this._table = '';
      this._select = [];
      this._primary_key = 'id';
      this._select = [];
      this._join = [];
      this._where = [];
      this._group = [];
      this._having = [];
      this._order = [];
      this._limit = 0;
      this._offset = 0;
      return;
    }

    _Class.prototype.table = function(_table) {
      this._table = _table;
    };

    _Class.prototype.primary_key = function(_primary_key) {
      this._primary_key = _primary_key;
    };

    _Class.prototype._simple = function(n) {
      return function() {
        var a, k;
        a = arguments;
        if (a.length >= 1 && all(a, 's')) {
          for (k in a) {
            if (word(a[k])) {
              a[k] = this.escape_key(a[k]);
            }
          }
          concat(this["_" + n], a);
        }
        return this;
      };
    };

    _Class.prototype.select = _Class.prototype._simple('select');

    _Class.prototype.project = _Class.prototype.select;

    _Class.prototype.join = function() {
      var a, k;
      a = arguments;
      if (word(a[0]) || a.length > 1) {
        for (k in a) {
          this._join.push("JOIN " + (this.escape_key(a[k])) + "\n ON 1");
        }
      } else if (y(a[0] === 's')) {
        this._join.push(a[0]);
      }
      return this;
    };

    _Class.prototype.joins = _Class.prototype.join;

    _Class.prototype.include = _Class.prototype.join;

    _Class.prototype.where = function() {
      var a, i, r, s,
        _this = this;
      a = arguments;
      s = sig(a);
      if (a.length >= 2 && all(a, 's') && a[0].indexOf('?') !== -1) {
        i = 0;
        this._where.push(a[0].replace(/\?/g, function() {
          return _this.escape(a[++i]);
        }));
      } else if (a.length >= 1 && all(a, 's')) {
        concat(this._where, a);
      } else if (s === 'o') {
        if (a[0].length === undefined) {
          r = function(o, prefix) {
            var k, _r;
            if (prefix == null) {
              prefix = '';
            }
            _r = [];
            for (k in o) {
              if (typeof o[k] === 'object') {
                concat(_r, r(o[k], "" + (_this.escape_key(k)) + "."));
              } else {
                _r.push("" + prefix + (word(k) ? _this.escape_key(k) : k) + " = " + (_this.escape(o[k])));
              }
            }
            return _r;
          };
          concat(this._where, r(a[0]));
        }
      }
      return this;
    };

    _Class.prototype.group = _Class.prototype._simple('group');

    _Class.prototype.having = _Class.prototype._simple('having');

    _Class.prototype.order = _Class.prototype._simple('order');

    _Class.prototype.limit = function(_limit) {
      this._limit = _limit;
      return this;
    };

    _Class.prototype.take = _Class.prototype.limit;

    _Class.prototype.offset = function(_offset) {
      this._offset = _offset;
      return this;
    };

    _Class.prototype.skip = _Class.prototype.offset;

    _Class.prototype.escape_key = function(s) {
      return "`" + (s.toString().replace(/`/g, '')) + "`";
    };

    _Class.prototype.escape = function(s) {
      if (typeof s === 'undefined' || s === null) {
        return 'NULL';
      } else {
        return "'" + s.toString().replace(/'/g, "\'") + "'";
      }
    };

    _Class.prototype.toString = function() {
      return this.toSql();
    };

    _Class.prototype.toSql = function() {
      return ("SELECT\n " + (this._select.join(",\n ")) + "\n") + ("FROM " + (this.escape_key(this._table)) + "\n") + this._join.join("\n") + (this._where.length ? "WHERE\n " + (this._where.join(" AND \n ")) + "\n" : '') + (this._group.length ? "GROUP BY " + (this._group.join(', ')) + "\n" : '') + (this._order.length ? "ORDER BY " + (this._order.join(', ')) + "\n" : '') + (this._having.length ? "HAVING " + (this._having.join(', ')) + "\n" : '') + (this._limit ? "LIMIT " + this._limit + "\n" : '') + (this._offset ? "OFFSET " + this._offset + "\n" : '') + ';';
    };

    return _Class;

  })();

  CoffeeShop.Model = (function(_super) {

    __extends(_Class, _super);

    function _Class() {
      var a, k;
      _Class.__super__.constructor.call(this);
      this.id = null;
      this.table(this.constructor.name.pluralize().toLowerCase());
      this._attributes = {};
      this._has_one = [];
      this._has_many = [];
      this._has_and_belongs_to_many = [];
      this._belongs_to = [];
      a = arguments;
      for (k in a[0]) {
        this[k] = a[0][k];
      }
      return;
    }

    _Class.prototype.attr_accessible = function(a) {
      var k, _results;
      _results = [];
      for (k in a) {
        _results.push(this._attributes[a[k]] = true);
      }
      return _results;
    };

    _Class.prototype.attributes = function() {
      var attrs, k;
      attrs = {};
      attrs[this._primary_key] = this[this._primary_key];
      for (k in this) {
        if (!__hasProp.call(this, k)) continue;
        if (y(this._attributes[k]) !== 'u') {
          attrs[k] = this[k];
        }
      }
      return attrs;
    };

    _Class.prototype.serialize = function() {
      return JSON.stringify(this.attributes());
    };

    _Class.prototype.all = function(cb) {
      var _this = this;
      this.execute_sql(this.toSql(), function(err, records) {
        var k;
        if (err) {
          return cb(err);
        }
        for (k in records) {
          records[k] = new _this.constructor(records[k]);
        }
        cb(null, records);
      });
    };

    _Class.prototype.first = function(cb) {
      this.limit(1);
      return this.all(function(err, results) {
        if (err) {
          return cb(err);
        }
        return cb(null, results[0]);
      });
    };

    _Class.prototype.find = function(id, cb) {
      this.select('*');
      this.where({
        id: id
      });
      return this.first(cb);
    };

    _Class.prototype.exists = function(id, cb) {
      var conditions;
      conditions = {};
      conditions[this._primary_key] = id;
      return this.select('1').where(conditions).limit(1).first(function(err, result) {
        if (err) {
          return cb(err);
        }
        return cb(null, !!result);
      });
    };

    _Class.prototype.save = function(cb) {
      var attrs, begin, execute_sql, insert, update,
        _this = this;
      attrs = this.attributes();
      begin = function() {
        if (!this[this._primary_key]) {
          insert();
        } else {
          this.exists(this[this._primary_key], function(err, exists) {
            if (exists) {
              update();
            } else {
              insert();
            }
          });
        }
      };
      update = function() {
        var k, pairs, v;
        pairs = [];
        for (k in attrs) {
          v = attrs[k];
          if (!(k === _this._primary_key)) {
            pairs.push("" + (_this.escape_key(k)) + " = " + (_this.escape(v)));
          }
        }
        execute_sql(("UPDATE " + (_this.escape_key(_this._table)) + "\n") + ("SET " + (pairs.join(', ')) + "\n") + ("WHERE " + (_this.escape_key(_this._primary_key)) + " = " + (_this.escape(_this[_this._primary_key])) + ";"));
      };
      insert = function() {
        var k, names, v, values;
        names = [];
        values = [];
        for (k in attrs) {
          v = attrs[k];
          if (!(!(k === _this._primary_key))) {
            continue;
          }
          names.push(_this.escape_key(k));
          values.push(_this.escape(v));
        }
        execute_sql(("INSERT INTO " + (_this.escape_key(_this._table)) + " ") + ("(" + (names.join(', ')) + ") VALUES\n") + ("(" + (values.join(', ')) + ");"));
      };
      execute_sql = function(sql) {
        return _this.execute_sql(sql, cb);
      };
      begin();
    };

    _Class.build = function(o) {
      var instance;
      return instance = new this(o);
    };

    _Class.create = function(o, cb) {
      var instance;
      instance = new this(o);
      instance.save(cb || function() {});
      return instance;
    };

    _Class.prototype.execute_sql = function(sql, cb) {
      console.log("would have executed sql:", sql);
      console.log("override .execute_sql() function to make it happen for real.");
      return cb(null, true);
    };

    _Class.prototype["delete"] = function() {};

    _Class.prototype.deleteAll = function() {};

    _Class.prototype.has_one = function(s) {
      return this._has_one.push(s);
    };

    _Class.prototype.has_many = function(s) {
      return this._has_many.push(s);
    };

    _Class.prototype.has_and_belongs_to_many = function(s) {
      return this._has_and_belongs_to_many.push(s);
    };

    _Class.prototype.belongs_to = function(s) {
      return this._belongs_to.push(s);
    };

    _Class.prototype.validates_presence_of = function() {};

    _Class.prototype.validates_uniqueness_of = function() {};

    _Class.prototype.validates_format_of = function() {};

    _Class.prototype.transform_serialize = function() {};

    _Class.prototype.update_attributes = function() {};

    _Class.prototype.update_column = function() {};

    _Class.prototype.after_create = function() {};

    return _Class;

  })(CoffeeShop.Table);

  return CoffeeShop;

}).call(this);

y = function(v) {
  return (typeof v)[0];
};

sig = function(a) {
  var k, s;
  s = '';
  for (k in a) {
    s += y(a[k]);
  }
  return s;
};

word = function(s) {
  return y(s) === 's' && s.match(/^\w[\w\d]*$/) !== null;
};

concat = function(a, b) {
  var k;
  for (k in b) {
    a[k] = b[k];
  }
};

all = function(a, t) {
  return sig(a) === (new Array(a.length + 1)).join(t);
};
