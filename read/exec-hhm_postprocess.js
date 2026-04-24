const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const [
  addLogEvent,
  ,
  ,
  ,
  ,
  startTimer,
  endTimer,
] = require("../utils/logger/log");
const {
  type: { I, E },
  tag: { cal, det, cat },
} = require("../utils/logger/enums");
const path = require("path");

const PHASE = "postprocess";

// Post-processing (e.g. mdb-export, unzip) runs against already-local files,
// so it has its own — generally more generous — timeout budget than the
// acquisition phase. Two-layer pattern matches exec-hhm_data_grab: coreutils
// `timeout` fires first (exit 124), Node backstop catches scripts that trap
// TERM. Classifies timeouts as `postprocess_timeout` and other failures as
// `postprocess_fail` so they don't mix with network-phase classifications.
const SHELL_TIMEOUT_S = Number(process.env.POSTPROCESS_SHELL_TIMEOUT_S) || 180;
const EXEC_TIMEOUT_MS = Number(process.env.EXEC_TIMEOUT_MS) || 120_000;
const EXEC_MAX_BUFFER = 10 * 1024 * 1024;
const MAX_STREAM_CHARS = 4096;

const truncateStream = (s) => {
  if (typeof s !== "string" || s.length <= MAX_STREAM_CHARS) return s;
  return `...[truncated ${s.length - MAX_STREAM_CHARS} chars]\n${s.slice(-MAX_STREAM_CHARS)}`;
};

const exec_hhm_postprocess = async (
  job_id,
  run_log,
  sme,
  scriptPath,
  system,
  capture_datetime
) => {
  const inner_container_path = path.join(process.cwd(), "files");
  const data_store_path = `${inner_container_path}/${sme}`;
  const args = [data_store_path];

  const resolvedShellS = SHELL_TIMEOUT_S;
  const resolvedExecMs = Math.max(
    EXEC_TIMEOUT_MS,
    resolvedShellS * 1000 + 30_000
  );

  const note = {
    job_id,
    system_id: sme,
    execute_path: scriptPath,
    file_path: data_store_path,
  };

  await addLogEvent(I, run_log, "exec_hhm_postprocess", cal, note, null);

  const timer_label = `postprocess.${sme}`;
  startTimer(run_log, timer_label);
  try {
    try {
      const { stdout, stderr } = await execFile(
        "timeout",
        [`${resolvedShellS}s`, scriptPath, ...args],
        {
          timeout: resolvedExecMs,
          killSignal: "SIGKILL",
          maxBuffer: EXEC_MAX_BUFFER,
        }
      );

      await addLogEvent(
        I,
        run_log,
        "exec_hhm_postprocess",
        det,
        {
          job_id,
          system_id: sme,
          stdout: truncateStream(stdout),
          stderr: truncateStream(stderr),
          phase: PHASE,
        },
        null
      );

      return stdout;
    } catch (error) {
      // Postprocess runs on already-local files, so a failure here is never
      // a connection issue. No redis queue, no system_reset_totalizer — the
      // acquisition phase already routed the system based on its own status.
      const isTimeout = error.code === 124 || error.killed === true;
      await addLogEvent(
        E,
        run_log,
        "exec_hhm_postprocess",
        cat,
        {
          job_id,
          system_id: sme,
          error_category: isTimeout ? "postprocess_timeout" : "postprocess_fail",
          phase: PHASE,
        },
        error
      );
      return false;
    }
  } finally {
    await endTimer(run_log, timer_label, {
      sme,
      host_ip: system.host_ip,
    });
  }
};

module.exports = exec_hhm_postprocess;
