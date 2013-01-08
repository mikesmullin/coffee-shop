cluster = require 'cluster'
numCPUs = require('os').cpus().length

if cluster.isMaster
  for i in [0...numCPUs]
    cluster.fork()
  cluster.on 'exit', (worker, code, signal) ->
    if signal
      console.log "worker was killed by signal: "+signal
    else if code isnt 0
      console.log "worker exited with error code: "+code
    else
      console.log "worker exited normally"
else
  require('./server.js') (app) ->
