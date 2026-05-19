const exec_phil_cv_data_grab = require("../../../read/exec-phil_cv_data_grab");
const exec_phil_cv_unzip = require("../../../read/exec-phil_cv_unzip");
const { get_hhm, getHhmCreds } = require("../../../sql/qf-provider");
const { list_new_phil_cv_files } = require("../../../util");
const { decrypt_string } = require("../../../util/encrypt/decrypt");
const { get_previous_dir } = require("../../../redis/redis_helpers");
const { file_exists } = require("../../../util");
const { v4: uuidv4 } = require("uuid");
const path = require("path");

const [
  addLogEvent,
  ,
  ,
  ,
  ,
  startTimer,
  endTimer,
] = require("../../../utils/logger/log");
const { systemLogShape } = require("../../../util/log_shapes");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf },
} = require("../../../utils/logger/enums");

async function get_philips_cv_data(run_log, capture_datetime, override_systems = null) {
  const child_processes = [];
  try {
    await addLogEvent(I, run_log, "get_philips_cv_data", cal, null, null);
    const manufacturer = "Philips";
    const modality = "CV/IR";
    startTimer(run_log, "philips_cv.sql_fetch");
    const systems = override_systems
      ? override_systems
      : await get_hhm([manufacturer, modality]);
    const credentials = await getHhmCreds([manufacturer, modality]);
    await endTimer(run_log, "philips_cv.sql_fetch", {
      system_count: systems.length,
      credential_count: credentials.length,
    });

    for (const system of systems) {
      const job_id = uuidv4();
      child_processes.push(
        async () =>
          await run_phil_cv(
            job_id,
            run_log,
            system,
            credentials,
            capture_datetime
          )
      );
    }
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "get_philips_cv_data", cat, null, error);
  }
  try {
    // CREATE AN ARRAY OF PROMISES BY CALLING EACH child_process FUNCTION
    const promises = child_processes.map((child_process) => child_process());

    // AWAIT PROMISIS
    startTimer(run_log, "philips_cv.promise_all_wait");
    await Promise.all(promises);
    await endTimer(run_log, "philips_cv.promise_all_wait", {
      child_process_count: child_processes.length,
    });
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "get_ge_cv_data", cat, null, error);
  }
}

async function run_phil_cv(
  job_id,
  run_log,
  system,
  credentials,
  capture_datetime
) {
  await addLogEvent(I, run_log, "run_phil_cv", cal, { job_id, system: systemLogShape(system) }, null);
  const daily_dir_acqu_script = `./read/sh/Philips/${system.acquisition_script}`;
  const lod_dir_acqu_script = `./read/sh/Philips/phil_cv_21_lod.sh`;
  const parse_event_zip = `./read/sh/Philips/parse_event_zip.sh`;
  const fallback = path.join(process.cwd(), "files");

  if (!system.host_ip || !system.credentials_group) {
    let note = {
      job_id,
      system: system.id,
      host_ip: system.host_ip,
      system: system.credentials_group,
      message: "Missing host_ip and credentials_group",
    };
    await addLogEvent(I, run_log, "run_phil_cv", det, note, null);
  }

  const system_creds = credentials.find((credential) => {
    if (credential.id == system.credentials_group) return true;
  });

  const user = decrypt_string(system_creds.user_enc);
  const pass = decrypt_string(system_creds.password_enc);

  // REDIS VALUE: GET PREVIOUS DAILY DIR PULLED FROM HOST STORED IN REDIS - Example: daily_2023_06_19 or daily_20230619
  const last_aquired_dir = await get_previous_dir(
    job_id,
    run_log,
    system.id,
    "last_phil_cv_daily"
  );

  // REDIS VALUE: GET PREVIOUS LOD DIR PULLED FROM HOST STORED IN REDIS - Example: lod_20231114_0953
  const last_lod_file = await get_previous_dir(
    job_id,
    run_log,
    system.id,
    "last_phil_cv_lod"
  );

  // REQUIRES HOST CONNECTIVITY: PASS IN PREVIOUS FILE NAMES AND RETURN 1 OR MORE LOD OR DAILY DIRs TO PULL
  const { daily_files_to_pull, lod_files_to_pull } =
    await list_new_phil_cv_files(
      job_id,
      run_log,
      system.id,
      system.host_ip,
      last_aquired_dir,
      last_lod_file,
      user,
      pass,
      system,
      capture_datetime
    );
  /* 
  console.log("\nPAIRED DOWN LIST:");

  console.log("\ndaily_files_to_pull");
  console.log(daily_files_to_pull);

  console.log("\nlod_files_to_pull");
  console.log(lod_files_to_pull);
 */
  // CHECK FOR EventLog.txe within last_aquired_dir
  /* if (process.env.RUN_ENV === "dev") {
    system.debian_server_path = `/home/matt-teixeira/hep3/hhm_data_acquisition/files/${system.id}`;
  } */
  console.log("\nsystem.debian_server_path");
  system.debian_server_path = `${fallback}/files/${system.id}`;
  console.log(system.debian_server_path);

  // BACKFILL ANY CURRENT DATA NOT PRESENT
  // WILL RUN EVEN IN ABSENCE OF daily_files_to_pull AND lod_files_to_pull AS A DOUBLE CHECK ON CURRENT STATE
  if (last_aquired_dir) {
    // 1) CHECK FOR PRESENCE OF Event.zip WITHIN last_aquired_dir
    const event_zip_there = await file_exists(
      system.debian_server_path,
      `${last_aquired_dir}/Event.zip`
    );
    // 2) IF Event.zip NOT PRESENT: PULL DIR FROM HOST AGAIN.
    // Track whether the re-pull succeeded: a truthy return means the fetch
    // completed cleanly; a falsy return means it was killed (timeout) or
    // errored, leaving the zip partial. If we didn't need to re-pull, treat
    // the existing Event.zip as valid (repull_ok = true).
    let repull_ok = true;
    if (!event_zip_there) {
      const result = await exec_phil_cv_data_grab(
        job_id,
        run_log,
        system.id,
        daily_dir_acqu_script,
        system,
        [system.host_ip, user, pass, last_aquired_dir],
        "last_phil_cv_daily",
        capture_datetime
      );
      // Contract: exec_phil_cv_data_grab returns `false` or `null` on any
      // failure path (timeout kill, connection error, extraction error,
      // unknown exception); a successful fetch returns `stdout` (a string,
      // which can legitimately be empty when lftp emits no stdout).
      repull_ok = result !== false && result !== null;
    }

    // 1) CHECK FOR PRESENCE OF EventLog.txe WITHIN last_aquired_dir
    const event_log_there = await file_exists(
      system.debian_server_path,
      `${last_aquired_dir}/EventLog.txe`
    );

    // Skip unzip if we just attempted a re-pull that was killed/errored:
    // the Event.zip is partial and unzip would guarantee-fail, generating
    // noise and potentially producing a misleading EventLog.txe from a
    // stale backup zip found by parse_event_zip.sh's recursive find.
    if (!event_log_there && repull_ok) {
      await exec_phil_cv_unzip(
        job_id,
        run_log,
        system.id,
        parse_event_zip,
        system,
        last_aquired_dir
      );
    }
  }

  // TESTING VARS
  // const daily_files_to_pull = ["daily_2025_05_06", "daily_2025_05_08"];
  // const lod_files_to_pull = null;

  // GET ALL DIRECTORIES FROM HOST BASED ON DELTA LIST FROM daily_files_to_pull. EXAMPLE: ["daily_2025_05_06", "daily_2025_05_08"]
  if (daily_files_to_pull !== null && daily_files_to_pull !== false) {
    // Only unzip dirs whose fetch completed cleanly. Contract:
    // exec_phil_cv_data_grab returns `false` or `null` on any failure path
    // (timeout kill, connection error, extraction error, unknown exception).
    // A successful fetch returns `stdout` - a STRING, which can legitimately
    // be empty (lftp often produces no stdout even on success). So we check
    // for the explicit failure sentinels rather than falsiness.
    const successful_fetches = [];
    for await (const file of daily_files_to_pull) {
      const result = await exec_phil_cv_data_grab(
        job_id,
        run_log,
        system.id,
        daily_dir_acqu_script,
        system,
        [system.host_ip, user, pass, file],
        "last_phil_cv_daily",
        capture_datetime
      );
      if (result !== false && result !== null) successful_fetches.push(file);
    }

    // NOTE: LOOP THROUGH EACH DIRECTORY BROUGHT OVER FROM HOST, UNZIP AND FORMAT INTO EventLog.txe
    for await (const daily_dir of successful_fetches) {
      await exec_phil_cv_unzip(
        job_id,
        run_log,
        system.id,
        parse_event_zip,
        system,
        daily_dir
      );
    }
  }

  // NOTE: PULL LOD DIRECTORIES FROM HOST
  if (lod_files_to_pull !== null && lod_files_to_pull !== false) {
    for await (const file of lod_files_to_pull) {
      await exec_phil_cv_data_grab(
        job_id,
        run_log,
        system.id,
        lod_dir_acqu_script,
        system,
        [system.host_ip, user, pass, file],
        "last_phil_cv_lod",
        capture_datetime
      );
    }
  }

  // NOTE: PULLS TRACE DIRECTORIES FROM HOST
  // LARGE FILE SET - STOP PROCESS IF SLOW HOST NETWORK
  /*
  if (daily_files_to_pull !== null) {
    for await (const file of daily_files_to_pull) {
      await get_trace_files(
        job_id,
        run_log,
        system,
        user,
        pass,
        file,
        capture_datetime
      );
    }
  }
  */
}

async function get_trace_files(
  job_id,
  run_log,
  system,
  user,
  pass,
  file,
  capture_datetime
) {
  let note = {
    job_id,
    system: systemLogShape(system),
  };

  await addLogEvent(I, run_log, "get_trace_files", cal, note, null);
  const daily_dir_acqu_script = `./read/sh/Philips/phil_cv_21_trace.sh`;

  await exec_phil_cv_data_grab(
    job_id,
    run_log,
    system.id,
    daily_dir_acqu_script,
    system,
    [system.host_ip, user, pass, file],
    "last_phil_cv_daily",
    capture_datetime
  );
}

module.exports = { get_philips_cv_data, run_phil_cv };
