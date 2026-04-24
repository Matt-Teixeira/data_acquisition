const exec_hhm_data_grab = require("../../../read/exec-hhm_data_grab");
const { get_hhm, getHhmCreds } = require("../../../sql/qf-provider");
const { decrypt_string } = require("../../../util/encrypt/decrypt");
const { v4: uuidv4 } = require("uuid");
const [
  addLogEvent,
  ,
  ,
  ,
  ,
  startTimer,
  endTimer,
] = require("../../../utils/logger/log");
const { systemLogShape } = require("../../../util/log_shapes");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf },
} = require("../../../utils/logger/enums");

async function get_ge_cv_data(run_log, capture_datetime) {
  await addLogEvent(I, run_log, "get_ge_cv_data", cal, null, null);

  const manufacturer = "GE";
  const modality = "CV/IR";
  startTimer(run_log, "ge_cv.sql_fetch");
  const systems = await get_hhm([manufacturer, modality]);
  const credentials = await getHhmCreds([manufacturer, modality]);
  await endTimer(run_log, "ge_cv.sql_fetch", {
    system_count: systems.length,
    credential_count: credentials.length,
  });

  const child_processes = [];
  for (const system of systems) {
    const job_id = uuidv4();
    let note = {
      job_id,
      system: systemLogShape(system),
    };
    try {
      await addLogEvent(I, run_log, "get_ge_cv_data", det, note, null);
      if (system.host_ip && system.credentials_group) {
        const cv_path = `./read/sh/GE/${system.acquisition_script}`;

        const system_creds = credentials.find((credential) => {
          if (credential.id == system.credentials_group) return true;
        });

        const user = decrypt_string(system_creds.user_enc);
        const pass = decrypt_string(system_creds.password_enc);

        child_processes.push(
          async () =>
            await exec_hhm_data_grab(
              job_id,
              run_log,
              system.id,
              cv_path,
              system,
              [system.host_ip, user, pass],
              capture_datetime
            )
        );
      }
    } catch (error) {
      let note = {
        job_id: job_id,
        system: systemLogShape(system),
      };
      await addLogEvent(E, run_log, "get_ge_cv_data", cat, note, error);
    }
  }
  try {
    await addLogEvent(
      I,
      run_log,
      "get_ge_cv_data: run child_processes",
      cal,
      null,
      null
    );
    // CREATE AN ARRAY OF PROMISES BY CALLING EACH child_process FUNCTION
    const promises = child_processes.map((child_process) => child_process());

    // AWAIT PROMISIS
    startTimer(run_log, "ge_cv.promise_all_wait");
    await Promise.all(promises);
    await endTimer(run_log, "ge_cv.promise_all_wait", {
      child_process_count: child_processes.length,
    });
  } catch (error) {
    await addLogEvent(
      E,
      run_log,
      "get_ge_cv_data: run child_processes",
      cat,
      null,
      error
    );
  }
}

module.exports = get_ge_cv_data;
