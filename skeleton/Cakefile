async           = require 'async2'
fs              = require 'fs'
CoffeeAssets    = require 'coffee-assets'
path            = CoffeeAssets.path # provides .xplat
require_fresh   = CoffeeAssets.require_fresh # bypasses cache
asset           = new CoffeeAssets asset_path: asset_path = 'static/public/assets'
child_processes = {}
exit_gracefully = ->
  asset.safe_shutdown_child_processes child_processes, 'node', ->
    process.exit 0

task 'open', 'start main process loop', ->
  asset.watch 'gaze', 'Cakefile', (o) ->
    asset.notify o.title, 'Cakefile changed. restart...', 'pending', false, true
    exit_gracefully()

  asset.watch 'coffeescripts', [
      in: 'precompile'
      suffix: '/server.js.coffee'
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

  asset.watch 'javascript', 'static/app/**/*.js', (o) ->
    asset.notify 'gaze', "#{o.infile} changed. restarting node on next tick...", 'pending', false, true
    process.nextTick ->
      asset.restart_child_process child_processes.node

  asset.watch 'coffeejson', [
    in: 'precompile/config'
    out: 'static/config'
  ,
    in: 'precompile/assets'
    out: asset_path
  ], '/**/*.json.coffee', asset.common_compiler()

  child_processes.node_inspector = asset.child_process_loop 'node-inspector', 'node-inspector'
  child_processes.node = asset.child_process_loop 'node', 'node', ['server.js']
  process.on 'uncaughtException', (err) ->
    console.log err.stack
    exit_gracefully()
  asset.forward_interrupt() # use CTRL+\ to kill
