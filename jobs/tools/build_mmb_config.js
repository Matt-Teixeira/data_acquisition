const {
  get_mmb_configs,
  insert_mmb_acqu_config,
  update_edu_config_array,
  insert_mmb_edu_config,
  update_mag_config_array,
  insert_mmb_mag_config
} = require("../../sql/qf-provider");

async function mmb_configs() {
  const systems = await get_mmb_configs();
  for (let system of systems) {
    const id = system.id;
    const ip = system.mmb_config.ssh.ip_address;
    const method = "rsync";
    const host = system.mmb_config.ssh.host;
    const user = system.mmb_config.ssh.user_id;

    if (!system.mmb_config.rpp_configs) continue;

    //if (id === "SME15812") {
    try {
      await insert_mmb_acqu_config([id, ip, method, host, user]);

      for (let conf of system.mmb_config.rpp_configs) {
        const edu_test = /edu/;
        const is_edu = edu_test.test(conf.mmbScript);

        if (is_edu) {
          const script = conf.mmbScript;
          const table = conf.pgTable;
          const schedule = conf.schedule;

          await insert_mmb_edu_config([id, script, table, schedule]);

          for await (let re of conf.regexModels) {
            console.log(re);
            await update_edu_config_array([re, id]);
          }
        } else {
          const script = conf.mmbScript;
          const table = conf.pgTable;
          const schedule = conf.schedule;

          await insert_mmb_mag_config([id, script, table, schedule]);
          for await (let re of conf.regexModels) {
            console.log(re);
            await update_mag_config_array([re, id]);
          }
        }
      }
    } catch (error) {
      console.log(error);
    }
    //}
  }
}

function array_to_str(array) {
  let reg_str = "";

  for (let i = 0; i < array.length; i++) {
    if (array.length - 1 === i) {
      const s = `${array[i]}`;
      reg_str += s;
      continue;
    }
    const s = `${array[i]}, `;
    reg_str += s;
  }

  return reg_str;
}

module.exports = mmb_configs;

/* 
console.log(system.id);
      console.log(system.mmb_config.ssh);
      console.log(system.mmb_config.rpp_configs);
*/
