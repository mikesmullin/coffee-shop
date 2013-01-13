# like Express.js + Spine.js + Joosy, with a few twists
# API for the server
module.exports = CoffeeShopServer = ->
  global.exports = (file, o) -> o # companion placeholder for client-side modules

  process.on 'uncaughtException', (err) ->
    if err.code is 'EADDRINUSE'
      process.stderr.write "FATAL: port is already open. kill all node processes and try again."
      process.exit 1

  connect = require 'connect'
  app     = connect()
  path    = require 'path'
  async   = require 'async2'
  routes  = {}

  # define path global constants
  app.ENV = process.env.NODE_ENV = process.env.NODE_ENV or 'development'
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
  app.SERVER_VIEWS = path.join app.APP, 'views', path.sep
  app.SERVER_LAYOUTS = path.join app.VIEWS, 'layouts', path.sep

  # define HTTP VERB methods
  for k, method of methods = ['GET','POST','PUT','DELETE']
    ((method)=>
      app[method.toLowerCase()] = (uri, middlewares..., cb) =>
        # remember route by 'as' alias
        options = {}
        for k of middlewares when typeof middlewares[k] is 'object'
          options = middlewares[k]
          continue
        if uri is '/'
          routes['root'] = '/'
        else if options.as
          routes[options.as] = uri # user-specified overrides all
        else
          options.as = uri.replace(`/[^a-zA-Z+_-]+/g`, '_').replace(`/(^_|_$)/g`,'') # auto-generate
          routes[options.as] = routes[options.as] or uri # defer to user-specified

        app.use (req, res, next) =>
          return next() unless req.method is method and
            (params=req.url.match(new RegExp "^#{uri}$")) isnt null

          # I/O request and response helpers
          req.params = params.slice 1
          app.response.send = res.send = res.end

          # route middleware
          flow = async.flow req, res
          for k of middlewares when typeof middlewares[k] is 'function'
            ((middleware)->
              flow.serial (req, res, next) ->
                middlewares[k] req, res, (err, warning) ->
                  if err is false # false breaks middleware chain without throwing error
                    res.end warning # optional human-friendly error sent to browser
                  else
                    next err, req, res
            )(middlewares[k])
          flow.go (err, req, res) ->
            return next err if err # errors pass through to connect
            cb req, res # callback is executed
    )(method)

  # general request and response helpers
  app.request = {}
  app.response = { locals: {} }
  app.use (req, res, next) ->
    res.locals = {}
    res.navigate = (uri) -> res.redirect uri
    res.url = join: (parts...) -> parts.join '/'
    res.render = (file, options) -> res.send "would render view template \"#{file}\" with options: #{JSON.stringify options, null, 2}"
    res.activate = (file, options) -> res.send "would activate widget \"#{file}\" with options: #{JSON.stringify options, null, 2}"
    for k of app.request
      req[k] = app.request[k]
    for k of app.response
      res[k] = app.response[k]
    next()
  app.locals = (o) ->
    for k of o
      app.response.locals[k] = app.response.locals[k] or o[k]

  if process.env.NODE_ENV is 'development'
    app.get '/shop/routes', (req, res) ->
      res.send JSON.stringify routes, null, 2

  flow = new async
  app.bootstrap = ->
    flow.go ->
      # a callback can be provided when bootstrapping,
      # in which case we stop short of opening socket
      if typeof app.BOOTSTRAP is 'function'
        process.nextTick ->
          app.BOOTSTRAP app # indicate readiness
      else # open socket
        server = app.listen app.PORT, ->
          console.log "worker #{process.pid} listening on http://localhost:#{app.PORT}/"

        # report exception leaks
        process.on 'uncaughtException', (err) ->
          process.stderr.write "\nWARNING: handle your exceptions better: \n\n"+err.stack+"\n\n"
          server.close() if server
          process.exit 1

  return {
    app: app
    connect: connect
    flow: flow
  }

