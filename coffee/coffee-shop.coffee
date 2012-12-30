y=(v)->(typeof v)[0] # shorthand typeof
sig=(a)->s=''; s+=y(a[k]) for k of a; s # argument signature
string=(a)->a.length is 1 and sig(a) is 's'
word=(a)->string(a) and a[0].match(/^\w+$/) isnt null # when arguments = ['word']
concat=(a,b)->a[k] = b[k] for k of b
all=(a,t)->sig(a) is (new Array(a.length+1)).join t


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
        # ['first']
        # ['first, last']
        @_select.push a[0] # raw sql
      else if a.length > 1
        # ['first', 'last']
        concat @_select, a
      @
    # TODO: add alias: joins
    join: ->
      a = arguments
      if word(a) or a.length > 1
        # ['table2']
        # ['table2', 'table3']
        # TODO: lookup relationship and build query here
        for k of a
          @_joins.push "JOIN #{a[k]}\n ON 1"
      else if string a
        # ['LEFT OUTER JOIN table2 ON table1.id = table2.id']
        @_joins.push a[0] # raw sql
      @
    # TODO: add union?
    # TODO: implement OR; use raw sql conditions for now
    where: ->
      a = arguments
      s = sig a
      if a.length >= 2 and all(a, 's') and a[0].indexOf('?') isnt -1
        # ["customers.last LIKE 'a%?'", 'son']
        # ["customers.? LIKE 'a%?'", 'last', 'son']
        i = 0
        @_where.push a[0].replace /\?/g, -> a[++i]
      # decidedly not supporting these use cases
      # they can be achieved via separate where() calls
      #if a.length is 1 and sig is 'o' and a[0].length is 2
      #  # [["customers.last LIKE 'a%?'", 'son']]
      #  # [["customers.last LIKE 'a%?'", 'son'], ["customers.last LIKE 'a%?'", 'son']]
      #  # ["customers.first = 'bob'", ["customers.last LIKE 'a%?'", 'son']]
      #  # ["customers.first = 'bob'", ["customers.middle LIKE '%?%'", 'ert'], ["customers.last LIKE 'a%?'", 'son'], "customers.suffix = 'Jr.'"]
      else if a.length >= 1 and all(a, 's')
        # ["customers.first = 'bob'"]
        # ["customers.first = 'bob'", "customers.last = 'anderson'"]
        concat @_where, a # raw sql
      else if s is 'o'
        if a[0].length is `undefined` # hash
          # [{'customers.first': 'bob'}]
          # [{'customers.first': 'bob', 'customers.last': 'anderson'}]
          # [{customers: { first: 'bob'}}]
          r = (o, prefix='') ->
            _r = []
            for k of o
              if typeof o[k] is 'object'
                concat _r, r o[k], "#{k}."
              else
                _r.push "#{prefix}#{k} = \"#{o[k]}\"" # TODO: escape here
            return _r
          concat @_where, r a[0]
      @
    #TODO: select, group, having can probably be merged
    group: ->
      a = arguments
      if string a
        @_group.push a[0] # raw sql
      else if a.length > 1
        concat @_group, a
      @
    having: ->
      a = arguments
      if string a
        @_having.push a[0] # raw sql
      else if a.length > 1
        concat @_having, a
      @
    order: ->
      a = arguments
      if string a
        @_order.push a[0] # raw sql
      else if a.length > 1
        concat @_order, a
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
        (if @_where.length then "WHERE\n #{@_where.join(" AND \n ")}\n" else '')+
        (if @_group.length then "GROUP BY #{@_group.join(', ')}\n" else '')+
        (if @_order.length then "ORDER BY #{@_order.join(', ')}\n" else '')+
        (if @_having.length then "HAVING #{@_having.join(', ')}\n" else '')+
        (if @_limit then "LIMIT #{@_limit}\n" else '')+
        (if @_offset then "OFFSET #{@_offset}\n" else '')+
        ';'

  @Model: class extends CoffeeShop.Table # like ActiveRecord
    constructor: ->
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
