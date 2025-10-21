const db = require("../db/pgPool");
const { log } = require("../logger");
const {
  system_ip,
  system_data,
  system_data_logs,
  pg_table,
  update_date_time,
  get_mod_man,
  get_hhm_data,
  get_hhm_creds,
  one_system_data,
  phil_mri_host,
  get_althea_env_configs
} = require("./sql");

// GENERIC LOGGER FOR ANY QF CALL
const logQf = async (uuid, fn, qfArgs) => {
  await log("info", uuid, "sme", fn, `FN CALL`, {
    qfArgs: qfArgs
  });
};

const getSystemIpAddress = async (uuid, sme) => {
  await logQf(uuid, "getSystemIpAddress", sme);
  return db.any(system_ip.ipAddress, sme);
};

const get_phil_mri_systems = async () => {
  await logQf("ID", "get_phil_mri_systems", "n/a");
  return await db.any(system_data.smeNumber);
};

const get_phil_mri_systems_log = async () => {
  await logQf("ID", "get_phil_mri_systems", "n/a");
  return await db.any(system_data_logs.systems);
};

const getPgTable = async (uuid, sme) => {
  await logQf(uuid, "getPgTable", sme);
  return db.one(pg_table.smeNumber, sme);
};

const updateDateTime = async (argsArray) => {
  try {
    return db.any(update_date_time.dateTime, argsArray);
  } catch (error) {
    await log("error", uuid, argsArray[2], "updateDateTime", `FN CALL`);
  }
};

const getModMan = async (sme) => {
  try {
    return await db.one(get_mod_man.smeNumber, sme);
  } catch (error) {
    console.log(error);
  }
};

const get_hhm = async (argsArray) => {
  try {
    return db.any(get_hhm_data.systems, argsArray);
  } catch (error) {
    console.log(error);
    await log("error", "uuid", "sme", "get_hhm_data", `FN CALL`);
  }
};

const getHhmCreds = async (argsArray) => {
  try {
    return db.any(get_hhm_creds.hhm_credentials, argsArray);
  } catch (error) {
    console.log(error);
    await log("error", "uuid", "sme", "getHhmCreds", `FN CALL`);
  }
};

const getOneSystem = async (argsArray) => {
  try {
    return db.any(one_system_data.system, argsArray);
  } catch (error) {
    console.log(error);
  }
};

const get_phil_mri_host = async (argsArray) => {
  try {
    return db.any(phil_mri_host.systems, argsArray);
  } catch (error) {
    console.log(error);
    await log("error", "uuid", "sme", "get_phil_mri_host", `FN CALL`);
  }
};

const get_althea_env_systems = async () => {
  try {
    return db.any(get_althea_env_configs.systems);
  } catch (error) {
    console.log(error);
    await log("error", "uuid", "sme", "get_hhm_data", `FN CALL`);
  }
};

module.exports = {
  getSystemIpAddress,
  get_phil_mri_systems,
  get_phil_mri_systems_log,
  getPgTable,
  updateDateTime,
  getModMan,
  get_hhm,
  getHhmCreds,
  getOneSystem,
  get_phil_mri_host,
  get_althea_env_systems
};
