const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const [addLogEvent] = require("../utils/logger/log");
const { redactArgsForLog } = require("../util/log_shapes");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

// Matches the two-layer timeout pattern in exec-hhm_data_grab: coreutils
// `timeout` fires first with exit 124; Node backstop fires for scripts that
// trap TERM. Prevents indefinite hangs on unreachable hosts.
const SHELL_TIMEOUT_S = Number(process.env.SHELL_TIMEOUT_S) || 90;
const EXEC_TIMEOUT_MS = Number(process.env.EXEC_TIMEOUT_MS) || 120_000;
const EXEC_MAX_BUFFER = 10 * 1024 * 1024;

const exec_pull_vm_files = async (run_log, job_id, path, args) => {
  const sme = args[0];
  let note = {
    job_id,
    system_id: sme,
    path,
    // args = [system_id, remote_path, local_path, host_ip, user_id]; redact user_id at index 4.
    args: redactArgsForLog(args, [4])
  };
  await addLogEvent(I, run_log, "exec_pull_vm_files", cal, note, null);
  console.log(args);
  try {
    const resolvedExecMs = Math.max(
      EXEC_TIMEOUT_MS,
      SHELL_TIMEOUT_S * 1000 + 30_000
    );
    const { stdout, stderr } = await execFile(
      "timeout",
      [`${SHELL_TIMEOUT_S}s`, path, ...args],
      {
        timeout: resolvedExecMs,
        killSignal: "SIGKILL",
        maxBuffer: EXEC_MAX_BUFFER,
      }
    );

    console.log("\nstdout");
    console.log(stdout);

    return;
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "exec_pull_vm_files", cat, note, error);
    return [];
  }
};

module.exports = exec_pull_vm_files;
