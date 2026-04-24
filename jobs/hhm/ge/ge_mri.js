const runHhmJob = require("../_shared");
const { get_hhm, getHhmCreds } = require("../../../sql/qf-provider");
const { decrypt_string } = require("../../../util/encrypt/decrypt");

const get_ge_mri_data = async (run_log, capture_datetime) =>
  runHhmJob(run_log, capture_datetime, {
    jobName: "ge_mri",
    logLabel: "get_ge_mri_data",
    manufacturer: "GE",
    modality: "MRI",
    shellSubdir: "GE",
    fetchSystems: get_hhm,
    fetchCredentials: getHhmCreds,
    argsBuilder: (system, creds) => [
      system.host_ip,
      decrypt_string(creds.user_enc),
      decrypt_string(creds.password_enc),
    ],
  });

module.exports = get_ge_mri_data;
