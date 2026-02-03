const exec_list_dirs = require("../../read/exec-list_dirs");
const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");

async function list_new_phil_cv_files(
  job_id,
  run_log,
  sme,
  ip_address,
  previous_daily_file,
  previous_lod_file,
  user,
  pass,
  system,
  capture_datetime,
  ip_reset = false
) {
  let note = {
    job_id,
    system_id: sme,
    previous_daily_file,
    previous_lod_file
  };

  await addLogEvent(I, run_log, "list_new_phil_cv_files", cal, note, null);

  // Extract port from acquisition_script name (e.g., "phil_cv_21.sh" → "21")
  const port_match = system.acquisition_script.match(/phil_cv_(\d+)/);
  const port = port_match ? port_match[1] : "21";

  const list_path = `./read/sh/Philips/phil_cv_${port}_file_list.sh`;

  const files_list = await exec_list_dirs(
    job_id,
    run_log,
    sme,
    list_path,
    system,
    [ip_address, user, pass, `${process.env.DEV_HHM_FILES}/${sme}`],
    capture_datetime,
    ip_reset
  );

  // IF files_list IS null/false, BREAK EARLY DUE TO POSSIBLE CONNECTION ISSUE
  if (!files_list) {
    let daily_files_to_pull = null;
    let lod_files_to_pull = null;
    return { daily_files_to_pull, lod_files_to_pull };
  }

  const daily_files_to_pull = await list_new_daily_files(
    job_id,
    run_log,
    sme,
    previous_daily_file,
    files_list
  );

  // IF daily_files_to_pull IS null, BREAK EARLY DUE TO CONNECTION ISSUE
  /* if (!daily_files_to_pull) {
    let lod_files_to_pull = null;
    return { daily_files_to_pull, lod_files_to_pull };
  } */

  const lod_files_to_pull = await list_new_lod_files(
    job_id,
    run_log,
    sme,
    previous_lod_file,
    files_list
  );

  return { daily_files_to_pull, lod_files_to_pull };
}

async function list_new_daily_files(
  job_id,
  run_log,
  sme,
  previous_daily_file,
  files_list
) {
  let note = {
    job_id,
    system_id: sme,
    previous_daily_file
  };

  await addLogEvent(I, run_log, "list_new_daily_files", cal, note, null);

  const daily_re = /daily_\d{4}_\d{2}_\d{2}|daily_\d{4}\d{2}\d{2}/;

  const dirs = files_list.split(" ");
  if (!dirs) return null;

  // Runs if block if no Redis reference - returns last (newest) valid dir for this system
  if (!previous_daily_file) {
    let last_file = "";
    for (let i = dirs.length - 1; i > 0; i--) {
      const matching_file = daily_re.test(dirs[i]);
      if (matching_file) {
        last_file = dirs[i];
        last_file = last_file.trim();
        break;
      }
    }
    return [last_file];
  }

  // BEGIN: identifying daily directory to pull
  const last_file_index = dirs.indexOf(previous_daily_file);

  let reduced_files = dirs.slice(last_file_index + 1, dirs.length - 1);

  const last_files = reduced_files.filter((file) => file.match(daily_re));

  // END: identifying daily directory to pull

  // BEGIN: determin wether or not to pull lod file
  // ???
  // END: determin wether or not to pull lod file

  if (!last_files.length) return null;
  return last_files;
}

async function list_new_lod_files(
  job_id,
  run_log,
  sme,
  previous_lod_file,
  files_list
) {
  let note = {
    job_id,
    system_id: sme,
    previous_lod_file
  };

  await addLogEvent(I, run_log, "list_new_lod_files", cal, note, null);

  const lod_re = /lod.*/;

  const dirs = files_list.split(" ");
  if (!dirs) return null;

  // Runs if block if no Redis reference - returns oldest valid lod dir for this system
  if (!previous_lod_file) {
    let first_lod_file = "";
    for (let i = 0; i < dirs.length; i++) {
      const matching_file = lod_re.test(dirs[i]);
      if (matching_file) {
        first_lod_file = dirs[i];
        first_lod_file = first_lod_file.trim();
        break;
      }
    }

    // account for no lod dir
    if (first_lod_file === "") return null;

    return [first_lod_file];
  }

  // Group lod directories

  const lod_dirs = [];

  for (let i = 0; i < dirs.length; i++) {
    const matching_file = lod_re.test(dirs[i]);
    if (matching_file) {
      lod_dirs.push(dirs[i]);
    }
  }

  let prev_lod_index = lod_dirs.indexOf(previous_lod_file);

  // Account no lod
  if (lod_dirs.length < 1) {
    let note = {
      job_id,
      message: "Previous lod file not found",
      previous_lod_file
    };
    await addLogEvent(I, run_log, "list_new_lod_files", det, note, null);
    return null;
  }

  // Account for not found previous lod dir
  // prev_lod_index < 0 MEANS PREVIOUS FILE NOT FOUND - We want to pull something so
  if (prev_lod_index < 0) {
    const new_lod_file = lod_dirs[lod_dirs.length - 1];
    return [new_lod_file];
  }

  const new_lod_file = lod_dirs.slice(prev_lod_index + 1);

  if (!new_lod_file.length) return null;

  return new_lod_file;
}

module.exports = list_new_phil_cv_files;
