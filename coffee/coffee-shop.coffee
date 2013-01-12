sugar = require 'sugar'

module.exports = class CoffeeShop
  @Server: -> # like Express
    connect = require 'connect'
    app = connect()
    for k, method of methods = ['GET','POST','PUT','DELETE']
      ((method)=>
        app[method.toLowerCase()] = (uri, cb) =>
          app.use (req, res, next) =>
            if req.method is method
              if (params=req.url.match(new RegExp "^#{uri}$")) isnt null
                req.params = params.slice 1
                console.log "res.send was: ", res.send
                console.log "res.render was: ", res.render
                out = ''
                res.send = (s) -> out += s
                res.render = (file) -> out += file
                cb req, res
                res.end out
                return
            next()
      )(method)

    app.use (req, res, next) ->
      res.locals = {}
      next()

    path = require 'path'
    process.env.NODE_ENV = process.env.NODE_ENV or 'development'
    app.PORT = process.env.PORT or 3001
    app.STATIC = path.join process.cwd(), 'static', path.sep
    app.PUBLIC = path.join app.STATIC, 'public', path.sep
    app.ASSETS = path.join app.PUBLIC, 'assets', path.sep
    app.APP = path.join app.STATIC, 'app', path.sep
    app.CONFIG = path.join app.STATIC, 'config', path.sep
    app.SERVER_CONTROLLERS = path.join app.APP, 'controllers', path.sep
    app.SHARED_CONTROLLERS = path.join app.ASSETS, 'controllers', path.sep
    app.SERVER_MODELS = path.join app.APP, 'models', path.sep
    app.SERVER_HELPERS = path.join app.APP, 'helpers', path.sep
    app.SHARED_HELPERS = path.join app.ASSETS, 'helpers', path.sep

    process.on 'uncaughtException', (err) ->
      if err.code is 'EADDRINUSE'
        process.stderr.write "FATAL: port is already open. kill all node processes and try again."
        process.exit 1

    return {
      app: app
      connect: connect
    }

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

  @Model: class extends CoffeeShop.Table # like ActiveRecord
    constructor: ->
      super()
      @id = null
      @table @constructor.name.pluralize().toLowerCase()
      @_attributes = {}
      @_has_one = []
      @_has_many = []
      @_has_and_belongs_to_many = []
      @_belongs_to = []
      a = arguments
      for k of a[0]
        @[k] = a[0][k]
      return

    attr_accessible: (a) ->
      for k of a
        @_attributes[a[k]] = true
    attributes: ->
      attrs = {}
      attrs[@_primary_key] = @[@_primary_key]
      for own k of @ when y(@_attributes[k]) isnt 'u'
        attrs[k] = @[k]
      return attrs
    serialize: ->
      JSON.stringify @attributes()

    all: (cb) ->
      @execute_sql @toSql(), (err, records) =>
        return cb err if err
        for k of records
          records[k] = new @constructor records[k]
        cb null, records
        return
      return
    first: (cb) ->
      @limit 1
      @all (err, results) ->
        return cb err if err
        cb null, results[0]
    # may as well ask for all()
    #last: (cb) ->
    #  @limit 1
    #  @all (err, results) ->
    #    return cb err if err
    #    cb null, results[results.length-1]
    find: (id, cb) ->
      @select '*'
      @where id: id
      @first cb
    exists: (id, cb) ->
      conditions = {}
      conditions[@_primary_key] = id
      @select('1').where(conditions).limit(1).first (err, result) ->
        return cb err if err
        cb null, !!result
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
      instance.save cb or ->
      return instance

    execute_sql: (sql, cb) ->
      # db-proprietary; overridable
      # e.g. app.db.exec sql, cb
      console.log "would have executed sql:", sql
      console.log "override .execute_sql() function to make it happen for real."
      cb null

    # pending
    delete: ->
    deleteAll: ->
    has_one: (s) -> @_has_one.push s
    has_many: (s) -> @_has_many.push s
    has_and_belongs_to_many: (s) -> @_has_and_belongs_to_many.push s
    belongs_to: (s) -> @_belongs_to.push s
    validates_presence_of: ->
    #mount_uploader: -> # should be third-party provided
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
