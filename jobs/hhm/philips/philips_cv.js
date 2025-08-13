const exec_phil_cv_data_grab = require("../../../read/exec-phil_cv_data_grab");
const exec_phil_cv_unzip = require("../../../read/exec-phil_cv_unzip");
const { get_hhm, getHhmCreds } = require("../../../sql/qf-provider");
const { decryptString, list_new_phil_cv_files } = require("../../../util");
const { get_previous_dir } = require("../../../redis/redis_helpers");
const { file_exists } = require("../../../util");
const { v4: uuidv4 } = require("uuid");

const [addLogEvent] = require("../../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../../utils/logger/enums");

async function get_philips_cv_data(run_log, capture_datetime) {
  const child_processes = [];
  try {
    await addLogEvent(I, run_log, "get_philips_cv_data", cal, null, null);
    const manufacturer = "Philips";
    const modality = "CV/IR";
    const systems = await get_hhm([manufacturer, modality]);
    const credentials = await getHhmCreds([manufacturer, modality]);

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
    await Promise.all(promises);
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
  await addLogEvent(I, run_log, "run_phil_cv", cal, { job_id, system }, null);
  const daily_dir_acqu_script = `./read/sh/Philips/${system.acquisition_script}`;
  const lod_dir_acqu_script = `./read/sh/Philips/phil_cv_21_lod.sh`;
  const parse_event_zip = `./read/sh/Philips/parse_event_zip.sh`;

  if (!system.host_ip || !system.credentials_group) {
    let note = {
      job_id,
      system: system.id,
      host_ip: system.host_ip,
      system: system.credentials_group,
      message: "Missing host_ip and credentials_group"
    };
    await addLogEvent(I, run_log, "run_phil_cv", det, note, null);
  }

  const system_creds = credentials.find((credential) => {
    if (credential.id == system.credentials_group) return true;
  });

  const user = decryptString(system_creds.user_enc);
  const pass = decryptString(system_creds.password_enc);

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
  if (process.env.RUN_ENV === "dev") {
    system.debian_server_path = `/home/matt-teixeira/hep3/hhm_data_acquisition/files/${system.id}`;
  }

  // BACKFILL ANY CURRENT DATA NOT PRESENT
  // WILL RUN EVEN IN ABSENCE OF daily_files_to_pull AND lod_files_to_pull AS A DOUBLE CHECK ON CURRENT STATE
  if (last_aquired_dir) {
    // 1) CHECK FOR PRESENCE OF Event.zip WITHIN last_aquired_dir
    const event_zip_there = await file_exists(
      system.debian_server_path,
      `${last_aquired_dir}/Event.zip`
    );
    // 2) IF Event.zip NOT PRESENT: PULL DIR FROM HOST AGAIN
    if (!event_zip_there) {
      await exec_phil_cv_data_grab(
        job_id,
        run_log,
        system.id,
        daily_dir_acqu_script,
        system,
        [system.host_ip, user, pass, last_aquired_dir],
        "last_phil_cv_daily",
        capture_datetime
      );
    }

    // 1) CHECK FOR PRESENCE OF EventLog.txe WITHIN last_aquired_dir
    const event_log_there = await file_exists(
      system.debian_server_path,
      `${last_aquired_dir}/EventLog.txe`
    );

    if (!event_log_there) {
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
    for await (const file of daily_files_to_pull) {
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

    // NOTE: LOOP THROUGH EACH DIRECTORY BROUGHT OVER FROM HOST, UNZIP AND FORMAT INTO EventLog.txe
    for await (const daily_dir of daily_files_to_pull) {
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
    system
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
