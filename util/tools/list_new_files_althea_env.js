const fs = require("fs");
const fsp = require("fs/promises");
const path = require("path");
const { pipeline } = require("stream/promises");
const { DateTime } = require("luxon");

const exec_list_files = require("../../read/exec-list_files");
const exec_pull_vm_files = require("../../read/exec-pull_files_vm");
const {
  get_prev_file,
  update_last_file
} = require("../../redis/redis_helpers");
const { add_to_online_queue } = require("../../redis");

const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");

async function get_new_files(job_id, run_log, system, capture_datetime) {
  // SHELL SCRIPT EXEC PATHS
  const pull_path = `./read/sh/althea-env/${system.acquisition_script}`;

  console.log("\ncapture_datetime");
  console.log(capture_datetime);

  if (process.env.RUN_ENV === "dev") {
    system.debian_server_path =
      "/home/matt-teixeira/hep3/hhm_data_acquisition/files";
  }

  const remote_path = `${system.host_path}/${system.system_id}.v3_ge_mm3.log`;
  const local_path = `${system.debian_server_path}/${system.system_id}.v3_ge_mm3.log`;

  console.log(system);

  try {
    await exec_pull_vm_files(run_log, job_id, pull_path, [
      system.system_id,
      remote_path,
      local_path,
      system.host_ip,
      system.user_id
    ]);

    let lastCaptureDatetime = await readLastCaptureDatetime(local_path);

    if (lastCaptureDatetime) {
      lastCaptureDatetime = DateTime.fromISO(lastCaptureDatetime, {
        zone: "utc"
      })
        .setZone("America/New_York")
        .toISO();
    }

    await add_to_online_queue(job_id, run_log, {
      id: system.system_id,
      capture_datetime: lastCaptureDatetime,
      successful_acquisition: true,
      data_source: "mmb"
    });
  } catch (error) {
    console.log(error);
  }
}

async function readLastCaptureDatetime(filePath) {
  const marker = "[END CAPTURE BLOCK : ";
  const closing = "]";
  const isoRe = /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/;
  const chunkSize = 64 * 1024;
  const overlap = marker.length + 32;

  const handle = await fsp.open(filePath, "r");

  try {
    const { size } = await handle.stat();
    if (size === 0) {
      return null;
    }

    let offset = size;
    let carry = "";

    while (offset > 0) {
      const readSize = Math.min(chunkSize, offset);
      offset -= readSize;

      const buffer = Buffer.allocUnsafe(readSize);
      const { bytesRead } = await handle.read(buffer, 0, readSize, offset);
      if (bytesRead === 0) {
        break;
      }

      const chunk = buffer.toString("utf8", 0, bytesRead);
      const combined = chunk + carry;

      let searchIndex = combined.length;
      let needsMore = false;

      while (true) {
        const markerIndex = combined.lastIndexOf(marker, searchIndex - 1);
        if (markerIndex === -1) {
          break;
        }

        if (markerIndex >= chunk.length && carry) {
          searchIndex = markerIndex;
          continue;
        }

        const isoStart = markerIndex + marker.length;
        const closingIndex = combined.indexOf(closing, isoStart);

        if (closingIndex === -1) {
          carry = combined.slice(markerIndex);
          needsMore = true;
          break;
        }

        const candidate = combined.slice(isoStart, closingIndex).trim();
        if (isoRe.test(candidate)) {
          return candidate;
        }

        searchIndex = markerIndex;
      }

      if (needsMore) {
        continue;
      }

      carry = combined.slice(0, Math.min(overlap, combined.length));
    }

    return null;
  } finally {
    await handle.close();
  }
}

module.exports = get_new_files;
