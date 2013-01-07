var CoffeeShop, Session,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CoffeeShop = require('coffee-shop');

module.exports = Session = (function(_super) {

  __extends(Session, _super);

  function Session() {
    Session.__super__.constructor.apply(this, arguments);
    this.attr_accessible('session_id data'.split(' '));
  }

  return Session;

})(CoffeeShop.Model);
