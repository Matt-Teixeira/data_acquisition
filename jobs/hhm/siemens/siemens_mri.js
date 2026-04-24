const runHhmJob = require("../_shared");
const { get_hhm } = require("../../../sql/qf-provider");

const get_siemens_mri_data = async (run_log, capture_datetime) =>
  runHhmJob(run_log, capture_datetime, {
    jobName: "siemens_mri",
    logLabel: "get_siemens_mri_data",
    manufacturer: "Siemens",
    modality: "MRI",
    shellSubdir: "Siemens",
    fetchSystems: get_hhm,
    argsBuilder: (system) => [system.host_ip],
  });

module.exports = get_siemens_mri_data;
