const { runHhmJob } = require("../_shared");
const { geMri } = require("../_configs");

module.exports = async (run_log, capture_datetime) =>
  runHhmJob(run_log, capture_datetime, geMri);
