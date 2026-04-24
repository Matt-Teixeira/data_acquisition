const runHhmJob = require("../_shared");
const { get_hhm, getHhmCreds } = require("../../../sql/qf-provider");
const { decrypt_string } = require("../../../util/encrypt/decrypt");

const get_siemens_cv_data = async (run_log, capture_datetime) =>
  runHhmJob(run_log, capture_datetime, {
    jobName: "siemens_cv",
    logLabel: "get_siemens_cv_data",
    manufacturer: "Siemens",
    modality: "CV/IR",
    shellSubdir: "Siemens",
    fetchSystems: get_hhm,
    fetchCredentials: getHhmCreds,
    // Siemens CV has creds but uses the acquisition_script/host_ip guard
    // (matches original pre-refactor behavior — does NOT also gate on
    // credentials_group presence).
    hostPredicate: (sys) => Boolean(sys.acquisition_script && sys.host_ip),
    argsBuilder: (system, creds) => [
      system.host_ip,
      decrypt_string(creds.user_enc),
      decrypt_string(creds.password_enc),
      system.host_path,
      system.cerb_file,
    ],
  });

module.exports = get_siemens_cv_data;
