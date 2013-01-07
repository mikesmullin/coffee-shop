path = require 'path'
fs = require 'fs'
sugar = require 'sugar'
express = require 'express'
async = require 'async2'
app = express()
server = `undefined`
cb = ->
module.exports = (f) -> cb = f
flow = new async

flow.serial (next) -> # configure
  app.PORT = process.env.PORT or 3001
  app.ENV = process.env.ENV or 'development'
  app.STATIC = path.join __dirname, 'static', path.sep
  app.PUBLIC = path.join app.STATIC, 'public', path.sep
  app.ASSETS = path.join app.PUBLIC, 'assets', path.sep
  app.APP = path.join app.STATIC, 'app', path.sep
  app.SERVER_CONTROLLERS = path.join app.APP, 'controllers', path.sep
  app.SERVER_MODELS = path.join app.APP, 'models', path.sep
  app.SERVER_HELPERS = path.join app.APP, 'helpers', path.sep
  app.SHARED_HELPERS = path.join app.ASSETS, 'helpers', path.sep
  app.set 'title', ''

  # CoffeeTemplates.__express
  require_fresh=(a)->delete require.cache[require.resolve a];require a
  app.locals require_fresh app.SHARED_HELPERS+'templates'
  app.response._render = app.response.render
  app.response.render = (name, options, cb) ->
    options = options or {}
    options.view = name
    options.layout =
      if options.layout
        path.join 'shared', 'layouts', options.layout
      else
        path.join 'shared', 'layouts', 'application'
    if name.indexOf('server'+path.sep) is 0
      name = path.join 'app', 'views', 'templates'
    else # shared
      name = path.join 'public', 'assets', 'templates'
    @_render name, options, cb
  app.set 'view engine', 'js'
  app.set 'views', app.STATIC
  app.engine 'js', (file, options, cb) ->
    fs.readFile file, 'utf8', (err, templates) ->
      if file.indexOf(path.join 'static', 'app', 'views', 'templates.js') isnt -1 # server-only template requested
        # splice-in shared templates; this extra cpu avoids double-tree stored on disk
        fs.readFile app.ASSETS+'templates.js', 'utf8', (err, shared_templates) ->
          templates = templates.split("\n")
          templates.splice -2, 0, shared_templates.split("\n").slice(2,-2).join("\n")
          render templates.join("\n")
      else
        render templates
    render = (js) ->
      eval js # returns templates() function
      #console.log "rendering with options", options
      cb null, templates options.view, options

  # static file server
  app.use express.static app.PUBLIC
  next()

flow.serial (next) -> # database
  sql = require 'node-sqlite-purejs'
  sql.open db_file = "#{app.STATIC}db/#{app.ENV}.sqlite", {}, (err, db) ->
    throw err if err
    app.db = db
    console.log "opened db #{db_file}"
    app.require_model = (file) ->
      Model = require app.SERVER_MODELS+file
      Model::execute_sql = (q, cb) ->
        console.log "executing sql: #{q}"
        return app.db.exec q, cb
      return Model
    app.model = (file) ->
      new (app.require_model file)
    next()

flow.serial (next) -> # middleware
  app.use express.cookieParser()
  app.use express.bodyParser()
  # http request logger
  app.use (req, res, done) ->
    console.log "#{req.method} \"#{req.url}\" for #{req.ip} at #{Date.create().iso()}"
    console.log "POSTDATA ", req.body if JSON.stringify(req.body) isnt '{}'
    done()
  app.use express.methodOverride()
  app.use express.session
    key: require(path.join __dirname, 'package.json').name+'.sid'
    secret: "<REPLACE WITH YOUR KEYBOARD CAT HERE>"
    cookie: path: '/', maxAge: 1000*60*30 # 30mins
    store: new class SQLiteStore extends express.session.Store
      get: (session_id, cb) ->
        app.model('session').select('data').where(session_id: session_id).first (err, session) ->
          return cb err if err
          cb null, if session then JSON.parse session.data else undefined
      set: (session_id, data, cb) ->
        session = app.model('session')
        session.select('id').where(session_id: session_id).first (err, result) ->
          return cb err if err
          session.id = result.id if result
          session.session_id = session_id
          session.data = JSON.stringify data
          session.save (err) ->
            return cb err if err
            cb null
  app.use require('connect-flash')()
  #app.use express.csrf()
  app.use (req, res, next) ->
    res.locals._csrf = req.session._csrf
    res.locals.flash =
      alert: req.flash 'error'
      notice: req.flash 'notice'
    res.locals.current_user = req.user
    next()

  app.require_auth = (req, res, next) ->
    return next() if req.isAuthenticated()
    res.redirect "/"

  next()

flow.go -> # ready
  # controllers
  require(app.SERVER_CONTROLLERS+'application') app

  unless process.env.BOOTSTRAP
    # start server
    server = app.listen app.PORT
    console.log "listening on http://localhost:#{app.PORT}/"
    process.on 'SIGINT', ->
      console.log "caught SIGINT. will attempt safe shutdown..."
      server.close()

  process.nextTick -> cb app # indicate readiness
