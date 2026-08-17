("use strict");
require("dotenv").config();
const pgp = require("pg-promise")();
const db = require("./utils/db/pg-pool");
const job_db = require("./db/pgPool");
const update_db = require("./util/encrypt/old_to_new_process");
const rsync_philips_mri = require("./jobs/philips_mri/rsync_philips-mri");
const onBootMMB = require("./jobs/mmb");
const onBootDemoSystems = require("./jobs/demo_systems");
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
  ,
  ,
  ,
  addRunSummary,
] = require("./utils/logger/log");
const {
  type: { I, E },
  tag: { cal, det, cat },
} = require("./utils/logger/enums");

// FAIL-LOUDLY EXIT-CODE CONTRACT (see DESIGN.md):
//   0 = success or skipped, 1 = failed (fatal error reached onBoot),
//   2 = partial (tolerated per-system errors) or self-log persistence failure,
//   3 = usage error (unknown run group -> operator must fix the crontab).
const EXIT = { SUCCESS: 0, FAILED: 1, PARTIAL: 2, USAGE: 3 };

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
    case "demo_systems":
      await onBootDemoSystems(run_log, capture_datetime);
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
    case "update_db_creds":
      await update_db();
      break;
    case "ip_sec":
      // HANDLED IN onBoot BEFORE DISPATCH; VALID GROUP, NOTHING MORE TO DO.
      break;
    default: {
      // FAIL LOUDLY: A TYPO'D CRONTAB ENTRY MUST NOT EXIT 0 AS A SILENT NO-OP.
      const err = new Error(`Unknown run group: ${JSON.stringify(run_group)}`);
      err.code = "E_UNKNOWN_RUN_GROUP";
      throw err;
    }
  }
}

// DERIVE THE FINAL RUN OUTCOME FROM THE EVENTS THE RUN ACTUALLY RECORDED.
// TOLERATED (PER-SYSTEM) FAILURES WERE CAUGHT BY THE JOBS' OWN PER-UNIT
// CATCHES AND LOGGED AS ERROR EVENTS; A FATAL ERROR IS ONE THAT ESCAPED TO
// onBoot'S CATCH. SEE DESIGN.md ("run_outcome/v1").
const deriveOutcome = (run_log, fatal_error) => {
  const events = run_log.log_events || [];
  const error_events = events.filter((e) => e.type === "ERROR").length;
  const warn_events = events.filter((e) => e.type === "WARN").length;
  const failed_systems = [
    ...new Set(
      events
        .filter((e) => e.type === "ERROR" && e.note)
        .map((e) => e.note.sme || e.note.system_id)
        .filter(Boolean)
    ),
  ];

  let outcome;
  let exit_code;
  if (fatal_error) {
    outcome = "failed";
    exit_code =
      fatal_error.code === "E_UNKNOWN_RUN_GROUP" ? EXIT.USAGE : EXIT.FAILED;
  } else if (error_events > 0) {
    outcome = "partial";
    exit_code = EXIT.PARTIAL;
  } else if (run_log.outcome === "skipped") {
    // JOBS MAY OPT IN: run_log.outcome = "skipped" WHEN THERE WAS NO WORK.
    outcome = "skipped";
    exit_code = EXIT.SUCCESS;
  } else {
    outcome = "success";
    exit_code = EXIT.SUCCESS;
  }

  return {
    outcome: outcome,
    exit_code: exit_code,
    error_events: error_events,
    warn_events: warn_events,
    systems: {
      failed_count: failed_systems.length,
      failed: failed_systems.slice(0, 50),
    },
    fatal: fatal_error
      ? {
          code: fatal_error.code || null,
          message: String(fatal_error.message || fatal_error),
        }
      : null,
    contract: "run_outcome/v1",
  };
};

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

  let fatal_error = null;
  try {
    const run_group = process.argv[2];
    const schedule = process.argv[3] || null;
    const manufacturer = process.argv[4] || null;
    const modality = process.argv[5] || null;

    run_log.run_group = run_group;
    run_log.manufacturer = manufacturer;
    run_log.modality = modality;

    if (run_group === "ip_sec") {
      await get_ip_sec_table();
    }

    await runJob(run_log, run_group, schedule, manufacturer, modality);
  } catch (error) {
    fatal_error = error;
    console.error(error);
    await addLogEvent(E, run_log, "onBoot", cat, null, error);
  } finally {
    // 1) DECIDE THE OUTCOME AND SET THE (HONEST) EXIT CODE. NEVER process.exit():
    //    process.exitCode LETS PENDING I/O FLUSH AND THE LOOP DRAIN NATURALLY.
    const outcome = deriveOutcome(run_log, fatal_error);
    process.exitCode = outcome.exit_code;

    // 2) APPEND SUMMARY + TERMINAL run_outcome EVENT (type INFO ON PURPOSE:
    //    IT MUST NEVER LAND IN warn_error_logs -- ops-dashboard DERIVES STATUS
    //    AND incident-engine MATERIALIZES INCIDENTS FROM THAT COLUMN).
    await addRunSummary(run_log);
    await addLogEvent(I, run_log, "run_outcome", det, outcome, null);

    // 3) PERSIST THE SELF-LOG, DB FIRST THEN DISK (DISK CAPTURES ANY DB-INSERT
    //    ERROR EVENT). BOTH NOW REPORT FAILURE INSTEAD OF SWALLOWING IT.
    const db_insert_ok = await dbInsertLogEvents(pgp, run_log);
    const disk_write_ok = await writeLogEvents(run_log);
    if (!db_insert_ok || !disk_write_ok) {
      // MONITORING IS BLIND FOR THIS RUN -- NEVER REPORT A CLEAN SUCCESS.
      if (process.exitCode === EXIT.SUCCESS) process.exitCode = EXIT.PARTIAL;
      console.error(
        `[run_outcome] self-log persistence failed (db=${db_insert_ok} disk=${disk_write_ok})`
      );
    }

    console.log(
      `[run_outcome] ${outcome.outcome} exit=${process.exitCode}` +
        ` errors=${outcome.error_events} warns=${outcome.warn_events}` +
        ` failed_systems=${outcome.systems.failed_count}`
    );
    console.log("\n********** END **********");
    console.timeEnd("App Run Time");

    // 4) RELEASE SHARED CLIENTS SO THE EVENT LOOP CAN DRAIN. BOTH POOLS ARE
    //    ALREADY INSTANTIATED TRANSITIVELY BY THE REQUIRES ABOVE.
    try {
      await db.$pool.end();
    } catch (e) {
      console.error(`[run_outcome] utils/db/pg-pool close: ${e.message}`);
    }
    try {
      await job_db.$pool.end();
    } catch (e) {
      console.error(`[run_outcome] db/pgPool close: ${e.message}`);
    }
    pgp.end();

    // 5) FAILSAFE: IF A LEAKED HANDLE (REDIS CLIENT, CHILD PROCESS) KEEPS THE
    //    LOOP ALIVE, FORCE-EXIT WITH THE SAME HONEST CODE INSTEAD OF HANGING
    //    UNDER CRON. unref() SO THE TIMER ITSELF NEVER HOLDS THE LOOP OPEN.
    const failsafe = setTimeout(() => {
      console.error(
        "[run_outcome] event loop did not drain within 30s; forcing exit"
      );
      process.exit(process.exitCode);
    }, 30_000);
    failsafe.unref();
  }
};

onBoot().catch((error) => {
  // BOOTSTRAP FAILURE (makeAppRunLog / FIRST LOG EVENT): NOTHING WAS RECORDED,
  // SO AT LEAST CRASH HONESTLY.
  console.error(error);
  process.exit(EXIT.FAILED);
});
