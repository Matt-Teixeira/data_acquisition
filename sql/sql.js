const { QueryFile } = require("pg-promise");
const { join: joinPath } = require("path");

// HELPER FOR LINKING TO EXTERNAL QUERY FILES
const sql = (file) => {
  const fullPath = joinPath(__dirname, file); // GENERATING FULL PATH;
  return new QueryFile(fullPath, { minify: true });
};

module.exports = {
  system_ip: {
    ipAddress: sql("system/ip-address.sql"),
  },
  system_data: {
    smeNumber: sql("system/phil_mri_systems.sql"),
  },
  system_data_logs: {
    systems: sql("system/phil_mri_systems_log.sql"),
  },
  pg_table: {
    smeNumber: sql("system/getPgTable.sql"),
  },
  update_date_time: {
    dateTime: sql("system/updateDateTime.sql"),
  },
  get_mod_man: {
    smeNumber: sql("system/get_mod_man.sql"),
  },
  get_hhm_data: {
    systems: sql("system/get_hhm_data.sql"),
  },
  get_hhm_creds: {
    hhm_credentials: sql("system/hhm_credentials.sql"),
  },
  one_system_data: {
    system: sql("system/one_system.sql"),
  },
  phil_mri_host: {
    systems: sql("system/get_phil_mri_host.sql"),
  },
  get_althea_env_configs: {
    systems: sql("system/get_althea_env_configs.sql"),
  }
};
