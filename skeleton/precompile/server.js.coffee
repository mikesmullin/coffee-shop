{ app, connect, fetch, flow } = require('coffee-shop').Server()

# middleware
app.use connect.logger 'dev'
app.use connect.static app.PUBLIC
app.use connect.methodOverride()
app.use connect.cookieParser()
app.use connect.bodyParser()
#app.use connect.csrf()

# database
flow.serial (next) ->
  mysql     = require 'mysql'
  db_config = require(app.CONFIG+'database.json')[process.env.NODE_ENV]
  db_name   = db_config.database; delete db_config.database
  app.db    = mysql.createConnection db_config
  app.db.on 'error', (err) ->
    if err.code is 'ER_BAD_DB_ERROR'
      process.stderr.write "WARNING: could not locate database \"#{db_config.database}\"\n"
    else throw err
  app.db.connect ->
    app.db.query "USE `#{db_name}`;", ->
      app.require_model = (file) ->
        Model = require app.SERVER_MODELS+file
        Model::execute_sql = (q, cb) ->
          console.log "executing sql: #{q}"
          return app.db.query q, cb
        return Model
      app.model = (file) ->
        new (app.require_model file)
      app.use connect.session
        key:    require(path.join __dirname, 'package.json').name+'.sid'
        secret: "<REPLACE WITH YOUR KEYBOARD CAT HERE>"
        cookie:
          path: '/'
          maxAge: 1000*60*30 # 30mins
      #  store: new class SQLStore extends express.session.Store
      #    get: (session_id, cb) ->
      #      app.model('session').select('data').where(session_id: session_id).first (err, session) ->
      #        return cb err if err
      #        cb null, if session then JSON.parse session.data else undefined
      #    set: (session_id, data, cb) ->
      #      session = app.model('session')
      #      session.select('id').where(session_id: session_id).first (err, result) ->
      #        return cb err if err
      #        session.id = result.id if result
      #        session.session_id = session_id
      #        session.data = JSON.stringify data
      next()

# user authentication
flow.serial (next) ->
  passport = require 'passport'
  passport.serializeUser (user, done) -> done null, user.id
  passport.deserializeUser (id, done) -> app.model('user').find id, done
  LocalStrategy = require('passport-local').Strategy
  passport.use new LocalStrategy usernameField: 'auth_key', passwordField: 'password', (auth_key, password, done) ->
    app.model('user').select('id', 'email', 'password_digest').where(email: auth_key).first (err, user) ->
      return done err if err
          session.save (err) ->
            return cb err if err
            cb null
      return done null, false, message: 'Incorrect username.' if not user
      return done null, false, message: 'Incorrect password.' if not user.valid_password password
      return done null, user
  app.passport = passport
  app.use passport.initialize()
  app.use passport.session()
  app.require_auth = (req, res, next) ->
    return next() if req.isAuthenticated()
    res.redirect "/"
  app.use require('connect-flash')()
  app.use (req, res, next) ->
    #res.locals._csrf = req.session._csrf
    res.locals.flash =
      alert: req.flash 'error'
      notice: req.flash 'notice'
    res.locals.current_user = res.current_user = req.user
    next()

  next()

# template engine
require_fresh=(a)->delete require.cache[require.resolve a];require a
app.locals require_fresh app.SHARED_HELPERS+'templates'
app.response.render = (name, options={}) ->
  options.view = 'views/'+name
  options.layout = 'views/'+app.SERVER_LAYOUTS+(options.layout or 'application')
  require('fs').readFile app.SERVER_VIEWS+'templates.js', 'utf8', (err, js) ->
    return process.stderr.write err.stack if err
    eval js # returns templates() function
    options.locals = options.locals or {}
    options.locals.layout = options.layout
    for k of app.response.locals
      options.locals[k] = app.response.locals[k]
    #console.log "rendering #{options.view} with locals", options.locals
    out = templates options.view, options.locals
    app.response.send out

# controllers
flow.serial -> fetch app.SERVER_CONTROLLERS+'application', app, @
flow.serial -> fetch app.SERVER_CONTROLLERS+'users', app, @
flow.serial -> fetch app.SHARED_CONTROLLERS+'application', app, @
flow.serial -> fetch app.SHARED_CONTROLLERS+'users', app, @

module.exports = (cb) -> app.BOOTSTRAP = cb
app.bootstrap()
