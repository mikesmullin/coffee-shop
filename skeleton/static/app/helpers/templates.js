var path;

path = require('path');

module.exports = {
  _asset: function(tag, attrs, file_attr, basename) {
    var file, files, i, out, require_fresh, set_file, _results,
      _this = this;
    set_file = function(file) {
      return attrs[file_attr] = _this.block("cdn_url " + (JSON.stringify(file)));
    };
    out = function(file) {
      set_file(path.normalize('/assets/' + file));
      return tag(attrs);
    };
    if (process.env.ENV === 'production') {
      return out(basename);
    } else {
      require_fresh = function(a) {
        delete require.cache[require.resolve(a)];
        return require(a);
      };
      files = require_fresh(process.cwd() + '/static/public/assets/manifest.json')[basename];
      if (typeof files === 'object' && files.length >= 1) {
        _results = [];
        for (i in files) {
          file = files[i];
          _results.push(out(file));
        }
        return _results;
      } else {
        return out(basename);
      }
    }
  },
  stylesheet: function(file, o) {
    o = o || {};
    o.rel = 'stylesheet';
    return this._asset(this.link, o, 'href', file + '.css');
  },
  javascript: function(file, o) {
    return this._asset(this.script, o || {}, 'src', file + '.js');
  }
};
