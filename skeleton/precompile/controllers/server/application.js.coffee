module.exports = (app) ->
  app.get '/', (req, res) ->
    res.render 'shared/pages/home'
