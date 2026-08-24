const {
  get_systems_by_schedule,
  get_systems_by_mag_schedule,
  get_systems_by_edu_schedule
} = require("./sql/qf-provider");
const getMachineConfigs = require("./boot/get-machine-configs");
const execRsync = require("./read/exec-rsync");
const { v4: uuidv4 } = require("uuid");
const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");

const runJob = async (run_log, config, capture_datetime) => {
  // UUID FOR EACH JOB
  const job_id = uuidv4();

  try {
    // THIS IS THE PRIMARY JOB FUNCTION
    let note = {
      job_id,
      config
    };
    await addLogEvent(I, run_log, "runJob", cal, note, null);

    // ["SME01096","v2_edu2","mmb_ge_mm3",["RE_GE_MM3_A"]]
    // TODO: RENAME machineRegexTags TO regexModels
    const [
      sme,
      mmbScript,
      pgTable,
      machineRegexTags,
      ip_address,
      user_id
    ] = config;
    if (!(sme && mmbScript && pgTable && machineRegexTags)) {
      let note = {
        job_id,
        config,
        message: "JOB HALTED -> NON-CONFORMANT config"
      };
      await addLogEvent(W, run_log, "runJob", det, note, null);
      return;
    }

    // **************************************************** READ ****************************************************
    // RSYNC FILE FROM REMOTE TO LOCAL AND GET THE NEWLY SYNC FILE SIZE
    // console.log(`./files/${sme}.${mmbScript}.log`);
    const rsyncShPath = `./jobs/mmb/read/sh/rsync_mmb.sh`;
    const rsyncLocalPath = `./files/${sme}.${mmbScript}.log`; // EX. /home/prod/mmb-rpp/files/SME01113/v2_rdu_9600.log
    const rsyncRemotePath = `${mmbScript}.log`; // EX. v2_rdu_9600.log -> ~/v2_rdu_9600.log -> /home/avante/v2_rdu_9600.log
    const rsyncShArgs = [
      sme,
      rsyncRemotePath,
      rsyncLocalPath,
      ip_address,
      user_id
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

    // console.log("\nFile Size After Rsync");
    // console.log(fileSizeAfterRsync);

    // HALT JOB DUE TO BAD fileSizeAfterRsync
    if (fileSizeAfterRsync === null) {
      let note = {
        job_id,
        config,
        fileSizeAfterRsync,
        message: "JOB HALTED"
      };
      await addLogEvent(W, run_log, "runJob", det, note, null);
      return;
    }
  } catch (error) {
    console.log(error);
    let note = {
      job_id,
      config,
      error
    };
    await addLogEvent(E, run_log, "runJob", cat, note, error);
  }
};

const onBootMMB = async (run_log, process_argv, capture_datetime) => {
  let note = {
    USER_ID: process.env.USER_ID,
    LOGGER_MODE: process.env.LOGGER_MODE,
    RELEASE_SHA: process.env.RELEASE_SHA || "dev-tree",
    REDIS_IP: process.env.REDIS_HOST,
    PG_USER: process.env.PGUSER,
    PG_DB: process.env.PGDATABASE
  };

  await addLogEvent(I, run_log, "onBootMMB", cal, note, null);

  try {
    // ON BOOT GET DATA AND CONFIGS
    const systems_mag_configs = await get_systems_by_mag_schedule(
      process_argv.toString()
    );
    
    const systems_edu_configs = await get_systems_by_edu_schedule(
      process_argv.toString()
    );

    const systems_configs = [...systems_mag_configs, ...systems_edu_configs];

    let note = {
      systems_configs: systems_configs
    };
    await addLogEvent(I, run_log, "onBootMMB", det, note, null);

    // BUILD CONFIGS FOR runJob
    const machineConfigs = await getMachineConfigs(systems_configs);

    //console.log(machineConfigs);
    const jobs = [];
    for (const config of machineConfigs) {
      const {
        sme,
        mmbScript,
        pgTable,
        regexModels,
        ip_address,
        user_id
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
    // CREATE AN ARRAY OF PROMISES BY CALLING EACH FUNCTION
    const job_promises = jobs.map(job => job());

    // AWAIT JOBS
    await Promise.all(job_promises);
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "onBootMMB", cat, null, error);
  }
};

module.exports = onBootMMB;
