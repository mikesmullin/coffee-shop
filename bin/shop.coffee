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

  mkdir = (dir) ->
    fs.mkdirSync target+'/'+dir
    console.log "      #{cli.bold}#{cli.green}create#{cli.reset}  #{name}/#{dir}"

  write = (file, contents) ->
    fs.writeFileSync target+'/'+file, contents
    console.log "      #{cli.bold}#{cli.green}create#{cli.reset}  #{name}/#{file}"

  mkdir '' # target dir
  walk skeleton, (file, dir) ->
    if dir
      mkdir dir.substr skeleton.length+1
    else if file
      infile = file
      file = file.substr skeleton.length+1
      write file, fs.readFileSync infile, 'utf8'

  write 'package.json', JSON.stringify
    name: name
    version: '0.0.1'
    description: ''
    main: 'server.js'
    dependencies:
      express: '>=3.0.4'
    devDependencies:
      'coffee-script': '>=1.4.0'
      'mocha': '>=0.0.1'
      'gaze': '>=0.3.0'
      'growl': '>=1.6.1'
      'mkdirp': '>=0.3.4'
    scripts:
      test: 'echo "Error: no test specified" && exit 1'
      start: 'node server.js'
    repository: ''
    author: ''
    license: ''

  child_process = require 'child_process'
  shell = (cmd, cb) ->
    child_process.exec cmd, (err, stdout, stderr) ->
      if err then console.log err
      if stderr then console.log stderr
      if stdout then console.log stdout
      cb() if not err and typeof cb is 'function'

  shell "cd #{target} && npm install", ->
    console.log "done! next steps:\n\ncd #{name}\ncake start\ngoogle-chrome http://localhost:3000/"

cmd = process.argv[2] or 'help'
args = process.argv.slice(3)
if not _tasks[cmd]?
  console.log "task \"#{cmd}\" not found. try:\n  shop help"
  process.exit 1
else if args.length isnt _tasks[cmd].callback.length
  console.log "task \"#{cmd}\" requires #{_tasks[cmd].callback.length} argument(s)."
  process.exit 1
_tasks[cmd].callback.apply null, args
