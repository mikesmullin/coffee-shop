'use strict'

child_process = require 'child_process'
fs = require 'fs'
path = require 'path'
process.env.NODE_ENV = process.env.NODE_ENV or 'development'

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
    fs.writeFileSync target+'/'+file, contents, 'binary'
    console.log "      #{cli.bold}#{cli.green}create#{cli.reset}  #{name}/#{file}"

  mkdir '' # target dir
  walk skeleton, (file, dir) ->
    if dir
      mkdir dir.substr skeleton.length+1
    else if file
      infile = file
      file = file.substr skeleton.length+1
      write file, fs.readFileSync infile, 'binary'

  pack =
    name: name
    version: '0.0.1'
    description: ''
    main: 'server.js'
    dependencies:
      'express': '*'
      'connect-flash': '*'
      'sugar': '*'
      'coffee-shop': 'https://github.com/mikesmullin/coffee-shop/tarball/stable'
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

  child = child_process.spawn 'npm', ['install', '--force'], env: process.env, cwd: target, stdio: 'inherit'
  child.on 'exit', (code) -> if code is 0
    console.log "\nCoffeeShop skeleton copy completed successfully!\nnow try:\n\n  cd #{name}\n  shop open\n"

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

bootstrap = (cb) ->
  process.env.BOOTSTRAP = true
  global.app = require(path.join(process.cwd(), 'server.js'))(cb)
db_file = path.join 'static', 'db', process.env.NODE_ENV+'.sqlite'

task 'console', 'opens application environment in a CoffeeScript REPL', ->
  bootstrap -> process.stdout.write "coffee> CoffeeShop ready.\ncoffee> "
  require 'coffee-script/lib/coffee-script/repl'

task 'db', 'opens application database in sqlite3 cli', ->
  console.log "REMEMBER: CTRL+D to exit"
  child_process.spawn 'sqlite3', [db_file], stdio: 'inherit'

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

task 'db:drop', 'drop database of current NODE_ENV', ->
  if fs.existsSync db_file
    fs.unlinkSync db_file
    console.log "deleted database #{db_file}."
  else
    console.log "database #{db_file} doesn't exist!"
    process.exit 1

#task 'db:create', 'create database of current NODE_ENV', ->
#  if fs.existsSync db_file
#    console.log "database #{db_file} already exists!"
#    process.exit 1
#  else
#    fs.writeFile db_file, ''
#    console.log "wrote empty database #{db_file}."

task 'db:seed', 'reimport the database', ->
  child = child_process.spawn 'node', [path.join 'static', 'db', 'seeds.js'], stdio: 'inherit'

cmd = process.argv[2] or 'help'
args = process.argv.slice(3)
if not _tasks[cmd]?
  console.log "task \"#{cmd}\" not found. try:\n  shop help"
  process.exit 1
else if args.length isnt _tasks[cmd].callback.length
  console.log "task \"#{cmd}\" requires #{_tasks[cmd].callback.length} argument(s)."
  process.exit 1
_tasks[cmd].callback.apply null, args
