var CoffeeShop, User,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CoffeeShop = require('coffee-shop');

module.exports = User = (function(_super) {

  __extends(User, _super);

  function User() {
    User.__super__.constructor.apply(this, arguments);
    this.attr_accessible('first last email username password_digest'.split(' '));
  }

  return User;

})(CoffeeShop.Model);
