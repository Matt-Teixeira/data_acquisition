const exec_remote_rsync = require("../../read/exec-remote_rsync");
const rsync_local = require("../../relocate_files/rsync_local");
const { get_phil_mri_systems } = require("../../sql/qf-provider");
const captureDatetime = require("../../util/tools/captureDatetime");
const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");
const path = require("path");

const rsync_philips_mri = async (run_log, job_id = null) => {
  const system_data = await get_phil_mri_systems();

  // Single capture_datetime for the whole cycle so all per-SME queue entries
  // share a timestamp (mirrors the schedule-based MMB driver pattern).
  const capture_datetime = captureDatetime();

  const child_processes = [];
  for await (const system of system_data) {
    console.log(system.id);
    child_processes.push(
      async () => await group_processes(run_log, system, capture_datetime, job_id)
    );
  }
  try {
    // CREATE AN ARRAY OF PROMISES BY CALLING EACH child_process FUNCTION
    const promises = child_processes.map((child_process) => child_process());

    // AWAIT PROMISIS
    await Promise.all(promises);
  } catch (error) {
    addLogEvent(E, run_log, "rsync_philips_mri", cat, null, error);
  }
};

async function group_processes(run_log, system, capture_datetime, job_id) {
  const fallback = path.join(process.cwd(), "files");
  addLogEvent(I, run_log, "rsync_philips_mri", cal, { system }, null);
  await exec_remote_rsync(
    run_log,
    system.id,
    "./read/sh/rsync_mmb.sh",
    [system.user_id, system.mmb_ip, `${fallback}/${system.id}`],
    capture_datetime,
    job_id
  );
  await rsync_local(
    run_log,
    `${fallback}/${system.id}/host_logfiles`,
    system,
    fallback
  );
}

module.exports = rsync_philips_mri;
