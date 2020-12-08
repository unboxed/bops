const { environment } = require('@rails/webpacker')
const { merge } = require('webpack-merge')

const sassLoader = environment.loaders.get('sass')
const cssLoader = environment.loaders.get('css')

sassLoader.use.map(function(loader) {
  if (loader.options) {
    loader.options = merge(loader.options, { sourceMap: false })
  }
});

cssLoader.use.map(function(loader) {
  if (loader.options) {
    loader.options = merge(loader.options, { sourceMap: false })
  }
});

module.exports = environment
