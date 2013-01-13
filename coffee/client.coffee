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
    $(window).hashchange =>
      @emit 'hashchange', document.location.hash.substr 2
    @on 'ready', =>
      @log 'app ready.'
      @emit 'hashchange', document.location.hash.substr(2) or '/'
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
  events: {}
  on: (event, cb) ->
    @events[event] = @events[event] or []
    @events[event].push cb
  emit: (event, args...) ->
    for k of @events[event]
      @events[event][k].apply null, args
  removeAllListeners: (event) ->
    delete @events[event]

  request:
    url: ''

  response:
    locals: {}
    navigate: (uri) -> document.location.href = '#!'+uri
    activate: (widget) ->
    send: end = (s) -> $('body').append s
    end: end
    render: (file, options) -> @send "would render view template \"#{file}\" with options: #{JSON.stringify options, null, 2}"
    activate: (file, options) ->
      @log "activating widget \"#{file}\" with options: #{JSON.stringify options, null, 2}"
      widget = require("widgets/#{file}")(app)
      e = $(widget.e).appendTo(options.within)
      scope = {}
      for k of widget.elements
        scope[k] = $(widget.elements[k], e)
      for k of widget.events
        $(e).bind(k, widget.events[k])
      return e

  get: (uri, middlewares..., cb) ->
    @on 'hashchange', (url) =>
      console.log "route! uri is #{uri} and url is #{url}"
      @request.url = url
      req = @request
      res = @response
      next = (err, args...) =>
        @log "Could not GET #{url}" # alert box may be more appropriate here
        @log err if err
        return
      return next() unless (params=req.url.match(new RegExp "^#{uri}$")) isnt null

      # I/O request and response helpers
      req.params = params.slice 1

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
