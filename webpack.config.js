const path = require('path');
const webpack = require('webpack');

const config = {
  entry: path.join(__dirname, 'src/index.js'),

  output: {
    path: path.resolve(__dirname, 'dist/'),
    publicPath: 'dist/',
    filename: 'bundle.js'
  },

  resolve: {
    moduleDirectories: ['node_modules'],
    extensions: ['', '.js', '.elm']
  },

  module: {
    loaders: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-hot!elm-webpack?warn=true'
      },
      {
        test: /\.css$/,
        loader: 'style-loader!css-loader?-url'
      }
    ]
  },
}

module.exports = config;
