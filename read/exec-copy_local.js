const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf },
} = require("../utils/logger/enums");

const exec_local_rsync = async (run_log, sme, rsyncShPath, rsyncShArgs) => {
  let note = {
    system_id: sme,
    rsync_path: rsyncShPath,
    args: rsyncShArgs,
  };
  addLogEvent(I, run_log, "exec_local_rsync", cal, note, null);

  try {
    const { stdout } = await execFile(rsyncShPath, rsyncShArgs);

    // Success-path breadcrumb. Pre-fix this function only logged on CATCH,
    // so 100+ successful per-file rsync invocations per run were invisible
    // in the JSON log. Pattern matches read/exec-hhm_data_grab.js on
    // success. (Note: this helper currently has no job_id; we log
    // system_id + path which is enough to correlate.)
    addLogEvent(I, run_log, "exec_local_rsync", det, {
      system_id: sme,
      rsync_path: rsyncShPath,
    }, null);

    return;
  } catch (error) {
    console.log(error);
    addLogEvent(E, run_log, "exec_local_rsync", cat, note, error);
    return null;
  }
};

module.exports = exec_local_rsync;
