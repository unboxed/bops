process.env.NODE_ENV = process.env.NODE_ENV || "production"

const environment = require("./environment")

var config = environment.toWebpackConfig()
config.devtool = "nosources-source-map"

module.exports = config
