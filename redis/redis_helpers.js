const initRedis = require("./redis_instance");
const fs = require("node:fs").promises;
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

// .last_phil_cv_dir
// .last_phil_cv_lod

async function get_previous_dir(job_id, run_log, sme, type) {
  let note = {
    job_id,
    system_id: sme,
    type
  };
  await addLogEvent(I, run_log, "get_previous_dir", cal, note, null);

  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_IP
  );
  try {
    const getKey = `${sme}.${type}`;

    console.log("\ngetKey");
    console.log(getKey);

    const directory = await redisClient.get(getKey);
    await redisClient.quit();

    let note = {
      job_id,
      system_id: sme,
      type,
      directory
    };
    await addLogEvent(I, run_log, "get_previous_dir", det, note, null);

    if (directory === "") return null;
    return directory;
  } catch (error) {
    console.log(error);
    await redisClient.quit();

    let note = {
      job_id,
      system_id: sme,
      type
    };
    await addLogEvent(I, run_log, "get_previous_dir", cat, note, null);
  }
}

async function update_last_dir_date(sme, directory, type) {
  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_IP
  );
  try {
    const setKey = `${sme}.${type}`;
    const setValue = directory;
    await redisClient.set(setKey, setValue);
    await redisClient.quit();
  } catch (error) {
    console.log(error);
    await redisClient.quit();
  }
}

module.exports = { update_last_dir_date, get_previous_dir };
