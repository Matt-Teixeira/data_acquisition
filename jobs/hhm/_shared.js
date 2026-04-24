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

// Shared runner for the 8 similar HHM jobs under jobs/hhm/{ge,philips,siemens}/.
// Not used by philips_cv (multi-stage outlier) or any tunnel_reset path.
//
// config fields (required unless defaulted):
//   jobName          — timer-label prefix: "<jobName>.sql_fetch" / "<jobName>.promise_all_wait"
//   logLabel         — addLogEvent label, e.g. "get_ge_ct_data"
//   manufacturer     — "GE" | "Philips" | "Siemens" (passed to fetchSystems)
//   modality         — SQL modality selector (includes SQL LIKE patterns like "%CT")
//   shellSubdir      — folder under read/sh/ (e.g. "GE"); joined with system.acquisition_script
//   fetchSystems     — (args) => Promise<System[]>; usually get_hhm, except philips_mri uses get_phil_mri_host
//   fetchCredentials — (args) => Promise<Creds[]>; OMIT to skip credential fetch (siemens_ct / siemens_mri)
//   argsBuilder      — (system, creds | null) => string[]; the exec tuple shape varies by vendor
//   hostPredicate    — (system) => boolean; defaults to host_ip && credentials_group (with creds)
//                      or acquisition_script && host_ip (without). Override when the job needs both.
//   extraExecArgs    — positional args appended after ip_reset=false. Used by philips_mri to pass
//                      PHILIPS_MRI_SHELL_TIMEOUT_S as arg 9 to exec_hhm_data_grab.
const runHhmJob = async (run_log, capture_datetime, config) => {
  const {
    jobName,
    logLabel,
    manufacturer,
    modality,
    shellSubdir,
    fetchSystems,
    fetchCredentials,
    argsBuilder,
    hostPredicate,
    extraExecArgs = [],
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

      const execPath = `./read/sh/${shellSubdir}/${system.acquisition_script}`;
      const creds = credentials
        ? credentials.find((c) => c.id == system.credentials_group)
        : null;
      const execArgs = argsBuilder(system, creds);

      child_processes.push(
        async () =>
          await exec_hhm_data_grab(
            job_id,
            run_log,
            system.id,
            execPath,
            system,
            execArgs,
            capture_datetime,
            false,
            ...extraExecArgs
          )
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

module.exports = runHhmJob;
