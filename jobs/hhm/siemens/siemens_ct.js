const runHhmJob = require("../_shared");
const { get_hhm } = require("../../../sql/qf-provider");

const get_siemens_ct_data = async (run_log, capture_datetime) =>
  runHhmJob(run_log, capture_datetime, {
    jobName: "siemens_ct",
    logLabel: "get_siemens_ct_data",
    manufacturer: "Siemens",
    modality: "%CT",
    shellSubdir: "Siemens",
    fetchSystems: get_hhm,
    argsBuilder: (system) => [system.host_ip],
  });

module.exports = get_siemens_ct_data;
