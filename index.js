("use strict");
require("dotenv").config();
const pgp = require("pg-promise")();
const update_db = require("./util/encrypt/old_to_new_process");
const rsync_philips_mri = require("./jobs/philips_mri/rsync_philips-mri");
const onBootMMB = require("./jobs/mmb");
const get_hhm_data = require("./jobs/hhm");
const { get_althea_env_data } = require("./jobs/server_hop");
const reset_tunnel = require("./jobs/tunnel_reset");
const get_ip_sec_table = require("./jobs/tools/ip_sec");
const {
  captureDatetime,
  insertHeartbeat,
  increment_system_reset_totals,
} = require("./util");
const update_pg_ipsec = require("./utils/vpn/update-pg-ipsec-table");
const [
  addLogEvent,
  writeLogEvents,
  dbInsertLogEvents,
  makeAppRunLog,
] = require("./utils/logger/log");
const {
  type: { I, E },
  tag: { cal, det, cat },
} = require("./utils/logger/enums");

async function runJob(run_log, run_group, schedule, manufacturer, modality) {
  const capture_datetime = captureDatetime();

  let note = {
    run_group: run_group,
    schedule: schedule,
    modality: modality,
  };

  await addLogEvent(I, run_log, "runJob", det, note, null);

  switch (run_group) {
    case "mmb":
      await onBootMMB(run_log, parseInt(schedule), capture_datetime);
      break;
    case "philips":
      await rsync_philips_mri(run_log, capture_datetime);
      break;
    case "hhm":
      console.log("\nRUNNING HHM JOBS");
      await get_hhm_data(run_log, manufacturer, modality, capture_datetime);
      break;
    case "althea_env":
      await get_althea_env_data(run_log, capture_datetime);
      break;
    case "ip_reset":
      await reset_tunnel(run_log);
      break;
    case "offline_alert":
      await insertHeartbeat(run_log);
      break;
    case "update_ipsec":
      await update_pg_ipsec(run_log);
      break;
    case "system_reset_totalizer":
      await increment_system_reset_totals(run_log);
    case "update_db_creds":
      await update_db();
      break;
    default:
      break;
  }
}

const onBoot = async () => {
  console.time("App Run Time");
  const run_log = await makeAppRunLog();

  let note = {
    LOGGER: process.env.LOGGER,
    REDIS_IP: process.env.REDIS_HOST,
    PG_USER: process.env.PG_USER,
    PG_DB: process.env.PG_DB,
  };

  await addLogEvent(I, run_log, "onBoot", cal, note, null);

  try {
    const run_group = process.argv[2];
    const schedule = process.argv[3] || null;
    const manufacturer = process.argv[4] || null;
    const modality = process.argv[5] || null;

    if (run_group === "ip_sec") {
      await get_ip_sec_table();
    }

    await runJob(run_log, run_group, schedule, manufacturer, modality);

    await dbInsertLogEvents(pgp, run_log);
    await writeLogEvents(run_log);
    console.log("\n********** END **********");
    console.timeEnd("App Run Time");
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "onBoot", cat, null, error);
    await dbInsertLogEvents(pgp, run_log);
    await writeLogEvents(run_log);
  }
};

onBoot();
