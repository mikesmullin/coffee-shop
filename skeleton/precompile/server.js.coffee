process.env.ROOT = __dirname + '/static/'
process.env.development = true
process.env.PORT = 3001
sugar = require 'sugar'
express = require 'express'
app = express()

app.engine 'html', (path, options, cb) -> fs.readFile path, 'utf8', (err, str) -> cb err, str

app.use (req, res, done) ->
  console.log "#{req.method} \"#{req.url}\" for #{req.ip} at #{Date.create().iso()}"
  done()

app.use express.static process.env.ROOT + 'public/'

require(process.env.ROOT + 'app/controllers/application') app

app.listen process.env.PORT

console.log "listening on http://localhost:#{process.env.PORT}/"
