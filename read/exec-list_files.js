const util = require("util");
const execFile = util.promisify(require("child_process").execFile);

const { add_to_online_queue } = require("../redis");

const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

const exec_list_files = async (run_log, job_id, capture_datetime, path, args) => {
  const sme = args[2];
  let note = {
    system_id: sme,
    path,
    args
  };
  addLogEvent(I, run_log, "exec_list_files", cal, note, null);

  try {
    const { stdout, stderr } = await execFile(path, args);

    // stdout is null-delimited -> split safely
    const files_list = stdout.split("\0").filter(Boolean);

    await add_to_online_queue(job_id, run_log, {
      id: sme,
      capture_datetime,
      successful_acquisition: true,
      data_source: "mmb"
    });

    return files_list;
  } catch (error) {
    console.log(error);
    addLogEvent(E, run_log, "exec_list_files", cat, note, error);

    await add_to_online_queue(job_id, run_log, {
      id: sme,
      capture_datetime,
      successful_acquisition: false,
      data_source: "mmb"
    });

    return [];
  }
};

module.exports = exec_list_files;
