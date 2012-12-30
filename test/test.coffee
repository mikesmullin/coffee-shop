CoffeeShop = require '../js/coffee-shop.js'
assert = require('chai').assert

describe 'CoffeeShop', ->
  describe 'Object-Relational Mapping', ->
    user = `undefined`
    User = `undefined`
    sql = `undefined`
    _expecting = `undefined`
    expecting = (s) ->
      _expecting = s

    beforeEach ->
      class User extends CoffeeShop.Model
        constructor: ->
          (super)
          # pending
          #@has_one 'credit_card'
          #@has_one 'pet'
          return

      user = new User()
      _expecting = `undefined`

    afterEach ->
      if _expecting isnt false
        if _expecting
          #console.log sql
          #console.log JSON.stringify sql
          assert.equal sql, _expecting
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
      assert.equal sql, "SELECT\n *\nFROM `users`\nWHERE\n customers.first = 'bob'\n;"
      sql = scope.where("customers.first = 'bob'", "customers.last = 'anderson'").toSql()
      expecting "SELECT\n *\nFROM `users`\nWHERE\n customers.first = 'bob' AND \n customers.last = 'anderson'\n;"

    it 'can where single argument single item object', ->
      scope = user.select('*')
      sql = scope.where('customers.first': 'bob').toSql()
      expecting "SELECT\n *\nFROM `users`\nWHERE\n customers.first = \'bob\'\n;"

    it 'can where single argument multi item object', ->
      scope = user.select('*')
      sql = scope.where('customers.first': 'bob', 'customers.last': 'doe').toSql()
      expecting "SELECT\n *\nFROM `users`\nWHERE\n customers.first = 'bob' AND \n customers.last = 'doe'\n;"

    it 'can where single argument recursive item object', ->
      scope = user.select('*')
      sql = scope.where(customers: { first: 'bob', last: 'doe' }).toSql()
      expecting "SELECT\n *\nFROM `users`\nWHERE\n `customers`.`first` = 'bob' AND \n `customers`.`last` = 'doe'\n;"

    it 'can return a list of attributes', ->
      user.id = 1
      user.first_name = 'bob'
      user.last_name = 'anderson'
      o = user.attributes()
      assert.deepEqual {"id":1,"first_name":"bob","last_name":"anderson"}, o
      _expecting = false

    it 'can build new models, without validating or saving', ->
      user = User.build first_name: 'bob', last_name: 'anderson'
      o = user.attributes()
      assert.deepEqual {"id":null,"first_name":"bob","last_name":"anderson"}, o
      _expecting = false

    it 'can build insert statement from model attributes', (done) ->
      #user.id = null
      user.first_name = 'bob'
      user.last_name = 'anderson'
      user.execute_sql = (_sql, cb) ->
        sql = _sql
        cb null
      user.save (err) ->
        done()
      expecting "INSERT INTO `users` (`first_name`, `last_name`) VALUES\n('bob', 'anderson');"

    it 'can build update statement from model attributes', (done) ->
      user.id = 1
      user.first_name = 'bob'
      user.last_name = 'anderson'
      user.execute_sql = (_sql, cb) ->
        sql = _sql
        cb null
      user.save (err) ->
        done()
      expecting "UPDATE `users`\nSET `first_name` = 'bob', `last_name` = 'anderson'\nWHERE `id` = '1';"

    it 'can serialize model attributes', ->
      user.id = 1
      user.first_name = 'bob'
      user.last_name = 'anderson'
      sql = user.serialize()
      expecting "{\"id\":1,\"first_name\":\"bob\",\"last_name\":\"anderson\"}"

    it 'can update_attributes, automatically validating and saving'
    it 'can update_column, without validating or saving'

    it 'can create new models, automatically validating and saving', (done) ->
      User::execute_sql = (_sql, cb) ->
        sql = _sql
        cb null
      user = User.create first_name: 'bob', last_name: 'anderson', (err, result) ->
        done()
      expecting "INSERT INTO `users` (`first_name`, `last_name`) VALUES\n('bob', 'anderson');"
