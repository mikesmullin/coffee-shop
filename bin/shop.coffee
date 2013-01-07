'use strict'

child_process = require 'child_process'
path = require 'path'

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

  pack =
    name: name
    version: '0.0.1'
    description: ''
    main: 'server.js'
    dependencies:
      'express': '*'
      'coffee-shop': 'https://github.com/mikesmullin/coffee-shop/tarball/stable'
      'sugar': '*'
      'async2': 'https://github.com/mikesmullin/async2/tarball/stable'
      'node-sqlite-purejs': 'https://github.com/mikesmullin/node-sqlite-purejs/tarball/stable'
    devDependencies:
      'coffee-script': '*'
      'mocha': '*'
      'coffee-assets': 'https://github.com/mikesmullin/coffee-assets/tarball/stable'
      'coffee-templates': 'https://github.com/mikesmullin/coffee-templates/tarball/stable'
      'coffee-stylesheets': 'https://github.com/mikesmullin/coffee-stylesheets/tarball/stable'
      'coffee-sprites': 'https://github.com/mikesmullin/coffee-sprites/tarball/stable'
      'coffee-stylesheets-compass-framework': 'https://github.com/mikesmullin/coffee-stylesheets-compass-framework/tarball/stable'
    scripts:
      test: 'echo "Error: no test specified" && exit 1'
      start: 'node server.js'
    repository: ''
    author: ''
    license: ''
  write 'package.json', JSON.stringify pack, null, 2
  write 'README.md', "# #{name}"

  shell = (cmd, cb) ->
    child_process.exec cmd, (err, stdout, stderr) ->
      if err then console.log err
      if stderr then console.log stderr
      if stdout then console.log stdout
      cb() if not err and typeof cb is 'function'

  shell "cd #{target} && npm install", ->
    console.log "done! next steps:\n\ncd #{name}\nshop open"

task 'open', 'starts the main event loop', ->
  console.log "REMEMBER: CTRL+C to restart, CTRL+\\ to exit"
  child = `undefined`
  restart = ->
    child = child_process.spawn 'cake', ['open']
    child.stdout.on 'data', (stdout) ->
      process.stdout.write stdout
    child.stderr.on 'data', (stderr) ->
      process.stderr.write stderr
    child.on 'exit', (code) ->
      process.nextTick restart
  restart()
  # ignore these signals; forward to child only
  process.on 'SIGINT', ->
  process.on 'SIGQUIT', ->
    child.removeAllListeners 'exit'

task 'console', 'opens application environment in a CoffeeScript REPL', ->
  process.env.BOOTSTRAP = true
  global.app = require(path.join(process.cwd(), 'server.js'))(-> process.stdout.write "coffee> CoffeeShop ready.\ncoffee> ")
  require 'coffee-script/lib/coffee-script/repl'

task 'db', 'opens application database in sqlite3 cli', ->
  console.log "REMEMBER: CTRL+D to exit"
  child_process.spawn 'sqlite3', [path.join('static', 'db', 'development.sqlite')], stdio: 'inherit'

task 'update', 'updates coffee-shop, local git repo, and npm modules', ->
  console.log "\ngit pull"
  child = child_process.spawn 'git', ['pull'], stdio: 'inherit'
  child.on 'exit', (code) -> if code is 0
    console.log "\nnpm install coffee-shop -g"
    child = child_process.spawn 'npm', ['install', 'coffee-shop', '-g'], stdio: 'inherit'
    child.on 'exit', (code) -> if code is 0
      console.log "\nnpm install"
      child = child_process.spawn 'npm', ['install'], stdio: 'inherit'
      child.on 'exit', (code) -> if code is 0
        console.log "update completed successfully."

task 'version', 'output the current package version', ->
  console.log 'v'+require(path.join(__dirname,'..','package.json')).version

cmd = process.argv[2] or 'help'
args = process.argv.slice(3)
if not _tasks[cmd]?
  console.log "task \"#{cmd}\" not found. try:\n  shop help"
  process.exit 1
else if args.length isnt _tasks[cmd].callback.length
  console.log "task \"#{cmd}\" requires #{_tasks[cmd].callback.length} argument(s)."
  process.exit 1
_tasks[cmd].callback.apply null, args
