y=(v)->(typeof v)[0] # shorthand typeof
sig=(a)->s=''; s+=y(a[k]) for k of a; s # argument signature
string=(a)->a.length is 1 and sig(a) is 's'
word=(a)->string(a) and a[0].match(/^\w+$/) isnt null # when arguments = ['word']

module.exports = class CoffeeShop
  @Table: class # like Arel
    constructor: (@name) ->
      @_select = []
      @_joins = []
      @_where = []
      @_group = []
      @_having = []
      @_order = []
      @_limit = 0
      @_offset = 0

    # chainables
    select: ->
      a = arguments
      if string a
        @_select.push a[0] # raw sql
      else if a.length > 1
        @_select = @_select.concat a
      @
    joins: ->
      a = arguments
      if word a or a.length > 1 # list of table names
        # TODO: lookup relationship and build query here
        @_joins.push a[0]
      else if string a
        @_joins.push a[0] # raw sql
      @
    where: ->
      # "orders.name = 'bob'"
      # ["orders.name LIKE '%?%'", 'bob']
      # { 'orders.name': 'bob' }
      # { orders: { name: 'bob' } }
      @
    #TODO: select, group, having can probably be merged
    group: ->
      a = arguments
      if string a
        @_group.push a[0] # raw sql
      else if a.length > 1
        @_group = @_group.concat a
      @
    having: ->
      a = arguments
      if string a
        @_having.push a[0] # raw sql
      else if a.length > 1
        @_having = @_having.concat a
      @
    order: ->
      a = arguments
      if string a
        @_order.push a[0] # raw sql
      else if a.length > 1
        @_order = @_order.concat a
      @
    # TODO: add fn aliases: take, skip, project, include
    limit: (@_limit) ->
      @
    offset: (@_offset) ->
      @
    #TODO: add escape function
    toString: -> @toSql()
    toSql: ->
      sql = ''+
        "SELECT\n #{@_select.join(",\n ")}\n"+
        "FROM #{@_table}\n"+
        @_joins.join("\n")+
        (if @_group.length then "GROUP BY #{@_group.join(', ')}\n" else '')+
        (if @_order.length then "ORDER BY #{@_order.join(', ')}\n" else '')+
        (if @_having.length then "HAVING #{@_having.join(', ')}\n" else '')+
        (if @_limit then "LIMIT #{@_limit}\n" else '')+
        (if @_offset then "OFFSET #{@_offset}\n" else '')+
        ';'

  @Model: class extends CoffeeShop.Table # like ActiveRecord
    constructor: ->
      console.log "hi. table is #{@_table}"
      console.log "has_ones: #{@_has_one.join(', ')}"
      super()
    table: (@_table) ->
    _has_one: []
    has_one: (s) ->
      @_has_one.push s
    has_many: ->
    has_and_belongs_to_many: ->
    belongs_to: ->
    serialize: ->
    attr_accesible: ->
    validates_presence_of: ->

    execute_sql: (sql, cb) ->
      # db-proprietary
      app.db.exec sql, cb
    find: (id, cb) ->
      @where id: id
      @execute_sql @toSql(), cb
    all: ->
    first: ->
    last: ->
    save: ->
      # ask arel to generate sql
      # db-proprietary interface goes here
