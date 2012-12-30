CoffeeShop = require '../js/coffee-shop.js'
assert = require('chai').assert

describe 'CoffeeShop', ->
  describe 'Object-Relational Mapping', ->
    user = `undefined`
    beforeEach ->
      class User extends CoffeeShop.Model
        constructor: ->
          @table 'users'
          @has_one 'credit_card'
          @has_one 'pet'
          super()

      user = new User()

    it 'works', ->
      sql = user.select('first').toSql()
      assert.equal "SELECT\n first\nFROM users\n;", sql

      sql = user.select('first', 'last').toSql()
      assert.equal "SELECT\n first,\n [object Arguments]\nFROM users\n;", sql
