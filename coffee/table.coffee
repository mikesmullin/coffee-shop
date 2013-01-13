module.exports = class Table # like Arel
  constructor: ->
    @_table = ''
    @_select = []
    @_primary_key = 'id'
    @_select = []
    @_join = []
    @_where = []
    @_group = []
    @_having = []
    @_order = []
    @_limit = 0
    @_offset = 0
    return

  table: (@_table) ->
  primary_key: (@_primary_key) ->

  # chainables
  _simple: (n) -> ->
    a = arguments
    if a.length >= 1 and all a, 's'
      for k of a when word a[k]
        a[k] = @escape_key a[k]
      # ['a']
      # ['a=1']
      # ['a=1, b=1']
      # ['a=1', 'b=1']
      concat @["_#{n}"], a # raw sql
    @
  select: Table::_simple 'select'
  project: Table::select # alias
  join: ->
    a = arguments
    if word(a[0]) or a.length > 1
      # ['table2']
      # ['table2', 'table3']
      # TODO: lookup relationship and build query here
      for k of a
        @_join.push "JOIN #{@escape_key a[k]}\n ON 1"
    else if y a[0] is 's'
      # ['LEFT OUTER JOIN table2 ON table1.id = table2.id']
      @_join.push a[0] # raw sql
    @
  joins: Table::join # alias
  include: Table::join # alias
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
              _r.push "#{prefix}#{if word(k) then @escape_key k else k} = #{@escape o[k]}"
          return _r
        concat @_where, r a[0]
    @
  group: Table::_simple 'group'
  having: Table::_simple 'having'
  order: Table::_simple 'order'
  limit: (@_limit) ->
    @
  take: Table::limit # alias
  offset: (@_offset) ->
    @
  skip: Table::offset # alias

  #TODO: improve escape functions
  escape_key: (s) -> "`#{s.toString().replace(/`/g, '')}`"
  escape: (s) ->
    if typeof s is 'undefined' or s is null
      'NULL'
    else
      "'"+s.toString().replace(/'/g,"\'")+"'"
  toString: -> @toSql()
  toSql: ->
    "SELECT\n #{@_select.join(",\n ")}\n"+
    "FROM #{@escape_key @_table}\n"+
    @_join.join("\n")+
    (if @_where.length then "WHERE\n #{@_where.join(" AND \n ")}\n" else '')+
    (if @_group.length then "GROUP BY #{@_group.join(', ')}\n" else '')+
    (if @_order.length then "ORDER BY #{@_order.join(', ')}\n" else '')+
    (if @_having.length then "HAVING #{@_having.join(', ')}\n" else '')+
    (if @_limit then "LIMIT #{@_limit}\n" else '')+
    (if @_offset then "OFFSET #{@_offset}\n" else '')+
    ';'

y=(v)->(typeof v)[0] # shorthand typeof
sig=(a)->s=''; s+=y(a[k]) for k of a; s # argument signature
word=(s)->y(s) is 's' and s.match(/^\w[\w\d]*$/) isnt null # when arguments = ['word']
concat=(a,b)->a[k] = b[k] for k of b; return
all=(a,t)->sig(a) is (new Array(a.length+1)).join t
