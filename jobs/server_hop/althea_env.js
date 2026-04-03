const exec_hhm_data_grab = require("../../read/exec-hhm_data_grab");
const { get_new_files } = require("../../util");
const { v4: uuidv4 } = require("uuid");
const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");

const { get_althea_env_systems } = require("../../sql/qf-provider");

async function get_althea_env_data(run_log, capture_datetime) {
  const job_id = uuidv4();
  let note = {
    job_id: job_id
  };
  await addLogEvent(I, run_log, "get_althea_env_data", cal, note, null);

  const systems = await get_althea_env_systems();

  console.log(systems);

  for await (const system of systems) {
    await get_new_files(job_id, run_log, system, capture_datetime);
  }

  try {
    await addLogEvent(I, run_log, "get_althea_env_data", det, note, null);
    return;
  } catch (error) {
    await addLogEvent(E, run_log, "get_althea_env_data", cat, null, error);
  }
}

module.exports = get_althea_env_data;
