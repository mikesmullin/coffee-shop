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

task 'new', 'copy new empty application skeleton to given directory', (name) ->
  skeleton = __dirname+'/../skeleton'
  target = process.cwd()+'/'+name
  fs = require 'fs'
  path = require 'path'

  walk = (base, cb) ->
    items = fs.readdirSync base
    dirs = []
    for i, item of items
      abspath = base+'/'+item
      if fs.statSync(abspath).isDirectory()
        dirs.push abspath
        cb null, abspath
        walk abspath, cb
      else
        cb abspath
    dirs

  fs.mkdirSync target
  console.log "      #{cli.bold}#{cli.green}create#{cli.reset}  #{name}"
  walk skeleton, (file, dir) ->
    if dir
      dir = dir.substr skeleton.length+1
      fs.mkdirSync target+'/'+dir
      console.log "      #{cli.bold}#{cli.green}create#{cli.reset}  #{name}/#{dir}"
    else if file
      infile = file
      file = file.substr skeleton.length+1
      fs.writeFileSync target+'/'+file, fs.readFileSync infile, 'utf8'
      console.log "      #{cli.bold}#{cli.green}create#{cli.reset}  #{name}/#{file}"

cmd = process.argv[2] or 'help'
args = process.argv.slice(3)
if not _tasks[cmd]?
  console.log "task \"#{cmd}\" not found. try:\n  shop help"
  process.exit 1
else if args.length isnt _tasks[cmd].callback.length
  console.log "task \"#{cmd}\" requires #{_tasks[cmd].callback.length} argument(s)."
  process.exit 1
_tasks[cmd].callback.apply null, args
