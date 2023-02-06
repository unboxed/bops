const path = require("path")
const webpack = require("webpack")

const mode =
  process.env.NODE_ENV === "development" ? "development" : "production"

module.exports = {
  mode,
  entry: {
    application: "./app/javascript/application.js",
    govuk: "./app/javascript/govuk.js",
  },
  optimization: {
    moduleIds: "deterministic",
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    path: path.resolve(__dirname, "..", "..", "app/assets/builds"),
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1,
    }),
  ],
}
