# like Express.js + Spine.js + Joosy, with a few twists
# mirror API for the browser
# NOTICE: include jQuery or similar before this lib
# NOTICE: include async2 before this lib
# NOTICE: include before this lib for legacy browser hashchange event support:
#         https://raw.github.com/cowboy/jquery-hashchange/v1.3/jquery.ba-hashchange.js
@app = new class CoffeeShopClient
  bootstrap: (env, options) ->
    @ENV = env or 'production'
    options = options or {}
    @debug = options.debug or @ENV isnt 'production'
    @trace = options.trace or false
    @started = new Date()
    @events = {}
    @on 'hashchange', (hash) ->
      console.log "sup! hash is now #{hash}"
    $(window).hashchange ->
      @emit 'hashchange', location.hash
    @on 'ready', =>
      @log 'app ready.'
      @emit 'hashchange', location.hash
    @emit 'ready'

  log: (o) ->
    if @debug and console
      current = new Date()
      console.log if typeof o is 'string'
          "[#{(current - @started) / 1000}s] #{o}"
        else
          o
      if @trace
        console.trace()

  # EventEmitter clone
  on: (event, cb) ->
    @events[event] = @events[event] or []
    @events[event].push cb
  emit: (event, args...) ->
    for k of @events[event]
      @events[event][k].apply null, args
  removeAllListeners: (event) ->
    delete @events[event]

  get: (uri, middlewares..., cb) ->
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

# require() emulation for pre-aggregated js
@__exported__ = {}
@module = {}
@require = (file) => @__exported__[file]
@global = exports: (file, o) => @__exported__[file] = o
