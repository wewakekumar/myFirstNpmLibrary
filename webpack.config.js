const HTMLWebpackPlugin = require("html-webpack-plugin");

module.exports = () => {
  return {
    entry: "./index.jsx",
    mode: "development",
    resolve: { extensions: [".jsx", ".js"] },
    module: {
      rules: [
        {
          test: "/.css$/",
          exclude: /node_modules/,
          use: ["style-loader", "css-loader"],
        },
        {
          test: /\.?jsx?$/,
          exclude: /node_modules/,
          use: {
            loader: "babel-loader",
            options: {
              presets: ["@babel/preset-env", ["@babel/preset-react", {"runtime": "automatic"}]],
            },
          },
        },
      ],
    },
    plugins: [new HTMLWebpackPlugin({ template: "./public/index.html" })],
  };
};
