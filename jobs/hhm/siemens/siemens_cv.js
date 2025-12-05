const exec_hhm_data_grab = require("../../../read/exec-hhm_data_grab");
const { get_hhm, getHhmCreds } = require("../../../sql/qf-provider");
const { decrypt_string } = require("../../../util/encrypt/decrypt");
const { v4: uuidv4 } = require("uuid");

const [addLogEvent] = require("../../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../../utils/logger/enums");

async function get_siemens_cv_data(run_log, capture_datetime) {
  console.log("SIEMENS_CV/IR");

  const manufacturer = "Siemens";
  const modality = "CV/IR";
  const systems = await get_hhm([manufacturer, modality]);
  const credentials = await getHhmCreds([manufacturer, modality]);

  const child_processes = [];

  console.log(systems);

  for (const system of systems) {
    const job_id = uuidv4();
    let note = {
      job_id,
      system
    };
    try {
      const system_creds = credentials.find((credential) => {
        if (credential.id == system.credentials_group) return true;
      });
      const user = decrypt_string(system_creds.user_enc);
      const pass = decrypt_string(system_creds.password_enc);

      if (system.acquisition_script && system.host_ip) {
        const cv_path = `./read/sh/Siemens/${system.acquisition_script}`;

        child_processes.push(
          async () =>
            await exec_hhm_data_grab(
              job_id,
              run_log,
              system.id,
              cv_path,
              system,
              [system.host_ip, user, pass, system.host_path, system.cerb_file],
              capture_datetime
            )
        );
      }
    } catch (error) {
      console.log(error);
      await addLogEvent(E, run_log, "get_siemens_ct_data", cat, note, error);
    }
  }

  try {
    // CREATE AN ARRAY OF PROMISES BY CALLING EACH child_process FUNCTION
    const promises = child_processes.map((child_process) => child_process());

    // AWAIT PROMISIS
    await Promise.all(promises);
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "get_siemens_ct_data", cat, null, error);
  }
}

module.exports = get_siemens_cv_data;
