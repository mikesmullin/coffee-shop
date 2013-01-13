# like Express.js + Spine.js + Joosy, with a few twists
# mirror API for the browser
@app = new class CoffeeShopClient
  bootstrap: (env, options) ->
    @ENV = env or 'production'
    options = options or {}
    @debug = options.debug or @ENV isnt 'production'
    @trace = options.trace or false
    @started = new Date()
    @log 'app ready.'

  log: (o) ->
    if @debug and console
      current = new Date()
      console.log if typeof o is 'string'
          "[#{(current - @started) / 1000}s] #{o}"
        else
          o
      if @trace
        console.trace()

# require() emulation for pre-aggregated js
@__exported__ = {}
@module = {}
@require = (file) => @__exported__[file]
@global = exports: (file, o) => @__exported__[file] = o
