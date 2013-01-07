module.exports =
  cdn_url: (path, cb) ->
    cb ''+path

  # globals used in the layout; cannot be undefined
  current_user: {}
  flash: notice: [], alert: []
  body_class: ''
