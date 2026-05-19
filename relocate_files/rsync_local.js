const exec_local_rsync = require("../read/exec-copy_local");
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf },
} = require("../utils/logger/enums");

// One rsync invocation per category (source dir + dest dir + filename glob),
// replacing the prior per-file fork loop. See read/sh/rsync_pattern_local.sh.
async function sync_pattern(run_log, system, docker_path, include_glob, subdir) {
  return exec_local_rsync(
    run_log,
    system.id,
    "./read/sh/rsync_pattern_local.sh",
    [
      `${docker_path}/${system.id}/host_logfiles`,
      `${docker_path}/${system.id}/${subdir}`,
      include_glob,
    ]
  );
}

async function rsync_local(run_log, rsync_path, system, docker_path) {
  let note = {
    system_id: system.id,
  };
  try {
    await addLogEvent(I, run_log, "rsync_local", cal, note, null);

    if (system.log_config) {
      await exec_local_rsync(
        run_log,
        system.id,
        "./read/sh/rsync_monitoring_local.sh",
        [
          `${docker_path}/${system.id}/host_logfiles/${system.log_config.file_name}`,
          `${docker_path}/${system.id}`,
        ]
      );
    }

    for await (const file of system.mag_data) {
      console.log(file);
      let key = file.dir_name;

      if (key === "monitoring") {
        await exec_local_rsync(
          run_log,
          system.id,
          "./read/sh/rsync_monitoring_local.sh",
          [
            `${docker_path}/${system.id}/host_logfiles/${file.file_name}`,
            `${docker_path}/${system.id}/monitoring`,
          ]
        );
      } else if (key === "rmmu") {
        await sync_pattern(run_log, system, docker_path, "rmmu[0-9]*.log", "rmmu");
      } else if (key === "rmmu_magnet") {
        await sync_pattern(run_log, system, docker_path, "rmmu_magnet[0-9]*.log", "rmmu_magnet");
      } else if (key === "rmmu_long") {
        await sync_pattern(run_log, system, docker_path, "rmmu_long_cryogenic[0-9]*.log", "rmmu_long");
      } else if (key === "rmmu_short") {
        await sync_pattern(run_log, system, docker_path, "rmmu_short_cryogenic[0-9]*.log", "rmmu_short");
      } else if (key === "stt_magnet") {
        await exec_local_rsync(
          run_log,
          system.id,
          "./read/sh/rsync_logcurrent_local.sh",
          [
            `${docker_path}/${system.id}/host_logfiles/${file.file_name}`,
            `${docker_path}/${system.id}`,
          ]
        );
      }
    }
  } catch (error) {
    console.log("\nCatch Error");
    console.log(error);
    await addLogEvent(E, run_log, "rsync_local", cat, note, null);
  }
}

module.exports = rsync_local;

// echo $3 | sudo -S mv $1 $2
