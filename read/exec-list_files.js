const util = require("util");
const execFile = util.promisify(require("child_process").execFile);

const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

const exec_list_files = async (
  run_log,
  job_id,
  path,
  args
) => {
  const sme = args[2];
  let note = {
    job_id,
    system_id: sme,
    path,
    args
  };
  addLogEvent(I, run_log, "exec_list_files", cal, note, null);

  try {
    const { stdout } = await execFile(path, args);

    // stdout is null-delimited -> split safely
    const files_list = stdout.split("\0").filter(Boolean);

    return { files: files_list, success: true };
  } catch (error) {
    console.log(error);
    addLogEvent(E, run_log, "exec_list_files", cat, note, error);
    return { files: [], success: false, error };
  }
};

module.exports = exec_list_files;
