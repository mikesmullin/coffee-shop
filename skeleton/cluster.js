var cluster, i, numCPUs, _i;

cluster = require('cluster');

numCPUs = require('os').cpus().length;

if (cluster.isMaster) {
  for (i = _i = 0; 0 <= numCPUs ? _i < numCPUs : _i > numCPUs; i = 0 <= numCPUs ? ++_i : --_i) {
    cluster.fork();
  }
  cluster.on('exit', function(worker, code, signal) {
    if (signal) {
      return console.log("worker was killed by signal: " + signal);
    } else if (code !== 0) {
      return console.log("worker exited with error code: " + code);
    } else {
      return console.log("worker exited normally");
    }
  });
} else {
  require('./server.js')(function(app) {});
}
