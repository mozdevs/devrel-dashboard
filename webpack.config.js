const path = require('path');

module.exports = {
  devtool: '#cheap-module-eval-source-map',
  entry: [
    './index',
  ],
  output: {
    path: path.join(__dirname, 'dist'),
    publicPath: "./dist/",
    filename: 'bundle.js',
  },
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
