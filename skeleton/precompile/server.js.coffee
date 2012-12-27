process.env.ROOT = __dirname + '/static/'
process.env.development = true
process.env.PORT = 3001
sugar = require 'sugar'
fs = require 'fs'
express = require 'express'
app = express()

# CoffeeTemplates.__express
app.response._render = app.response.render
app.response.render = (name, options, cb) ->
  options = options or {}
  options.view = name
  options.layout =
    if options.layout
      'shared/layouts/'+options.layout
    else
      'shared/layouts/application'
  app_helper = require process.env.ROOT+'app/helpers/application'
  for k of app_helper
    ((f)->
      options[k] = ->
        cb = arguments[arguments.length-1]
        cb f.apply null, arguments
    )(app_helper[k])
  if name.indexOf('server/') is 0
    name = 'app/views/templates'
  else # shared
    name = 'public/assets/templates'
  @_render name, options, cb
app.set 'view engine', 'js'
app.set 'views', process.env.ROOT
app.engine 'js', (path, options, cb) ->
  render = (str) ->
    eval 'templates='+str
    cb null, templates options.view, options
  fs.readFile path, 'utf8', (err, templates) ->
    if path.indexOf('static/app/views/templates.js') isnt -1 # server-only template requested
      # splice-in shared templates; this extra cpu avoids double-tree stored on disk
      fs.readFile process.env.ROOT+'public/assets/templates.js', 'utf8', (err, shared_templates) ->
        templates = templates.split("\n")
        templates.splice -2, 0, shared_templates.split("\n").slice(2,-2).join("\n")
        render templates.join("\n")
    else
      render templates

# http request logger
app.use (req, res, done) ->
  console.log "#{req.method} \"#{req.url}\" for #{req.ip} at #{Date.create().iso()}"
  done()

# static file server
app.use express.static process.env.ROOT + 'public/'

# controllers
require(process.env.ROOT + 'app/controllers/application') app

# start server
app.listen process.env.PORT
console.log "listening on http://localhost:#{process.env.PORT}/"
