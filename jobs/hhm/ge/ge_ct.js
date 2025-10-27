const exec_hhm_data_grab = require("../../../read/exec-hhm_data_grab");
const { get_hhm, getHhmCreds } = require("../../../sql/qf-provider");
const { decryptString } = require("../../../util");
const {
  encrypt_string,
  decrypt_string,
} = require("../../../util/encrypt/decrypt");
const { v4: uuidv4 } = require("uuid");
const [addLogEvent] = require("../../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf },
} = require("../../../utils/logger/enums");

async function get_ge_ct_data(run_log, capture_datetime) {
  await addLogEvent(I, run_log, "get_ge_ct_data", cal, null, null);

  const manufacturer = "GE";
  const modality = "CT";
  const systems = await get_hhm([manufacturer, modality]);
  const credentials = await getHhmCreds([manufacturer, modality]);

  const child_processes = [];
  for (const system of systems) {
    const job_id = uuidv4();
    let note = {
      job_id: job_id,
      system,
    };
    try {
      await addLogEvent(I, run_log, "get_ge_ct_data", det, note, null);

      const ct_path = `./read/sh/GE/${system.acquisition_script}`;

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
            ct_path,
            system,
            [system.host_ip, user, pass],
            capture_datetime
          )
      );
    } catch (error) {
      let note = {
        job_id: job_id,
        system,
      };
      await addLogEvent(E, run_log, "get_ge_ct_data", cat, note, error);
    }
  }
  try {
    await addLogEvent(
      I,
      run_log,
      "get_ge_ct_data: run child_processes",
      cal,
      null,
      null
    );
    // CREATE AN ARRAY OF PROMISES BY CALLING EACH child_process FUNCTION
    const promises = child_processes.map((child_process) => child_process());

    // AWAIT PROMISIS
    await Promise.all(promises);
  } catch (error) {
    console.log(error);
    await addLogEvent(
      E,
      run_log,
      "get_ge_ct_data: run child_processes",
      cat,
      null,
      error
    );
  }
}
module.exports = get_ge_ct_data;
