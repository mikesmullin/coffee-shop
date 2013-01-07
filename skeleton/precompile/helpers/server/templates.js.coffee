path = require 'path'

module.exports =
  _asset: (tag, attrs, file_attr, basename) ->
    set_file = (file) => attrs[file_attr] = @block "cdn_url #{JSON.stringify file}"
    out = (file) -> set_file path.normalize '/assets/'+file; tag attrs
    if process.env.ENV is 'production' then out basename
    else
      require_fresh=(a)->delete require.cache[require.resolve a];require a
      files = require_fresh(process.cwd()+'/static/public/assets/manifest.json')[basename]
      if typeof files is 'object' and files.length >= 1
        for i, file of files
          out file
      else
        out basename
  stylesheet: (file, o) ->
    o = o or {}
    o.rel = 'stylesheet'
    @_asset @link, o, 'href', file+'.css'
  javascript: (file, o) ->
    @_asset @script, o or {}, 'src', file+'.js'
