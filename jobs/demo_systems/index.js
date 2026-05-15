const {
  get_demo_mag_systems,
  get_demo_edu_systems,
  get_demo_phil_mri_systems,
} = require("./sql/qf-provider");
const getMachineConfigs = require("../mmb/boot/get-machine-configs");
const execRsync = require("../mmb/read/exec-rsync");
const rsync_philips_mri = require("../philips_mri/rsync_philips-mri");
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
    LOGGER: process.env.LOGGER,
    REDIS_IP: process.env.REDIS_HOST,
    PG_USER: process.env.PG_USER,
    PG_DB: process.env.PG_DB,
  };

  await addLogEvent(I, run_log, "onBootDemoSystems", cal, note, null);

  try {
    const systems_mag_configs = await get_demo_mag_systems();
    const systems_edu_configs = await get_demo_edu_systems();

    const systems_configs = [...systems_mag_configs, ...systems_edu_configs];

    let note = {
      systems_configs: systems_configs,
    };
    await addLogEvent(I, run_log, "onBootDemoSystems", det, note, null);

    const machineConfigs = await getMachineConfigs(systems_configs);

    const jobs = [];
    for (const config of machineConfigs) {
      const {
        sme,
        mmbScript,
        pgTable,
        regexModels,
        ip_address,
        user_id,
      } = config;

      jobs.push(
        async () =>
          await runJob(
            run_log,
            [sme, mmbScript, pgTable, regexModels, ip_address, user_id],
            capture_datetime
          )
      );
    }

    const job_promises = jobs.map((job) => job());

    await Promise.all(job_promises);

    const phil_mri_systems = await get_demo_phil_mri_systems();
    if (phil_mri_systems && phil_mri_systems.length > 0) {
      await addLogEvent(I, run_log, "onBootDemoSystems", det, {
        phil_mri_systems,
      }, null);
      await rsync_philips_mri(run_log, null, phil_mri_systems);
    }
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "onBootDemoSystems", cat, null, error);
  }
};

module.exports = onBootDemoSystems;
