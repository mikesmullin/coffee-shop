y=(v)->(typeof v)[0] # shorthand typeof
sig=(a)->s=''; s+=y(a[k]) for k of a; s # argument signature
word=(s)->y(s) is 's' and s.match(/^\w[\w\d]*$/) isnt null # when arguments = ['word']
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
    project: -> select.apply @, arguments # alias
    _simple: (n) -> ->
      a = arguments
      if a.length >= 1 and all a, 's'
        for k of a when word a[k]
          console.log 'matched word'
          a[k] = @escape_key a[k]
        # ['a']
        # ['a=1']
        # ['a=1, b=1']
        # ['a=1', 'b=1']
        concat this["_#{n}"], a # raw sql
      @
    select: _Class::_simple 'select'
    joins: -> join.apply @, arguments # alias
    inclue: -> join.apply @, arguments # alias
    join: ->
      a = arguments
      if word(a[0]) or a.length > 1
        # ['table2']
        # ['table2', 'table3']
        # TODO: lookup relationship and build query here
        for k of a
          @_joins.push "JOIN #{@escape_key a[k]}\n ON 1"
      else if y a[0] is 's'
        # ['LEFT OUTER JOIN table2 ON table1.id = table2.id']
        @_joins.push a[0] # raw sql
      @
    # TODO: implement OR; use raw sql conditions for now
    where: ->
      a = arguments
      s = sig a
      if a.length >= 2 and all(a, 's') and a[0].indexOf('?') isnt -1
        # ["customers.last LIKE 'a%?'", 'son']
        # ["customers.? LIKE 'a%?'", 'last', 'son']
        i = 0
        @_where.push a[0].replace /\?/g, => @escape a[++i]
      else if a.length >= 1 and all(a, 's')
        # ["customers.first = 'bob'"]
        # ["customers.first = 'bob'", "customers.last = 'anderson'"]
        concat @_where, a # raw sql
      else if s is 'o'
        if a[0].length is `undefined` # hash
          # [{'customers.first': 'bob'}]
          # [{'customers.first': 'bob', 'customers.last': 'anderson'}]
          # [{customers: { first: 'bob'}}]
          r = (o, prefix='') =>
            _r = []
            for k of o
              if typeof o[k] is 'object'
                concat _r, r o[k], "#{@escape_key k}."
              else
                _r.push "#{prefix}#{@escape_key k} = #{@escape o[k]}"
            return _r
          concat @_where, r a[0]
      @
    group: _Class::_simple 'group'
    having: _Class::_simple 'having'
    order: _Class::_simple 'order'
    take: -> limit.apply @, arguments # alias
    limit: (@_limit) ->
      @
    skip: -> offset.apply @, arguments # alias
    offset: (@_offset) ->
      @

    #TODO: improve escape functions
    escape_key: (s) -> "`#{s.replace(/`/g, '')}`"
    escape: (s) -> "'"+s.replace(/'/g,"\'")+"'"
    toString: -> @toSql()
    toSql: ->
      sql = ''+
        "SELECT\n #{@_select.join(",\n ")}\n"+
        "FROM #{@escape_key @_table}\n"+
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
