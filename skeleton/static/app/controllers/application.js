module.exports = function(app) {
  return app.get('/', function(req, res) {
    return res.send('Welcome to CoffeeShop!');
  });
};
