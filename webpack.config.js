const path = require('path');
const webpack = require('webpack');

module.exports = {
  entry: [
    './index',
  ],
  output: {
    path: path.join(__dirname, 'dist'),
    publicPath: "dist/",
    filename: 'bundle.js',
  },
  plugins: [
    new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),
  ],
  module: {
    loaders: [
      {
        test: /\.js$/,
        loaders: ['babel'],
        exclude: /node_modules/,
        include: __dirname
      }
    ]
  }
}
