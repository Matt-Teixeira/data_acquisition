const fs = require("fs");
const fsp = require("fs/promises");
const path = require("path");
const { pipeline } = require("stream/promises");

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
  const list_path = "./read/sh/althea-env/list_files.sh";
  const pull_path = "./read/sh/althea-env/althea_server_pull.sh";

  // DEV CHANGES FOR TESTING: REMOVE OR COMMENT OUT
  if (process.env.RUN_ENV === "dev") {
    system.debian_server_path = `/home/matt-teixeira/hep3/hhm_data_acquisition/files/${system.system_id}_temp`;
  }

  // CREATE FILE NAME && DIR PATHS
  const perm_file_name = `${system.system_id}.v3_ge_mm3.log`;
  const dir = path.dirname(system.debian_server_path);
  let perm_file_path = path.join(dir, perm_file_name);

  console.log(perm_file_path);

  let note = {
    job_id,
    system_id: system.system_id
  };

  await addLogEvent(I, run_log, "get_new_files", cal, note, null);

  let latestCaptureFromProcessed = null;
  let acquisitionSuccess = false;

  try {
    const listResult = await exec_list_files(
      run_log,
      job_id,
      list_path,
      [system.user_id, system.host_ip, system.system_id]
    );

    if (!listResult.success) {
      throw listResult.error || new Error("Failed to list remote files");
    }

    const files = listResult.files;

    // NO NEED TO DO ANY WORK
    if (files.length > 0) {
      // ARRANGE FILES BY APPENDED DATE ASC
      const sorted = [...files].sort((a, b) => {
        const da = yyyymmddFromName(a);
        const db = yyyymmddFromName(b);
        if (da && db)
          return da === db ? a.localeCompare(b) : da.localeCompare(db);
        if (da && !db) return -1;
        if (!da && db) return 1;
        return a.localeCompare(b);
      });

      const { last_file_processed, getKey } = await get_prev_file(
        job_id,
        run_log,
        system.system_id,
        "althea_vm"
      );

      console.log("\nlast_file_processed");
      console.log(last_file_processed);
      const files_to_process = [];

      if (last_file_processed) {
        note.last_file_processed = last_file_processed;
        await addLogEvent(I, run_log, "get_new_files", cal, note, null);

        for (let i = sorted.length - 1; i > 0; i--) {
          if (last_file_processed === sorted[i]) break;
          files_to_process.unshift(sorted[i]);
        }

        for (const file of files_to_process) {
          console.log("\nPULLING AND PROCESSING DELTA");
          await exec_pull_vm_files(run_log, job_id, pull_path, [
            system.user_id,
            system.host_ip,
            system.system_id,
            file,
            system.debian_server_path
          ]);

          const files_to_append = await listFiles(system.debian_server_path);

          console.log("\nfiles_to_append");
          console.log(files_to_append);

          const res = await concatFilesInOrder(
            system.debian_server_path,
            files_to_append,
            perm_file_path,
            getKey
          );

          console.log("\nres");
          console.log(res);

          if (res && res.lastCaptureUtc) {
            latestCaptureFromProcessed = res.lastCaptureUtc;
          }
        }

        console.log("\n END OF DELTA PROCESSING");
      } else {
        for (const file of sorted) {
          await exec_pull_vm_files(run_log, job_id, pull_path, [
            system.user_id,
            system.host_ip,
            system.system_id,
            file,
            system.debian_server_path
          ]);
        }

        const files_to_append = await listFiles(system.debian_server_path);

        const res = await concatFilesInOrder(
          system.debian_server_path,
          files_to_append,
          perm_file_path,
          getKey
        );

        console.log(res);
        console.log("\n END OF ALL FILES PROCESSING");

        if (res && res.lastCaptureUtc) {
          latestCaptureFromProcessed = res.lastCaptureUtc;
        }
      }
    }

    acquisitionSuccess = true;
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "get_new_files", cat, null, error);
  } finally {
    let captureForQueue = latestCaptureFromProcessed;

    if (!captureForQueue) {
      captureForQueue =
        (await readLastCaptureTimestamp(perm_file_path)) || capture_datetime;
    }

    try {
      await add_to_online_queue(job_id, run_log, {
        id: system.system_id,
        capture_datetime: captureForQueue,
        successful_acquisition: acquisitionSuccess,
        data_source: "mmb"
      });
    } catch (queueError) {
      console.log(queueError);
      await addLogEvent(E, run_log, "get_new_files", cat, null, queueError);
    }
  }
}

async function listFiles(dir, absolute = false) {
  const entries = await fsp.readdir(dir, { withFileTypes: true });
  return entries
    .filter((e) => e.isFile())
    .map((e) => (absolute ? path.join(dir, e.name) : e.name))
    .sort();
}

// parse DDMMYY from ...-dayDDMMYY.dat -> "YYYYMMDD" (string) or null
function yyyymmddFromName(name) {
  const m = name.match(/-day(\d{6})\.dat$/i);
  if (!m) return null;
  const dd = +m[1].slice(0, 2);
  const mm = +m[1].slice(2, 4);
  const yy = +m[1].slice(4, 6);
  if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
  const year = yy <= 69 ? 2000 + yy : 1900 + yy;
  const dt = new Date(year, mm - 1, dd);
  if (
    dt.getFullYear() !== year ||
    dt.getMonth() !== mm - 1 ||
    dt.getDate() !== dd
  )
    return null;
  return `${year}${String(mm).padStart(2, "0")}${String(dd).padStart(2, "0")}`;
}

function findLastEndCaptureTimestamp(text) {
  const regex = /\[END CAPTURE BLOCK\s*:\s*([^\]]+)\]/gi;
  let match;
  let last = null;
  while ((match = regex.exec(text)) !== null) {
    last = match[1].trim();
  }
  return last;
}

async function extractEndCaptureTimestamp(filePath) {
  try {
    const contents = await fsp.readFile(filePath, "utf8");
    return findLastEndCaptureTimestamp(contents);
  } catch (error) {
    if (error.code !== "ENOENT") {
      console.log(error);
    }
    return null;
  }
}

async function readLastCaptureTimestamp(filePath) {
  let handle;
  try {
    handle = await fsp.open(filePath, "r");
    const stats = await handle.stat();
    if (stats.size === 0) return null;

    const chunkSize = Math.min(stats.size, 128 * 1024);
    const buffer = Buffer.alloc(chunkSize);
    await handle.read(buffer, 0, chunkSize, stats.size - chunkSize);
    return findLastEndCaptureTimestamp(buffer.toString("utf8"));
  } catch (error) {
    if (error.code === "ENOENT") {
      return null;
    }
    console.log(error);
    return null;
  } finally {
    if (handle) {
      await handle.close();
    }
  }
}

// assumes yyyymmddFromName(name) = (DDMMYY -> "YYYYMMDD")

async function concatFilesInOrder(srcDir, files, destPath, getKey) {
  const srcAbs = path.resolve(srcDir);
  const destAbs = path.resolve(destPath);

  if (destAbs.startsWith(srcAbs + path.sep)) {
    throw new Error(
      `Destination must not be inside source directory:\n  src=${srcAbs}\n  dest=${destAbs}`
    );
  }

  const sorted = [...files].sort((a, b) => {
    const da = yyyymmddFromName(a);
    const db = yyyymmddFromName(b);
    if (da && db) return da === db ? a.localeCompare(b) : da.localeCompare(db);
    if (da && !db) return -1;
    if (!da && db) return 1;
    return a.localeCompare(b);
  });

  if (sorted.length === 0) {
    console.log("LAST_FILE: <none>");
    return { count: 0, first: null, last: null, lastCaptureUtc: null };
  }

  const lastFile = sorted[sorted.length - 1];
  console.log("LAST_FILE:", lastFile);

  await fsp.mkdir(path.dirname(destAbs), { recursive: true });

  // append mode (persistent log)
  const out = fs.createWriteStream(destAbs, { flags: "a" });
  let lastSuccess = null;
  let lastCaptureUtc = null;

  try {
    for (const name of sorted) {
      const srcFile = path.join(srcAbs, name);

      const captureTimestamp = await extractEndCaptureTimestamp(srcFile);
      if (captureTimestamp) {
        lastCaptureUtc = captureTimestamp;
      }

      // append this file
      await pipeline(fs.createReadStream(srcFile), out, { end: false });

      // ensure separator hits the stream before we mark Redis
      await new Promise((res, rej) =>
        out.write("\n", (e) => (e ? rej(e) : res()))
      );

      // delete the source file
      try {
        await fsp.unlink(srcFile);
      } catch {}

      // ✅ update bookmark AFTER successful append (and optional delete)
      await update_last_file(getKey, name);

      lastSuccess = name;
    }
  } finally {
    await new Promise((res) => out.end(res));
  }

  return { count: sorted.length, last: lastSuccess, lastCaptureUtc };
}

// [START CAPTURE BLOCK : 2025-06-07T01:45:00Z]

// [END CAPTURE BLOCK : 2025-06-07T01:45:00Z]

module.exports = get_new_files;
