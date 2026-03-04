("use strict");
require("dotenv").config();
const { performance } = require("node:perf_hooks");
const pgp = require("pg-promise")();
const db = require("./utils/db/pg-pool");
const rsync_philips_mri = require("./jobs/philips_mri/rsync_philips-mri");
const onBootMMB = require("./jobs/mmb");
const get_hhm_data = require("./jobs/hhm");
const { get_althea_env_data } = require("./jobs/server_hop");
const run_system_manual = require("./jobs/hhm/run_manual");
const reset_tunnel = require("./jobs/tunnel_reset");
const get_ip_sec_table = require("./jobs/tools/ip_sec");
const {
  captureDatetime,
  insertHeartbeat,
  increment_system_reset_totals
} = require("./util");
const mmb_configs = require("./jobs/tools/build_mmb_config");
const update_pg_ipsec = require("./utils/vpn/update-pg-ipsec-table");
const [
  addLogEvent,
  writeLogEvents,
  dbInsertLogEvents,
  makeAppRunLog
] = require("./utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("./utils/logger/enums");

async function runJob(run_log, run_group, schedule, manufacturer, modality) {
  const capture_datetime = captureDatetime();

  let note = {
    run_group: run_group,
    schedule: schedule,
    modality: modality
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
      break;
    default:
      break;
  }
}

const onBoot = async () => {
  const start = performance.now();
  const run_dt = captureDatetime();
  const run_log = await makeAppRunLog();
  const run_group = process.argv[2];
  let status = "success";
  let error_message = null;

  let note = {
    LOGGER: process.env.LOGGER,
    REDIS_IP: process.env.REDIS_IP,
    PG_USER: process.env.PG_USER,
    PG_DB: process.env.PG_DB
  };

  await addLogEvent(I, run_log, "onBoot", cal, note, null);

  try {
    const schedule = process.argv[3] || null;
    const manufacturer = process.argv[4] || null;
    const modality = process.argv[5] || null;

    // Supply one or more SMEs in first arg array, but must be same manufac. & modality
    if (run_group === "manual") {
      const capture_datetime = captureDatetime();
      await run_system_manual(
        run_log,
        ["SME17372"],
        ["Philips", "CT"],
        capture_datetime
      );
    }
    if (run_group === "ip_sec") {
      await get_ip_sec_table();
    }

    await runJob(run_log, run_group, schedule, manufacturer, modality);

    console.log("\n********** END **********");
  } catch (error) {
    status = "error";
    error_message = error.message;
    console.log(error);
    await addLogEvent(E, run_log, "onBoot", cat, null, error);
  } finally {
    const end = performance.now();
    const ms = end - start;
    console.log(`Total runtime: ${ms.toFixed(2)} ms (${(ms / 1000).toFixed(2)} s)`);

    await dbInsertLogEvents(pgp, run_log);
    await writeLogEvents(run_log);

    if (run_group) {
      try {
        await db.none(
          `INSERT INTO stats.job_runs (app_name, job_name, run_datetime, run_time_ms, status, error_message)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [process.env.APP_NAME, run_group, run_dt, +ms.toFixed(1), status, error_message]
        );
      } catch (dbErr) {
        console.error("Failed to log job run:", dbErr.message);
      }
    }

    if (status === "error") process.exit(1);
  }
};

onBoot();
