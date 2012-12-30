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
        console.log sql
        console.log JSON.stringify sql
        assert.equal _expecting, sql
        _expecting = ''
      else
        console.log JSON.stringify sql
        #console.log sql

    it 'can select single argument word', ->
      sql = user.select('first').toSql()
      expecting "SELECT\n `first`\nFROM `users`\n;"

    it 'can select multi argument words', ->
      sql = user.select('first', 'last').toSql()
      expecting "SELECT\n `first`,\n `last`\nFROM `users`\n;"

    it 'can select single argument raw sql string', ->
      sql = user.select('first, last').toSql()
      expecting "SELECT\n first, last\nFROM `users`\n;"

    it 'can join single argument word', ->
      scope = user.select('*')
      sql = scope.join('table2').toSql()
      expecting "SELECT\n *\nFROM `users`\nJOIN `table2`\n ON 1;"

    it 'can join multi argument words', ->
      scope = user.select('*')
      sql = scope.join('table2', 'table3').toSql()
      expecting "SELECT\n *\nFROM `users`\nJOIN `table2`\n ON 1\nJOIN `table3`\n ON 1;"

    it 'can join single argument raw sql string', ->
      scope = user.select('*')
      sql = scope.join('LEFT OUTER JOIN table2 ON table1.id = table2.id').toSql()
      expecting "SELECT\n *\nFROM `users`\nLEFT OUTER JOIN table2 ON table1.id = table2.id;"

    it 'can where dual argument strings with one or more replacements', ->
      scope = user.select('*')
      sql = scope.where("customers LIKE ? OR customers LIKE ?", 'son', 'maker').toSql()
      expecting "SELECT\n *\nFROM `users`\nWHERE\n customers LIKE 'son' OR customers LIKE 'maker'\n;"

    it 'can where one or more raw sql strings', ->
      scope = user.select('*')
      sql = scope.where("customers.first = 'bob'").toSql()
      assert.equal "SELECT\n *\nFROM users\nWHERE\n customers.first = 'bob'\n;", sql
      sql = scope.where("customers.first = 'bob'", "customers.last = 'anderson'").toSql()
      expecting "SELECT\n *\nFROM users\nWHERE\n customers.first = 'bob' AND \n customers.last = 'anderson'\n;"

    it 'can where single argument single item object', ->
      scope = user.select('*')
      sql = scope.where('customers.first': 'bob').toSql()
      expecting "SELECT\n *\nFROM users\nWHERE\n customers.first = \"bob\"\n;"

    it 'can where single argument multi item object', ->
      scope = user.select('*')
      sql = scope.where('customers.first': 'bob', 'customers.last': 'doe').toSql()
      expecting "SELECT\n *\nFROM users\nWHERE\n customers.first = \"bob\" AND \n customers.last = \"doe\"\n;"

    it 'can where single argument recursive item object', ->
      scope = user.select('*')
      sql = scope.where(customers: { first: 'bob', last: 'doe' }).toSql()
      expecting "SELECT\n *\nFROM users\nWHERE\n customers.first = \"bob\" AND \n customers.last = \"doe\"\n;"
