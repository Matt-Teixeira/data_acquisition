const { runHhmJob } = require("../_shared");
const { siemensCt } = require("../_configs");

module.exports = async (run_log, capture_datetime) =>
  runHhmJob(run_log, capture_datetime, siemensCt);
