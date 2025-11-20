const fsp = require("node:fs/promises");
const exec_local_rsync = require("../read/exec-copy_local");
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf },
} = require("../utils/logger/enums");

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
          `${docker_path}/${system.id}/logs`,
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
        const files = await fsp.readdir(rsync_path);
        const rmmu_re_test = /rmmu\d+\.log/;

        // Gather only rmmu files. Example rmmu20140107030318.log
        const rmmu_files = files.filter((f) => rmmu_re_test.test(f) === true);

        for (const rmmu_file of rmmu_files) {
          await exec_local_rsync(
            run_log,
            system.id,
            "./read/sh/rsync_monitoring_local.sh",
            [
              `${docker_path}/${system.id}/host_logfiles/${rmmu_file}`,
              `${docker_path}/${system.id}/rmmu`,
            ]
          );
        }
      } else if (key === "rmmu_magnet") {
        const files = await fsp.readdir(rsync_path);
        const rmmu_re_test = /rmmu_magnet\d+\.log/;

        // Gather only rmmu files. Example rmmu20140107030318.log
        const rmmu_files = files.filter((f) => rmmu_re_test.test(f) === true);

        for (const rmmu_file of rmmu_files) {
          await exec_local_rsync(
            run_log,
            system.id,
            "./read/sh/rsync_monitoring_local.sh",
            [
              `${docker_path}/${system.id}/host_logfiles/${rmmu_file}`,
              `${docker_path}/${system.id}/rmmu_magnet`,
            ]
          );
        }
      } else if (key === "rmmu_long") {
        const files = await fsp.readdir(rsync_path); 
        const rmmu_re_test = /rmmu_long_cryogenic\d+\.log/;

        // Gather only rmmu files. Example rmmu20140107030318.log
        const rmmu_files = files.filter((f) => rmmu_re_test.test(f) === true);

        for (const rmmu_file of rmmu_files) {
          await exec_local_rsync(
            run_log,
            system.id,
            "./read/sh/rsync_monitoring_local.sh",
            [
              `${docker_path}/${system.id}/host_logfiles/${rmmu_file}`,
              `${docker_path}/${system.id}/rmmu_long`,
            ]
          );
        }
      } else if (key === "rmmu_short") {
        const files = await fsp.readdir(rsync_path); 
        const rmmu_re_test = /rmmu_short_cryogenic\d+\.log/;

        // Gather only rmmu files. Example rmmu20140107030318.log
        const rmmu_files = files.filter((f) => rmmu_re_test.test(f) === true);

        for (const rmmu_file of rmmu_files) {
          await exec_local_rsync(
            run_log,
            system.id,
            "./read/sh/rsync_monitoring_local.sh",
            [
              `${docker_path}/${system.id}/host_logfiles/${rmmu_file}`,
              `${docker_path}/${system.id}/rmmu_short`,
            ]
          );
        }
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
