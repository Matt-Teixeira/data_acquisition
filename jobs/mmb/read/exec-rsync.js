const util = require("util");
const execFile = util.promisify(require("child_process").execFile);
const { add_to_redis_queue, add_to_online_queue } = require("../../../redis");

const [addLogEvent] = require("../../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../../utils/logger/enums");

/* 
run_log,
job_id,
system.id,
`./jobs/mmb/read/sh/rsync_mmb.sh`,
system.rsyncShArgs,
capture_datetime,
true
*/

const execRsync = async (
  run_log,
  job_id,
  sme,
  rsyncShPath,
  rsyncShArgs,
  capture_datetime,
  vpn,
  ip_reset = false
) => {
  //  console.log(rsyncShArgs);
  // THIS FUNCTION SYNCS A REMOTE FILE TO A LOCAL MIRROR AND RETURNS THE NEWLY SYNCED FILE SIZE
  let note = {
    job_id,
    sme: sme,
    rsyncShPath: rsyncShPath,
    rsyncShArgs: rsyncShArgs
  };
  await addLogEvent(I, run_log, "execRsync", cal, note, null);

  const connection_error = /Connection timed out|connection unexpectedly closed|Broken pipe|error in rsync protocol data stream/;

  try {
    const { stdout } = await execFile(rsyncShPath, rsyncShArgs);

    const fileSizeAfterRsync = parseInt(stdout);

    let note = {
      job_id,
      sme,
      fileSizeAfterRsync
    };

    await addLogEvent(I, run_log, "execRsync", det, note, null);

    if (capture_datetime !== "ip_reset") {
      await add_to_online_queue(job_id, run_log, {
        id: sme,
        capture_datetime,
        successful_acquisition: true,
        data_source: "mmb"
      });
    }

    return fileSizeAfterRsync;
  } catch (error) {
    let note = {
      job_id,
      sme
    };

    await addLogEvent(E, run_log, "execRsync", cat, note, error);
    //console.log(error);

    if (connection_error.test(error)) {
      let system = {
        id: rsyncShArgs[0],
        vpn: vpn,
        mmb_ip: rsyncShArgs[3],
        data_source: "mmb",
        rsyncShArgs,
        rsyncShPath,
        capture_datetime
      };

      // Only runs for ip reset instance
      // Reason: In initial data pull, if connection issue occurs, just send to ip:queue and make second attempt.
      // If connection issue occurs on second attempt (ip reset job), place in online:queue to then place in alert.offline table
      if (ip_reset) {
        await add_to_online_queue(job_id, run_log, {
          id: system.id,
          capture_datetime,
          successful_acquisition: false,
          data_source: "mmb"
        });

        return null;
      }

      await add_to_redis_queue(job_id, run_log, system);

      return null;
    }
    return null;
  }
};

module.exports = execRsync;
