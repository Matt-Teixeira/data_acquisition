const exec_phil_cv_data_grab = require("../../../read/exec-phil_cv_data_grab");
const { getHhmCreds } = require("../../../sql/qf-provider");
const { decryptString, list_new_phil_cv_files } = require("../../../util");
const { get_previous_dir } = require("../../../redis/redis_helpers");
const [addLogEvent] = require("../../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../../utils/logger/enums");

async function get_philips_cv_data(
  job_id,
  run_log,
  system,
  capture_datetime,
  ip_reset
) {
  const note = { job_id, system_id: system.id };
  try {
    await addLogEvent(I, run_log, "get_philips_cv_data", cal, note, null);
    const manufacturer = "Philips";
    const modality = "CV/IR";
    const credentials = await getHhmCreds([manufacturer, modality]);

    const daily_dir_acqu_script = `./read/sh/Philips/${system.acquisition_script}`;
    const lod_dir_acqu_script = `./read/sh/Philips/phil_cv_21_lod.sh`;

    const system_creds = credentials.find(
      (credential) => credential.id === system.credentials_group
    );

    const user = decryptString(system_creds.user_enc);
    const pass = decryptString(system_creds.password_enc);

    const last_aquired_dir = await get_previous_dir(
      job_id,
      run_log,
      system.id,
      "last_phil_cv_daily"
    );
    // Example: daily_2023_06_19 or daily_20230619

    const last_lod_file = await get_previous_dir(
      job_id,
      run_log,
      system.id,
      "last_phil_cv_lod"
    );
    // Example: lod_20231114_0953

    // Pass last_aquired_dir to list new files post last_aquired_dir
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
        capture_datetime,
        true
      );

    if (daily_files_to_pull !== null) {
      for await (const file of daily_files_to_pull) {
        await exec_phil_cv_data_grab(
          job_id,
          run_log,
          system.id,
          daily_dir_acqu_script,
          system,
          [system.host_ip, user, pass, file],
          "last_phil_cv_daily",
          capture_datetime,
          ip_reset
        );
      }
    }

    if (lod_files_to_pull !== null) {
      for await (const file of lod_files_to_pull) {
        await exec_phil_cv_data_grab(
          job_id,
          run_log,
          system.id,
          lod_dir_acqu_script,
          system,
          [system.host_ip, user, pass, file],
          "last_phil_cv_lod",
          capture_datetime,
          ip_reset
        );
      }
    }
  } catch (error) {
    await addLogEvent(E, run_log, "get_philips_cv_data", cat, note, error);
  }
}

module.exports = get_philips_cv_data;
