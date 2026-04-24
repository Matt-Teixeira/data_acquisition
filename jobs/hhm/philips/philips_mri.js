const runHhmJob = require("../_shared");
const { get_phil_mri_host, getHhmCreds } = require("../../../sql/qf-provider");
const { decrypt_string } = require("../../../util/encrypt/decrypt");

// Philips MRI transfers can legitimately run longer than the default 90s
// shell timeout; pass as the 9th positional arg to exec_hhm_data_grab.
const PHILIPS_MRI_SHELL_TIMEOUT_S =
  Number(process.env.PHILIPS_MRI_SHELL_TIMEOUT_S) || 300;

const get_philips_mri_data = async (run_log, capture_datetime) =>
  runHhmJob(run_log, capture_datetime, {
    jobName: "philips_mri",
    logLabel: "get_philips_mri_data",
    manufacturer: "Philips",
    modality: "MRI",
    shellSubdir: "Philips",
    fetchSystems: get_phil_mri_host,
    fetchCredentials: getHhmCreds,
    argsBuilder: (system, creds) => [
      system.host_ip,
      decrypt_string(creds.user_enc),
      decrypt_string(creds.password_enc),
    ],
    extraExecArgs: [PHILIPS_MRI_SHELL_TIMEOUT_S],
  });

module.exports = get_philips_mri_data;
