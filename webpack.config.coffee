path = require 'path'
BrowserSyncPlugin = require 'browser-sync-webpack-plugin'
{IgnorePlugin, DefinePlugin} = require 'webpack'
webRoot = path.resolve '../Products/webroot'
UglifyJsPlugin = require('uglifyjs-webpack-plugin')

browserSync = new BrowserSyncPlugin {
  port: 3000
  host: 'localhost'
  server: { baseDir: [ webRoot ] }
}

define = new DefinePlugin {
  'process.env.NODE_ENV': JSON.stringify('production')
}

uglify = new UglifyJsPlugin()

plugins = [browserSync, define, uglify]
ignores = [/^pg-promise/,/^electron/,/^pg/,/^fs/]


for i in ignores
  plugins.push new IgnorePlugin(i)

babelLoader = {
  loader: 'babel-loader'
  options: {
    presets: ['es2015','react']
    sourceMap: false
  }
}

exclude = /node_modules/

coffeeLoader = {
  loader: 'coffee-loader'
  options: {sourceMap: false}
}

module.exports = {
  module:
    rules: [
      {test: /\.coffee$/, use: [babelLoader, coffeeLoader], exclude}
      {test: /\.(js|jsx)$/, use: [babelLoader], exclude}
      {test: /\.styl$/, use: ["style-loader","css-loader", "stylus-loader"]}
      {test: /\.css$/, use: ["style-loader", "css-loader"]}
      {
        test: /\.(eot|svg|ttf|woff|woff2)$/,
        use: [
          {
            loader: 'file-loader',
            options: {}
          }
        ]
      }
      {
        test: /\.(png|svg)$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              name: '[name].[ext]'
            }
          }
        ]
      }

    ]
  resolve:
    extensions: [".coffee", ".js"]
  entry: "./app/web-index.coffee"
  output:
    path: path.join webRoot, "assets"
    publicPath: "/assets/"
    filename: "app.js"
  plugins
}
