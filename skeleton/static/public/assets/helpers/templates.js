
module.exports = {
  cdn_url: function(path, cb) {
    return cb('' + path);
  },
  current_user: {},
  flash: {
    notice: [],
    alert: []
  },
  body_class: ''
};
