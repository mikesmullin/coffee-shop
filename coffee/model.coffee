require 'sugar'
module.exports = class Model extends require('./table') # ORM like ActiveRecord
  constructor: ->
    super
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
    for own k of @ when @_attributes[k]
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
