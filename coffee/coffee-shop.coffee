# private helper methods
y=(v)->(typeof v)[0] # shorthand typeof
sig=(a)->s=''; s+=y(a[k]) for k of a; s # argument signature
word=(s)->y(s) is 's' and s.match(/^\w[\w\d]*$/) isnt null # when arguments = ['word']
concat=(a,b)->a[k] = b[k] for k of b
all=(a,t)->sig(a) is (new Array(a.length+1)).join t
non_enumerable=(o,n)->p = Object.getOwnPropertyDescriptor o, n;p.enumerable = false;Object.defineProperty o, n, p;return
non_enum_method=(o,n,f)->o[n] = f;non_enumerable o, n
PrimitiveObject = (@_s) ->
PrimitiveObject::_s = `undefined`
PrimitiveObject::set = (@_s) ->
PrimitiveObject::toString = -> @_s
non_enum_attr=(o,n,v)->o[n] = v;non_enumerable o, n
non_enum_attr_accessor=(o,n,d)->non_enum_attr o, '_'+n, new PrimitiveObject d; non_enum_method o, n, (s) -> if arguments.length then o['_'+n].set s else ''+o['_'+n]
non_enum_attr_writer=(o,n,d,f)->non_enum_attr o, '_'+n, d; non_enum_method o, n, f
non_enum_attr_reader=(o,n,f)->

# main class
module.exports = CoffeeShop = -> # constructor

# SQL query string builder; like Arel
# TODO: provide options to enable a noSQL version
CoffeeShop.Table = Table = (@name) -> # constructor

non_enum_attr_accessor Table::, 'table'
non_enum_attr_accessor Table::, 'primary_key', 'id'

# chainables
non_enum_method Table::, '_simple', (n) -> ->
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
non_enum_method Table::, 'select', Table::_simple 'select'
non_enum_method Table::, 'project', Table::select # alias
non_enum_method Table::, 'join' = ->
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
non_enum_method Table::, 'joins', Table::join # alias
non_enum_method Table::, 'include', Table::join # alias
# TODO: implement OR; use raw sql conditions for now
non_enum_method Table::, 'where', ->
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
non_enum_method Table::, 'group', Table::_simple 'group'
non_enum_method Table::, 'having', Table::_simple 'having'
non_enum_method Table::, 'order', Table::_simple 'order'
non_enum_method Table::, 'limit', (@_limit) ->
  @
non_enum_method Table::, 'take', Table::limit # alias
non_enum_method Table::, 'offset', (@_offset) ->
  @
non_enum_method Table::, 'skip', Table::offset # alias

#TODO: improve escape functions
Table::escape_key = (s) -> "`#{s.replace(/`/g, '')}`"
Table::escape = (s) -> "'"+s.replace(/'/g,"\'")+"'"
Table::toString = -> @toSql()
Table::toSql = ->
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

CoffeeShop.Model = Model = class extends CoffeeShop.Table # like ActiveRecord
  constructor: ->
    @_has_one = []
    @_has_many = []
    @_has_and_belongs_to_many = []
    @_belongs_to = []
    non_enumerable @, ('has_one _has_one has_many _has_many has_and_belongs_to_many '+
      '_has_and_belongs_to_many belongs_to _belongs_to attr_accessible serialize validates_presence_of '+
      'execute_sql all first last find save').split ' '
    super()

  has_one: (s) -> @_has_one.push s
  has_many: (s) -> @_has_many.push s
  has_and_belongs_to_many: (s) -> @_has_and_belongs_to_many.push s
  belongs_to: (s) -> @_belongs_to.push s

  attr_accessible: ->
  serialize: ->
  validates_presence_of: ->

  execute_sql: (sql, cb) ->
    # db-proprietary; overridable
    app.db.exec sql, cb
  all: (cb) ->
    @execute_sql @toSql(), cb
  first: (cb) ->
    @all (err, results) ->
      cb results[0]
  last: (cb) ->
    @all (err, results) ->
      cb results[results.length-1]
  find: (id, cb) ->
    @where id: id
    @first cb
  save: (cb) ->
    sql = "#{if @[@_primary_key] then 'UPDATE' else 'INSERT INTO'} #{escape_key @_table} "+
      "() VALUES\n"+
      " ("+@_records.join("),\n (")+");"
    @execute_sql sql, cb


non_enum_attr_writer CoffeeShop, 'has_one', [], (s) ->
  @_has_one.push s
