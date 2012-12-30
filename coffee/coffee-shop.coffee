sugar = require 'sugar'

module.exports = class CoffeeShop
  @Table: class # like Arel
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
    select: _Class::_simple 'select'
    project: _Class::select # alias
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
    joins: _Class::join # alias
    include: _Class::join # alias
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
    group: _Class::_simple 'group'
    having: _Class::_simple 'having'
    order: _Class::_simple 'order'
    limit: (@_limit) ->
      @
    take: _Class::limit # alias
    offset: (@_offset) ->
      @
    skip: _Class::offset # alias

    #TODO: improve escape functions
    escape_key: (s) -> "`#{s.toString().replace(/`/g, '')}`"
    escape: (s) -> "'"+s.toString().replace(/'/g,"\'")+"'"
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

  @Model: class extends CoffeeShop.Table # like ActiveRecord
    constructor: ->
      super()
      @id = null
      @table @constructor.name.pluralize().toLowerCase()
      @_non_attributes = {}
      for k of _ref = '_non_attributes _table table _primary_key primary_key _simple _select select project _join join joins include _where where _group group _having having _order order _limit limit take _offset offset skip escape_key escape toString toSql _has_one has_one _has_many has_many _has_and_belongs_to_many has_and_belongs_to_many _belongs_to belongs_to attr_accessible serialize validates_presence_of execute_sql all first last find attributes save mount_uploader validates_uniqueness_of validates_format_of transform_serialize update_attributes update_column after_create build create'.split ' '
        @_non_attributes[_ref[k]] = true
      @_has_one = []
      @_has_many = []
      @_has_and_belongs_to_many = []
      @_belongs_to = []
      a = arguments
      for k of a[0]
        @[k] = a[0][k]
      return

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
    attributes: ->
      attrs = {}
      for k of @
        if typeof @_non_attributes[k] is 'undefined'
          attrs[k] = @[k]
      return attrs
    serialize: ->
      JSON.stringify @attributes()
    save: (cb) ->
      attrs = @attributes()
      if @[@_primary_key]
        pairs = []
        for k, v of attrs when not (k is @_primary_key)
          pairs.push "#{@escape_key k} = #{@escape v}"
        sql = "UPDATE #{@escape_key @_table}\n"+
          "SET #{pairs.join(', ')}\n"+
          "WHERE #{@escape_key @_primary_key} = #{@escape @[@_primary_key]};"
      else
        names = []
        values = []
        for k, v of attrs when not (k is @_primary_key)
          names.push @escape_key k
          values.push @escape v
        sql = "INSERT INTO #{@escape_key @_table} "+
          "(#{names.join(', ')}) VALUES\n"+
          "(#{values.join(', ')});"
      @execute_sql sql, cb
    @build: (o) ->
      return instance = new @ o
    @create: (o, cb) ->
      instance = new @ o
      #validate()
      instance.save cb
      return instance

    execute_sql: (sql, cb) ->
      # db-proprietary; overridable
      # e.g. app.db.exec sql, cb
      console.log "would have executed sql:", sql
      console.log "override .execute_sql() function to make it happen for real."
      cb null

    # pending
    has_one: (s) -> @_has_one.push s
    has_many: (s) -> @_has_many.push s
    has_and_belongs_to_many: (s) -> @_has_and_belongs_to_many.push s
    belongs_to: (s) -> @_belongs_to.push s
    attr_accessible: ->
    validates_presence_of: ->
    mount_uploader: ->
    validates_uniqueness_of: ->
    validates_format_of: ->
    transform_serialize: ->
    update_attributes: ->
    update_column: ->
    after_create: ->

y=(v)->(typeof v)[0] # shorthand typeof
sig=(a)->s=''; s+=y(a[k]) for k of a; s # argument signature
word=(s)->y(s) is 's' and s.match(/^\w[\w\d]*$/) isnt null # when arguments = ['word']
concat=(a,b)->a[k] = b[k] for k of b; return
all=(a,t)->sig(a) is (new Array(a.length+1)).join t
