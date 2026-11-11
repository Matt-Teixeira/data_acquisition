const exec_hhm_data_grab = require("../../../read/exec-hhm_data_grab");
const { get_phil_mri_host, getHhmCreds } = require("../../../sql/qf-provider");
const { decryptString } = require("../../../util");
const { v4: uuidv4 } = require("uuid");

const [addLogEvent] = require("../../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../../utils/logger/enums");

async function get_philips_mri_data(run_log, capture_datetime) {
  await addLogEvent(I, run_log, "get_philips_mri_data", cal, null, null);

  const manufacturer = "Philips";
  const modality = "MRI";
  const systems = await get_phil_mri_host([manufacturer, modality]);
  const credentials = await getHhmCreds([manufacturer, modality]);

  console.log("\nsystems");
  console.log(systems);

  const child_processes = [];
  for (const system of systems) {
    const job_id = uuidv4();
    let note = {
      job_id,
      system
    };

    try {
      await addLogEvent(I, run_log, "get_philips_mri_data", det, note, null);
      if (system.host_ip && system.credentials_group) {
        const mri_path = `./read/sh/Philips/${system.acquisition_script}`;

        const system_creds = credentials.find((credential) => {
          if (credential.id == system.credentials_group)
            return true;
        });

        const user = decryptString(system_creds.user_enc);
        const pass = decryptString(system_creds.password_enc);

        child_processes.push(
          async () =>
            await exec_hhm_data_grab(
              job_id,
              run_log,
              system.id,
              mri_path,
              system,
              [system.host_ip, user, pass],
              capture_datetime
            )
        );
      }
    } catch (error) {
      console.log(error);
      addLogEvent(E, run_log, "get_philips_mri_data", cat, note, error);
    }
  }
  try {
    // CREATE AN ARRAY OF PROMISES BY CALLING EACH child_process FUNCTION
    const promises = child_processes.map((child_process) => child_process());

    // AWAIT PROMISIS
    await Promise.all(promises);
  } catch (error) {
    console.log(error);
    addLogEvent(E, run_log, "get_philips_mri_data", cat, null, error);
  }
}

module.exports = get_philips_mri_data;
