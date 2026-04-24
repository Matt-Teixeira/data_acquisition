const { runHhmJob } = require("../_shared");
const { philipsCt } = require("../_configs");

module.exports = async (run_log, capture_datetime) =>
  runHhmJob(run_log, capture_datetime, philipsCt);
