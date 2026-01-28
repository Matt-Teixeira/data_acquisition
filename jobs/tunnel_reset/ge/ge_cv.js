const exec_hhm_data_grab = require("../../../read/exec-hhm_data_grab");
const { getHhmCreds } = require("../../../sql/qf-provider");
const { decryptString } = require("../../../util");
const [addLogEvent] = require("../../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../../utils/logger/enums");

async function get_ge_cv_data(
  job_id,
  run_log,
  system,
  capture_datetime,
  ip_reset
) {
  const note = { job_id, system_id: system.id };
  try {
    await addLogEvent(I, run_log, "get_ge_cv_data", cal, note, null);
    const manufacturer = "GE";
    const modality = "CV/IR";
    const credentials = await getHhmCreds([manufacturer, modality]);

    const cv_path = `./read/sh/GE/${system.acquisition_script}`;

    const system_creds = credentials.find(
      (credential) => credential.id === system.credentials_group
    );

    const user = decryptString(system_creds.user_enc);
    const pass = decryptString(system_creds.password_enc);

    await exec_hhm_data_grab(
      job_id,
      run_log,
      system.id,
      cv_path,
      system,
      [system.host_ip, user, pass],
      capture_datetime,
      ip_reset
    );
  } catch (error) {
    await addLogEvent(E, run_log, "get_ge_cv_data", cat, note, error);
  }
}

module.exports = get_ge_cv_data;
