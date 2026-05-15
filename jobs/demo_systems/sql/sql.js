const { QueryFile } = require("pg-promise");
const { join: joinPath } = require("path");

const sql = (file) => {
  const fullPath = joinPath(__dirname, file);
  return new QueryFile(fullPath, { minify: true });
};

module.exports = {
  demo_mag: sql("get-demo-mag.sql"),
  demo_edu: sql("get-demo-edu.sql"),
  demo_phil_mri: sql("get-demo-phil-mri.sql"),
};
