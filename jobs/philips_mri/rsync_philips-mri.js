const exec_remote_rsync = require("../../read/exec-remote_rsync");
const rsync_local = require("../../relocate_files/rsync_local");
const { get_phil_mri_systems } = require("../../sql/qf-provider");
const captureDatetime = require("../../util/tools/captureDatetime");
const { v4: uuidv4 } = require("uuid");
const [
  addLogEvent,
  ,
  ,
  ,
  ,
  startTimer,
  endTimer,
] = require("../../utils/logger/log");
const { systemLogShape } = require("../../util/log_shapes");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");
const path = require("path");

const rsync_philips_mri = async (run_log, job_id = null, override_system_data = null) => {
  let system_data;
  if (override_system_data) {
    system_data = override_system_data;
  } else {
    startTimer(run_log, "philips_mri_mmb.sql_fetch");
    system_data = await get_phil_mri_systems();
    await endTimer(run_log, "philips_mri_mmb.sql_fetch", {
      system_count: Array.isArray(system_data) ? system_data.length : undefined,
    });
  }

  // Single capture_datetime for the whole cycle so all per-SME queue entries
  // share a timestamp (mirrors the schedule-based MMB driver pattern).
  const capture_datetime = captureDatetime();

  // The outer `job_id` param is preserved for backwards compat with retry
  // callers but is intentionally not threaded into per-system events — each
  // system needs its own UUID so the JSON log can correlate a single
  // system's CALL/DETAILS/CATCH chain. (Pre-fix: all systems shared the
  // outer caller's timestamp/null as job_id, breaking per-system tracing.)
  void job_id;

  const child_processes = [];
  for await (const system of system_data) {
    console.log(system.id);
    child_processes.push(
      async () => await group_processes(run_log, system, capture_datetime)
    );
  }
  try {
    // CREATE AN ARRAY OF PROMISES BY CALLING EACH child_process FUNCTION
    const promises = child_processes.map((child_process) => child_process());

    // AWAIT PROMISIS
    startTimer(run_log, "philips_mri_mmb.promise_all_wait");
    await Promise.all(promises);
    await endTimer(run_log, "philips_mri_mmb.promise_all_wait", {
      child_process_count: child_processes.length,
    });
  } catch (error) {
    addLogEvent(E, run_log, "rsync_philips_mri", cat, null, error);
  }
};

async function group_processes(run_log, system, capture_datetime) {
  // Per-system UUID so each system's exec_remote_rsync CALL/DETAILS/CATCH
  // chain is independently traceable in the JSON log. Mirrors the pattern
  // used in jobs/hhm/_shared.js.
  const job_id = uuidv4();
  const fallback = path.join(process.cwd(), "files");
  addLogEvent(I, run_log, "rsync_philips_mri", cal, { job_id, system: systemLogShape(system) }, null);

  const remote_label = `remote_rsync.${system.id}`;
  startTimer(run_log, remote_label);
  try {
    await exec_remote_rsync(
      job_id,
      run_log,
      system.id,
      "./read/sh/rsync_mmb.sh",
      [system.user_id, system.mmb_ip, `${fallback}/${system.id}`],
      capture_datetime
    );
  } finally {
    await endTimer(run_log, remote_label, {
      sme: system.id,
      mmb_ip: system.mmb_ip,
    });
  }

  const local_label = `local_rsync.${system.id}`;
  startTimer(run_log, local_label);
  try {
    await rsync_local(
      run_log,
      `${fallback}/${system.id}/host_logfiles`,
      system,
      fallback
    );
  } finally {
    await endTimer(run_log, local_label, { sme: system.id });
  }
}

module.exports = rsync_philips_mri;
