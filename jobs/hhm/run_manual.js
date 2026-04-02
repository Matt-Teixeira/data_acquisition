const exec_hhm_data_grab = require("../../read/exec-hhm_data_grab");
const exec_phil_cv_data_grab = require("../../read/exec-phil_cv_data_grab");
const { getHhmCreds, getOneSystem } = require("../../sql/qf-provider");
const { decrypt_string } = require("../../util/encrypt/decrypt");
const { list_new_files } = require("../../util");
const { get_last_dir_date } = require("../../redis/redis_helpers");
const { run_phil_cv } = require("./philips/philips_cv");

async function run_system_manual(
  run_log,
  systemArray,
  man_mod,
  capture_datetime
) {
  try {
    const credentials = await getHhmCreds(man_mod);

    // Can accept multiple system args in array
    for (const sys of systemArray) {
      const system = await getOneSystem(sys);
      console.log(system);

      if (!system) {
        console.log("NO CONFIG!! " + system[0].id);
        continue;
      }

      // START Credential Acquisition

      let user = "";
      let pass = "";
      if (credentials.length) {
        for (const cred of credentials) {
          if (system[0].credentials_group == cred.id) {
            user = decrypt_string(cred.user_enc);
            pass = decrypt_string(cred.password_enc);
          }
        }
        if ((man_mod[0] !== "Siemens" && user === "") || pass === "") {
          throw new Error("NO CREDENTIALS FOUND");
        }
      }

      // END Credential Acquisition

      if (
        system[0].manufacturer === "Philips" &&
        system[0].modality === "CV/IR"
      ) {
        await run_phil_cv(run_log, system[0], credentials, capture_datetime);
        return;
      }

      const path = `./read/sh/${man_mod[0]}/${system[0].acquisition_script}`;

      // { START: Philips CV Specific Code

      if (man_mod[0] === "Philips" && man_mod[1] === "CV/IR") {
        // Get last dir from Redis
        const last_aquired_dir = await get_last_dir_date(system[0].id);
        console.log("\n last_aquired_dir");
        console.log(last_aquired_dir);
        console.log(user);
        console.log(pass);
        // Example: daily_2023_06_19 or daily_20230619

        // Pass last_aquired_dir to list new files post last_aquired_dir
        const new_files = await list_new_files(
          run_log,
          system[0].id,
          system[0].ip_address,
          last_aquired_dir,
          user,
          pass,
          system[0]
        );

        console.log("\n new_files");
        console.log(new_files);

        if (new_files === null) {
          //LOG
          console.log("No new files for: " + system[0].id);
          return;
        }
        if (new_files === false) {
          console.log("System needs tunnel reset: " + system[0].id);
          return;
        }
        // { END: Philips CV Specific Code

        // Remove last (file) arg if not running Philips CV
        for await (let file of new_files) {
          await exec_phil_cv_data_grab(run_log, system[0].id, path, system[0], [
            system[0].host_ip,
            user,
            pass,
            file
          ]);
        }
        return;
      }

      if (man_mod[0] === "Siemens") {
        await exec_hhm_data_grab(run_log, system[0].id, path, system[0], [
          system[0].host_ip
        ]);
      } else {
        await exec_hhm_data_grab(run_log, system[0].id, path, system[0], [
          system[0].host_ip,
          user,
          pass
        ]);
      }
    }
  } catch (error) {
    console.log("ERROR IN MANUAL CATCH");
    console.log(error);
  }
}

module.exports = run_system_manual;
/* 
Example hhm_config
{
  "file_path": "/opt/files/SME14520/hhm", 
  "modality": "CT", 
  "log_rotation": "v_2", "run_group": 1, 
  "data_acquisition": {"script": "ge_ct_data_grab.sh", "hhm_credentials_group": "1"}
}
 */
