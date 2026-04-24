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
  type: { I, E },
  tag: { cal, det, cat },
} = require("../../utils/logger/enums");
const exec_hhm_data_grab = require("../../read/exec-hhm_data_grab");
const exec_hhm_postprocess = require("../../read/exec-hhm_postprocess");

// Shared runner for the 8 similar HHM jobs under jobs/hhm/{ge,philips,siemens}/.
// Not used by philips_cv (multi-stage outlier).
//
// config fields (required unless defaulted):
//   jobName          — timer-label prefix: "<jobName>.sql_fetch" / "<jobName>.promise_all_wait"
//   logLabel         — addLogEvent label, e.g. "get_ge_ct_data"
//   manufacturer     — "GE" | "Philips" | "Siemens" (passed to fetchSystems)
//   modality         — SQL modality selector (includes SQL LIKE patterns like "%CT")
//   shellSubdir      — folder under read/sh/ (e.g. "GE"); joined with system.acquisition_script
//   fetchSystems     — (args) => Promise<System[]>; used only by runHhmJob (not retry)
//   fetchCredentials — (args) => Promise<Creds[]>; OMIT to skip credential fetch
//   argsBuilder      — (system, creds | null) => string[]; the exec tuple shape varies
//   hostPredicate    — (system) => boolean; defaults to host_ip && credentials_group (with creds)
//                      or acquisition_script && host_ip (without). Used by runHhmJob only;
//                      retry skips this check — a queued system is implicitly eligible.
//   extraExecArgs    — positional args appended after ip_reset. philips_mri uses this to pass
//                      PHILIPS_MRI_SHELL_TIMEOUT_S as arg 9 to exec_hhm_data_grab.
//   postProcessScript — optional shell script run after a successful acquisition with its own
//                      (generally more generous) timeout via exec_hhm_postprocess. Used by
//                      philips_ct to detach mdb-export conversion from the 90s acquisition wrap.

// Per-system exec: build path + args, spawn, maybe post-process. Used by both
// the bulk runHhmJob loop and the tunnel_reset retryHhmSystem entry point.
// Returns exec_hhm_data_grab's result (stdout | false | null) — post-process
// failure does NOT downgrade acquisition status, matching the S7 split intent.
const execHhmSystem = async (
  run_log,
  system,
  job_id,
  creds,
  capture_datetime,
  ipReset,
  config
) => {
  const execPath = `./read/sh/${config.shellSubdir}/${system.acquisition_script}`;
  const execArgs = config.argsBuilder(system, creds);
  const extra = config.extraExecArgs || [];

  const result = await exec_hhm_data_grab(
    job_id,
    run_log,
    system.id,
    execPath,
    system,
    execArgs,
    capture_datetime,
    ipReset,
    ...extra
  );

  if (config.postProcessScript && result !== false && result !== null) {
    await exec_hhm_postprocess(
      job_id,
      run_log,
      system.id,
      config.postProcessScript,
      system,
      capture_datetime
    );
  }

  return result;
};

// Main-run entry point: fetch all systems for a (manufacturer, modality),
// fan out with Promise.all, exec each with ipReset=false.
const runHhmJob = async (run_log, capture_datetime, config) => {
  const {
    jobName,
    logLabel,
    manufacturer,
    modality,
    fetchSystems,
    fetchCredentials,
    hostPredicate,
  } = config;

  await addLogEvent(I, run_log, logLabel, cal, null, null);

  startTimer(run_log, `${jobName}.sql_fetch`);
  const systems = await fetchSystems([manufacturer, modality]);
  const credentials = fetchCredentials
    ? await fetchCredentials([manufacturer, modality])
    : null;
  await endTimer(run_log, `${jobName}.sql_fetch`, {
    system_count: systems.length,
    credential_count: credentials ? credentials.length : 0,
  });

  const defaultPredicate = fetchCredentials
    ? (sys) => Boolean(sys.host_ip && sys.credentials_group)
    : (sys) => Boolean(sys.acquisition_script && sys.host_ip);
  const passesPredicate = hostPredicate || defaultPredicate;

  const child_processes = [];
  for (const system of systems) {
    const job_id = uuidv4();
    const note = { job_id, system: systemLogShape(system) };
    try {
      await addLogEvent(I, run_log, logLabel, det, note, null);
      if (!passesPredicate(system)) continue;

      const creds = credentials
        ? credentials.find((c) => c.id == system.credentials_group)
        : null;

      child_processes.push(async () =>
        execHhmSystem(run_log, system, job_id, creds, capture_datetime, false, config)
      );
    } catch (error) {
      await addLogEvent(E, run_log, logLabel, cat, note, error);
    }
  }

  try {
    await addLogEvent(
      I,
      run_log,
      `${logLabel}: run child_processes`,
      cal,
      null,
      null
    );
    const promises = child_processes.map((child_process) => child_process());
    startTimer(run_log, `${jobName}.promise_all_wait`);
    await Promise.all(promises);
    await endTimer(run_log, `${jobName}.promise_all_wait`, {
      child_process_count: child_processes.length,
    });
  } catch (error) {
    await addLogEvent(
      E,
      run_log,
      `${logLabel}: run child_processes`,
      cat,
      null,
      error
    );
  }
};

// Retry entry point (tunnel_reset). The system comes from the redis queue,
// so we skip SQL system fetch and hostPredicate. We still fetch credentials
// if the config requires them (unless caller pre-fetched and passed them in
// via the optional `credentials` arg — useful when multiple queued systems
// share a (manufacturer, modality) so we don't N+1).
const retryHhmSystem = async (
  run_log,
  system,
  job_id,
  capture_datetime,
  config,
  credentials = null
) => {
  const note = { job_id, system: systemLogShape(system) };
  try {
    await addLogEvent(I, run_log, config.logLabel, cal, note, null);

    let creds = null;
    if (config.fetchCredentials) {
      const credList =
        credentials ||
        (await config.fetchCredentials([config.manufacturer, config.modality]));
      creds = credList.find((c) => c.id == system.credentials_group);
    }

    await execHhmSystem(
      run_log,
      system,
      job_id,
      creds,
      capture_datetime,
      true,
      config
    );
  } catch (error) {
    await addLogEvent(E, run_log, config.logLabel, cat, note, error);
  }
};

module.exports = { runHhmJob, retryHhmSystem };
