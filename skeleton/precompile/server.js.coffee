process.env.ROOT = __dirname + '/static/'
process.env.development = true
express = require 'express'
app = express()

app.engine 'html', (path, options, cb) -> fs.readFile path, 'utf8', (err, str) -> cb err, str

app.use express.static process.env.ROOT + 'public/'

require(process.env.ROOT + 'app/controllers/application') app

app.listen 3000
