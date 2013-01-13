// Generated by CoffeeScript 1.4.0
var Model,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

require('sugar');

module.exports = Model = (function(_super) {

  __extends(Model, _super);

  function Model() {
    var a, k;
    Model.__super__.constructor.apply(this, arguments);
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

  Model.prototype.attr_accessible = function(a) {
    var k, _results;
    _results = [];
    for (k in a) {
      _results.push(this._attributes[a[k]] = true);
    }
    return _results;
  };

  Model.prototype.attributes = function() {
    var attrs, k;
    attrs = {};
    attrs[this._primary_key] = this[this._primary_key];
    for (k in this) {
      if (!__hasProp.call(this, k)) continue;
      if (this._attributes[k]) {
        attrs[k] = this[k];
      }
    }
    return attrs;
  };

  Model.prototype.serialize = function() {
    return JSON.stringify(this.attributes());
  };

  Model.prototype.all = function(cb) {
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

  Model.prototype.first = function(cb) {
    this.limit(1);
    return this.all(function(err, results) {
      if (err) {
        return cb(err);
      }
      return cb(null, results[0]);
    });
  };

  Model.prototype.find = function(id, cb) {
    this.select('*');
    this.where({
      id: id
    });
    return this.first(cb);
  };

  Model.prototype.exists = function(id, cb) {
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

  Model.prototype.save = function(cb) {
    var attrs, k, names, pairs, sql, v, values;
    attrs = this.attributes();
    if (this[this._primary_key]) {
      pairs = [];
      for (k in attrs) {
        v = attrs[k];
        if (!(k === this._primary_key)) {
          pairs.push("" + (this.escape_key(k)) + " = " + (this.escape(v)));
        }
      }
      sql = ("UPDATE " + (this.escape_key(this._table)) + "\n") + ("SET " + (pairs.join(', ')) + "\n") + ("WHERE " + (this.escape_key(this._primary_key)) + " = " + (this.escape(this[this._primary_key])) + ";");
    } else {
      names = [];
      values = [];
      for (k in attrs) {
        v = attrs[k];
        if (!(!(k === this._primary_key))) {
          continue;
        }
        names.push(this.escape_key(k));
        values.push(this.escape(v));
      }
      sql = ("INSERT INTO " + (this.escape_key(this._table)) + " ") + ("(" + (names.join(', ')) + ") VALUES\n") + ("(" + (values.join(', ')) + ");");
    }
    return this.execute_sql(sql, cb);
  };

  Model.build = function(o) {
    var instance;
    return instance = new this(o);
  };

  Model.create = function(o, cb) {
    var instance;
    instance = new this(o);
    instance.save(cb || function() {});
    return instance;
  };

  Model.prototype.execute_sql = function(sql, cb) {
    console.log("would have executed sql:", sql);
    console.log("override .execute_sql() function to make it happen for real.");
    return cb(null);
  };

  Model.prototype["delete"] = function() {};

  Model.prototype.deleteAll = function() {};

  Model.prototype.has_one = function(s) {
    return this._has_one.push(s);
  };

  Model.prototype.has_many = function(s) {
    return this._has_many.push(s);
  };

  Model.prototype.has_and_belongs_to_many = function(s) {
    return this._has_and_belongs_to_many.push(s);
  };

  Model.prototype.belongs_to = function(s) {
    return this._belongs_to.push(s);
  };

  Model.prototype.validates_presence_of = function() {};

  Model.prototype.validates_uniqueness_of = function() {};

  Model.prototype.validates_format_of = function() {};

  Model.prototype.transform_serialize = function() {};

  Model.prototype.update_attributes = function() {};

  Model.prototype.update_column = function() {};

  Model.prototype.after_create = function() {};

  return Model;

})(require('./table'));
