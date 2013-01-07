CoffeeShop = require 'coffee-shop'

module.exports = class User extends CoffeeShop.Model
  constructor: ->
    (super)
    @attr_accessible ('first last email username password_digest').split ' '
