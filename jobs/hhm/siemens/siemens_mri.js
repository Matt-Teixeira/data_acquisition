const exec_hhm_data_grab = require("../../../read/exec-hhm_data_grab");
const { get_hhm } = require("../../../sql/qf-provider");
const { v4: uuidv4 } = require("uuid");

const [addLogEvent] = require("../../../utils/logger/log");
const { systemLogShape } = require("../../../util/log_shapes");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf },
} = require("../../../utils/logger/enums");

async function get_siemens_mri_data(run_log, capture_datetime) {
  await addLogEvent(I, run_log, "get_siemens_mri_data", cal, null, null);

  const manufacturer = "Siemens";
  const modality = "MRI";
  const systems = await get_hhm([manufacturer, modality]);

  const child_processes = [];
  for await (const system of systems) {
    const job_id = uuidv4();
    let note = {
      job_id,
      system: systemLogShape(system),
    };
    try {
      await addLogEvent(I, run_log, "get_siemens_mri_data", det, note, null);
      if (system.acquisition_script && system.host_ip) {
        const mri_path = `./read/sh/Siemens/${system.acquisition_script}`;

        child_processes.push(
          async () =>
            await exec_hhm_data_grab(
              job_id,
              run_log,
              system.id,
              mri_path,
              system,
              [system.host_ip],
              capture_datetime
            )
        );
      }
    } catch (error) {
      await addLogEvent(E, run_log, "get_siemens_mri_data", cat, note, error);
    }
  }
  try {
    // CREATE AN ARRAY OF PROMISES BY CALLING EACH child_process FUNCTION
    const promises = child_processes.map((child_process) => child_process());

    // AWAIT PROMISIS
    await Promise.all(promises);
  } catch (error) {
    addLogEvent(E, run_log, "get_siemens_ct_data", cat, null, error);
  }
}

module.exports = get_siemens_mri_data;
