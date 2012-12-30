CoffeeShop = require '../js/coffee-shop.js'
assert = require('chai').assert

describe 'CoffeeShop', ->
  describe 'Object-Relational Mapping', ->
    user = `undefined`
    sql = `undefined`

    beforeEach ->
      class User extends CoffeeShop.Model
        constructor: ->
          @table 'users'
          @has_one 'credit_card'
          @has_one 'pet'
          super()

      user = new User()

    _expecting = ''
    expecting = (s) ->
      _expecting = s

    afterEach ->
      if _expecting
        assert.equal _expecting, sql
      else
        #console.log JSON.stringify sql
        console.log sql

    it 'can select single argument word', ->
      sql = user.select('first').toSql()
      #assert.equal "SELECT\n first\nFROM users\n;", sql

    it 'can select multi argument words', ->
      sql = user.select('first', 'last').toSql()
      #assert.equal "SELECT\n first,\n [object Arguments]\nFROM users\n;", sql

    it 'can select single argument raw sql', ->
      sql = user.select('first, last').toSql()
      #assert.equal "SELECT\n first,\n [object Arguments]\nFROM users\n;", sql

    it 'can join single argument word', ->
      scope = user.select('*')
      sql = scope.join('table2').toSql()
      #assert.equal "SELECT\n first,\n [object Arguments]\nFROM users\n;", sql

    it 'can join multi argument words', ->
      scope = user.select('*')
      sql = scope.join('table2', 'table3').toSql()
      #assert.equal "SELECT\n first,\n [object Arguments]\nFROM users\n;", sql

    it 'can join single argument raw sql', ->
      scope = user.select('*')
      sql = scope.join('LEFT OUTER JOIN table2 ON table1.id = table2.id').toSql()
      #assert.equal "SELECT\n first,\n [object Arguments]\nFROM users\n;", sql

    it 'can where single argument single item object', ->
      scope = user.select('*')
      sql = scope.where('customers.first': 'bob').toSql()
      #assert.equal "SELECT\n first,\n [object Arguments]\nFROM users\n;", sql

    it 'can where single argument multi item object', ->
      scope = user.select('*')
      sql = scope.where('customers.first': 'bob', 'customers.last': 'doe').toSql()
      #assert.equal "SELECT\n first,\n [object Arguments]\nFROM users\n;", sql

    it 'can where single argument recursive item object', ->
      scope = user.select('*')
      sql = scope.where(customers: { first: 'bob', last: 'doe' }).toSql()
      #assert.equal "SELECT\n first,\n [object Arguments]\nFROM users\n;", sql
