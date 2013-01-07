CoffeeShop = require 'coffee-shop'

module.exports = class Session extends CoffeeShop.Model
  constructor: ->
    (super)
    @attr_accessible 'session_id data'.split ' '
