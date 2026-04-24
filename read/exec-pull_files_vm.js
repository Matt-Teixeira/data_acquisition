const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const [addLogEvent] = require("../utils/logger/log");
const { redactArgsForLog } = require("../util/log_shapes");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

const exec_pull_vm_files = async (run_log, job_id, path, args) => {
  const sme = args[0];
  let note = {
    job_id,
    system_id: sme,
    path,
    // args = [system_id, remote_path, local_path, host_ip, user_id]; redact user_id at index 4.
    args: redactArgsForLog(args, [4])
  };
  addLogEvent(I, run_log, "exec_pull_vm_files", cal, note, null);
  console.log(args);
  try {
    const { stdout, stderr } = await execFile(path, args);

    console.log("\nstdout");
    console.log(stdout);

    return;
  } catch (error) {
    console.log(error);
    addLogEvent(E, run_log, "exec_pull_vm_files", cat, note, error);
    return [];
  }
};

module.exports = exec_pull_vm_files;
