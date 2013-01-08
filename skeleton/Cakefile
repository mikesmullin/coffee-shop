async           = require 'async2'
fs              = require 'fs'
CoffeeAssets    = require 'coffee-assets'
path            = CoffeeAssets.path # provides .xplat
require_fresh   = CoffeeAssets.require_fresh # bypasses cache
asset           = new CoffeeAssets asset_path: asset_path = 'static/public/assets'
child_process   = require 'child_process'
child_processes = {}

task 'open', 'start main process loop', ->
  asset.watch 'gaze', 'Cakefile', (o) ->
    asset.notify o.title, 'Cakefile changed. restart...', 'pending', false, true
    child_processes.node.on 'exit', ->
      process.exit 0
    child_processes.node.kill 'SIGTERM'

  asset.watch 'coffeescripts', [
      in: 'precompile'
      suffix: '/*.js.coffee'
      out: ''
    ,
      in: 'precompile/db'
      suffix: '/seeds.js.coffee'
      out: 'static/db'
    ,
      in: 'precompile/config'
      out: 'static/config'
    ,
      in: 'precompile/controllers/server'
      out: 'static/app/controllers'
    ,
      in: 'precompile/controllers/shared'
      out: "#{asset_path}/controllers"
    ,
      in: 'precompile/models/server'
      out: 'static/app/models'
    ,
      in: 'precompile/models/shared'
      out: "#{asset_path}/models"
    ,
      in: 'precompile/helpers/server'
      out: 'static/app/helpers'
    ,
      in: 'precompile/helpers/shared'
      out: "#{asset_path}/helpers"
    ,
      in: 'precompile/assets/behaviors'
      out: asset_path
  # filenames with underscore prefix are only compiled via #= require directive
  ], '/**/!(@(_))*.{js,js.coffee}', asset.common_compiler()

  asset.watch 'coffeestylesheets', [
    in: 'precompile/assets/stylesheets'
    out: asset_path
  # filenames with underscore prefix are only compiled via #= require directive
  ], '/**/!(@(_))*.{css,css.coffee}', (o) -> asset.common_compiler(
    render_options:
      format: true
      globals: require_fresh path.xplat __dirname, 'static/app/helpers/stylesheets'
    sprite_options:
      image_path: path.xplat 'precompile/assets/sprites'
      sprite_path: path.xplat asset_path
      sprite_url: '/assets/' # TODO: include cdn_url or use relative here?
      #pngcrush: 'pngcrush' # should probably only be run for production
      logger: (i,m) -> asset.notify o.title, m, i or 'success', i is 'failure', true
  )(o)

  asset.watch 'coffeetemplates', [
      in: 'precompile/views/server'
      out: 'static/app/views'
    ,
      in: 'precompile/views/shared'
      out: asset_path
  ], '/**/*.html.coffee', (o) ->
    # if ANY template file changes, ALL must be recompiled
    # because they are aggregated into a single templates.js file and function()
    o.outfile = path.join o.outpath, 'templates.js'
    asset.precompile_all o.inpath, {
      render_options:
        format: true
        globals: require_fresh path.xplat __dirname, 'static/app/helpers/templates'
    }, asset.write_manager o

  asset.watch 'javascript', [
      in: 'static/app/**'
    ,
      in: ''
  ], '/*.js', (o) ->
    asset.notify 'gaze', "#{o.infile} changed. restarting node...", 'pending', false, true
    child_processes.node.kill 'SIGTERM'

  asset.watch 'coffeejson', [
    in: 'precompile/config'
    out: 'static/config'
  ,
    in: 'precompile/assets'
    out: asset_path
  ], '/**/*.json.coffee', asset.common_compiler()

  #asset.child_process_loop child_processes, 'node-inspector', 'node-inspector'
  asset.child_process_loop child_processes, 'node', 'node', ['server.js']
  process.on 'uncaughtException', (err) ->
    process.stderr.write "\nWARNING: handle your exceptions better: \n\n"+err.stack+"\n\n"
    process.exit 1

db_config = require(path.xplat process.cwd(), 'static/config/database.json')[process.env.NODE_ENV]

task 'db', 'opens application database in cli', ->
  console.log "REMEMBER: CTRL+D to exit"
  child_process.spawn 'sqlite3', [db_file], env: process.env, stdio: 'inherit'

task 'db:drop', 'drop database of current NODE_ENV', ->
  if fs.existsSync db_file
    fs.unlinkSync db_file
    console.log "deleted database #{db_file}."
  else
    console.log "database #{db_file} doesn't exist!"
    process.exit 1

task 'db:create', 'create database of current NODE_ENV', ->
  if fs.existsSync db_file
    console.log "database #{db_file} already exists!"
    process.exit 1
  else
    fs.writeFile db_file, ''
    console.log "wrote empty database #{db_file}."

task 'db:seed', 'reimport the database', ->
  require(path.xplat process.cwd(), 'server.js') (app) ->
    require(path.xplat process.cwd(), 'static/db/seeds.js')(app)
