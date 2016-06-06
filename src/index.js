if (process.env.NODE_ENV !== 'production') {
  // In development mode, use Webpack's CSS loader instead of a raw stylesheet:
  document.head.removeChild(document.head.querySelector('link[href="src/style.css"]'));
  require('./style.css');
}

var Elm = require('./Main');
Elm.Main.embed(document.getElementById('app'));
