'use strict'

cli =
  bold: '\u001b[1m'
  green: '\u001b[32m'
  reset: '\u001b[0m'

_tasks = {}
task=(name, description, callback)->
  _tasks[name] =
    name: name
    description: description
    callback: callback

task 'help', 'see this help information', ->
  console.log "Usage: shop [task] [arguments...]\n"
  console.log 'Available tasks:'
  for i, task of _tasks
    console.log "  #{task.name}: #{task.description}"
  console.log ''

task 'new', 'create new application skeleton', (root) ->
  fs = require 'fs'
  root = process.cwd()+'/'+root
  directories = [
    ''
    'precompile'
    'precompile/assets'
    'precompile/assets/behaviors'
    'precompile/assets/behaviors/test'
    'precompile/assets/images'
    'precompile/assets/stylesheets'
    'precompile/controllers'
    'precompile/controllers/server'
    'precompile/controllers/shared'
    'precompile/models'
    'precompile/models/server'
    'precompile/models/shared'
    'precompile/vendor'
    'precompile/vendor/assets'
    'precompile/vendor/assets/behaviors'
    'precompile/vendor/assets/stylesheets'
    'precompile/views'
    'precompile/views/server'
    'precompile/views/shared'
    'static'
    'static/app'
    'static/app/controllers'
    'static/app/models'
    'static/app/views'
    'static/db'
    'static/public'
    'static/public/assets'
    'static/public/uploads'
    'static/public/downloads'
    'static/public/fonts'
  ]
  for i, dir of directories
    fs.mkdirSync root+'/'+dir+'/'
    console.log "      #{cli.bold}#{cli.green}create#{cli.reset}  #{dir}"

  files = [
    'precompile/index.coffee'
    'precompile/server.coffee'
    'Cakefile'
    'loop'
    'README.md'
  ]
  for i, file of files
    fs.writeFileSync root+'/'+file, ''
    console.log "      #{cli.bold}#{cli.green}create#{cli.reset}  #{file}"

cmd = process.argv[2] or 'help'
args = process.argv.slice(3)
if not _tasks[cmd]?
  console.log "task \"#{cmd}\" not found. try:\n  shop help"
  process.exit 1
else if args.length isnt _tasks[cmd].callback.length
  console.log "task \"#{cmd}\" requires #{_tasks[cmd].callback.length} argument(s)."
  process.exit 1
_tasks[cmd].callback.apply null, args
