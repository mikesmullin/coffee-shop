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
  write '.gitignore', '''
  node_modules/
  npm-debug.log
  static/db/*.sqlite*
  static/public/assets/templates.js
  static/app/views/templates.js
  '''

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
  process.on 'SIGINT', ->
    console.log "\n\n*** Restarting ***\n"
  process.on 'SIGQUIT', ->
    console.log "\n\n*** Killing ***\n"
    process.exit 0

db_file = path.join 'static', 'db', process.env.NODE_ENV+'.sqlite'

task 'console', 'opens application environment in a CoffeeScript REPL', ->
  require(path.join(process.cwd(), 'server.js')) (app) ->
    global.app = app
    process.stdout.write "coffee> CoffeeShop ready.\ncoffee> "
    require 'coffee-script/lib/coffee-script/repl'

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

task 'db', 'opens application database in cli', ->
  child_process.spawn 'cake', ['db'], env: process.env, stdio: 'inherit'

task 'db:drop', 'drop database of current NODE_ENV', ->
  child_process.spawn 'cake', ['db:drop'], env: process.env, stdio: 'inherit'

task 'db:create', 'create database of current NODE_ENV', ->
  child_process.spawn 'cake', ['db:create'], env: process.env, stdio: 'inherit'

task 'db:seed', 'reimport the database', ->
  child_process.spawn 'cake', ['db:seed'], env: process.env, stdio: 'inherit'

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
