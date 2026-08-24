const {
  get_demo_mag_systems,
  get_demo_edu_systems,
  get_demo_phil_mri_systems,
  get_demo_ge_hhm_systems,
  get_demo_siemens_hhm_systems,
  get_demo_philips_hhm_systems,
} = require("./sql/qf-provider");
const getMachineConfigs = require("../mmb/boot/get-machine-configs");
const execRsync = require("../mmb/read/exec-rsync");
const rsync_philips_mri = require("../philips_mri/rsync_philips-mri");
const { runHhmJob } = require("../hhm/_shared");
const {
  geCt,
  geCv,
  geMri,
  siemensCt,
  siemensMri,
  philipsCt,
} = require("../hhm/_configs");
const { get_philips_cv_data } = require("../hhm/philips/philips_cv");

// SQL LIKE → JS matcher. Config modality strings can be exact ("CT", "MRI")
// or LIKE patterns ("%CT"); the DB column is always a literal string. Used
// to route fetched HHM systems to the right per-modality runHhmJob call.
const likeMatch = (pattern, value) => {
  if (!pattern.includes("%") && !pattern.includes("_")) return value === pattern;
  const re = new RegExp(
    "^" +
      pattern
        .replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
        .replace(/%/g, ".*")
        .replace(/_/g, ".") +
      "$"
  );
  return re.test(value);
};

// Runs a manufacturer's HHM modalities concurrently against a pre-fetched
// system pool. The pool is filtered per config.modality (LIKE-aware) so
// each runHhmJob call only sees its own systems.
const runHhmGroupConcurrent = async (
  run_log,
  capture_datetime,
  systems,
  configs
) => {
  if (!systems || systems.length === 0) return;
  await Promise.all(
    configs.map(async (hhmConfig) => {
      const filtered = systems.filter((s) =>
        likeMatch(hhmConfig.modality, s.modality)
      );
      if (filtered.length === 0) return;
      await addLogEvent(I, run_log, "onBootDemoSystems", det, {
        jobName: hhmConfig.jobName,
        systems: filtered,
      }, null);
      await runHhmJob(run_log, capture_datetime, hhmConfig, filtered);
    })
  );
};
const { v4: uuidv4 } = require("uuid");
const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat },
} = require("../../utils/logger/enums");

const runJob = async (run_log, config, capture_datetime) => {
  const job_id = uuidv4();

  try {
    let note = {
      job_id,
      config,
    };
    await addLogEvent(I, run_log, "runJob", cal, note, null);

    const [
      sme,
      mmbScript,
      pgTable,
      machineRegexTags,
      ip_address,
      user_id,
    ] = config;
    if (!(sme && mmbScript && pgTable && machineRegexTags)) {
      let note = {
        job_id,
        config,
        message: "JOB HALTED -> NON-CONFORMANT config",
      };
      await addLogEvent(W, run_log, "runJob", det, note, null);
      return;
    }

    const rsyncShPath = `./jobs/mmb/read/sh/rsync_mmb.sh`;
    const rsyncLocalPath = `./files/${sme}.${mmbScript}.log`;
    const rsyncRemotePath = `${mmbScript}.log`;
    const rsyncShArgs = [
      sme,
      rsyncRemotePath,
      rsyncLocalPath,
      ip_address,
      user_id,
    ];

    const fileSizeAfterRsync = await execRsync(
      run_log,
      job_id,
      sme,
      rsyncShPath,
      rsyncShArgs,
      capture_datetime,
      config.vpn
    );

    if (fileSizeAfterRsync === null) {
      let note = {
        job_id,
        config,
        fileSizeAfterRsync,
        message: "JOB HALTED",
      };
      await addLogEvent(W, run_log, "runJob", det, note, null);
      return;
    }
  } catch (error) {
    console.log(error);
    let note = {
      job_id,
      config,
      error,
    };
    await addLogEvent(E, run_log, "runJob", cat, note, error);
  }
};

const onBootDemoSystems = async (run_log, capture_datetime) => {
  let note = {
    USER_ID: process.env.USER_ID,
    LOGGER_MODE: process.env.LOGGER_MODE,
    RELEASE_SHA: process.env.RELEASE_SHA || "dev-tree",
    REDIS_IP: process.env.REDIS_HOST,
    PG_USER: process.env.PGUSER,
    PG_DB: process.env.PGDATABASE,
  };

  await addLogEvent(I, run_log, "onBootDemoSystems", cal, note, null);

  try {
    const mmb_pull = (async () => {
      const [systems_mag_configs, systems_edu_configs] = await Promise.all([
        get_demo_mag_systems(),
        get_demo_edu_systems(),
      ]);
      const systems_configs = [...systems_mag_configs, ...systems_edu_configs];
      await addLogEvent(I, run_log, "onBootDemoSystems", det, {
        systems_configs,
      }, null);
      const machineConfigs = await getMachineConfigs(systems_configs);
      await Promise.all(
        machineConfigs.map((c) =>
          runJob(
            run_log,
            [c.sme, c.mmbScript, c.pgTable, c.regexModels, c.ip_address, c.user_id],
            capture_datetime
          )
        )
      );
    })();

    const phil_mri_pull = (async () => {
      const phil_mri_systems = await get_demo_phil_mri_systems();
      if (!phil_mri_systems || phil_mri_systems.length === 0) return;
      await addLogEvent(I, run_log, "onBootDemoSystems", det, {
        phil_mri_systems,
      }, null);
      await rsync_philips_mri(run_log, null, phil_mri_systems);
    })();

    const ge_hhm_pull = (async () => {
      const systems = await get_demo_ge_hhm_systems();
      await runHhmGroupConcurrent(run_log, capture_datetime, systems, [
        geCt,
        geCv,
        geMri,
      ]);
    })();

    const siemens_hhm_pull = (async () => {
      const systems = await get_demo_siemens_hhm_systems();
      await runHhmGroupConcurrent(run_log, capture_datetime, systems, [
        siemensCt,
        siemensMri,
      ]);
    })();

    // Philips HHM: CT goes through runHhmJob (registry config); CV is an
    // outlier with its own multi-stage pipeline in jobs/hhm/philips/philips_cv.js.
    // Both branches run in parallel.
    const philips_hhm_pull = (async () => {
      const systems = await get_demo_philips_hhm_systems();
      if (!systems || systems.length === 0) return;
      const ct_systems = systems.filter((s) =>
        likeMatch(philipsCt.modality, s.modality)
      );
      const cv_systems = systems.filter((s) => s.modality === "CV/IR");

      const ct_branch = (async () => {
        if (ct_systems.length === 0) return;
        await addLogEvent(I, run_log, "onBootDemoSystems", det, {
          jobName: philipsCt.jobName,
          systems: ct_systems,
        }, null);
        await runHhmJob(run_log, capture_datetime, philipsCt, ct_systems);
      })();

      const cv_branch = (async () => {
        if (cv_systems.length === 0) return;
        await addLogEvent(I, run_log, "onBootDemoSystems", det, {
          jobName: "philips_cv",
          systems: cv_systems,
        }, null);
        await get_philips_cv_data(run_log, capture_datetime, cv_systems);
      })();

      await Promise.all([ct_branch, cv_branch]);
    })();

    await Promise.all([
      mmb_pull,
      phil_mri_pull,
      ge_hhm_pull,
      siemens_hhm_pull,
      philips_hhm_pull,
    ]);
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "onBootDemoSystems", cat, null, error);
  }
};

module.exports = onBootDemoSystems;
