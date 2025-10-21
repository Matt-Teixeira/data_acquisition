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

const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");

async function get_new_files(job_id, run_log, system, capture_datetime) {
  const list_path = "./read/sh/althea-env/list_files.sh";
  const pull_path = "./read/sh/althea-env/althea_server_pull.sh";

  const perm_file_name = `${system.system_id}.v3_ge_mm3.log`;
  const dir = path.dirname(system.debian_server_path);
  const perm_file_path = path.join(dir, perm_file_name);

  console.log(perm_file_path);

  let note = {
    job_id,
    system_id: system.system_id
  };

  await addLogEvent(I, run_log, "get_new_files", cal, note, null);

  try {
    const files = await exec_list_files(run_log, list_path, [
      system.user_id,
      system.host_ip,
      system.system_id
    ]);

    // NO NEED TO DO ANY WORK
    if (files.length === 0) return;

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

    // DEV CHANGES FOR TESTING: REMOVE OR COMMENT OUT
    if (process.env.RUN_ENV === "dev") {
      system.debian_server_path =
        "/home/matt-teixeira/hep3/hhm_data_acquisition/files/SME20288_temp";
    }

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

      // TODO
      // THERE EXSISTS SORTED FILES TO PROCESS, BUT COULD NOT FIND "last_file_processed" REFERENCED IN "sorted" ARRAY
      // PROCESS ALL IN "sorted" ARRAY AND CREATE NEW "last_file_processed" REFERENCE IN REDIS

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
          perm_file_path, // replace with perm_file_path when out of dev  "/home/matt-teixeira/hep3/hhm_data_acquisition/files/SME20288.v3_ge_mm3.log"
          getKey
        );

        console.log("\nres");
        console.log(res);
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
        perm_file_path,  // "/home/matt-teixeira/hep3/hhm_data_acquisition/files/SME20288.v3_ge_mm3.log"
        getKey
      );

      console.log(res);
      console.log("\n END OF ALL FILES PROCESSING");
    }
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "get_new_files", cat, null, error);
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
    return { count: 0, first: null, last: null };
  }

  const lastFile = sorted[sorted.length - 1];
  console.log("LAST_FILE:", lastFile); // <-- save this to Redis on your side

  await fsp.mkdir(path.dirname(destAbs), { recursive: true });

  // append mode (persistent log)
  const out = fs.createWriteStream(destAbs, { flags: "a" });

  try {
    for (const name of sorted) {
      const srcFile = path.join(srcAbs, name);

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

  return { count: sorted.length, last: lastSuccess };
}

// [START CAPTURE BLOCK : 2025-06-07T01:45:00Z]

// [END CAPTURE BLOCK : 2025-06-07T01:45:00Z]

module.exports = get_new_files;
