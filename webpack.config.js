const HTMLWebpackPlugin = require("html-webpack-plugin");

const MiniCSSExtractPlugin = require("mini-css-extract-plugin");

module.exports = () => {
  return {
    entry: "./index.tsx",
    mode: "development",
    resolve: { extensions: [".tsx", ".ts", ".jsx", ".js"] },
    module: {
      rules: [
        {
          test: /\.(sa|sc|c)ss$/,
          exclude: /node_modules/,
          use: [ MiniCSSExtractPlugin.loader, "css-loader", "sass-loader"],
        },
        {
          test: /\.[jt]sx?$/,
          exclude: /node_modules/,
          use: {
            loader: "esbuild-loader",
            options: {
              loader: "tsx",
              target: "es2015"
            },
          },
        },
      ],
    },
    plugins: [new HTMLWebpackPlugin({ template: "./public/index.html" }), new MiniCSSExtractPlugin()],
  };
};
