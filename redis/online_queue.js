const initRedis = require("./redis_instance");
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

async function add_to_online_queue(job_id, run_log, system) {
  //const ipAddressRegex = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/;

  let note = {
    job_id,
    system_id: system.system_id
  };
  await addLogEvent(I, run_log, "add_to_online_queue", cal, note, null);

  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_IP
  );
  try {
    await redisClient.sendCommand([
      "RPUSH",
      "online:queue",
      JSON.stringify(system)
    ]);
    await redisClient.quit();
    let note = {
      job_id,
      system_id: system.id,
      queue: "online:queue",
      message: "Sent to redis online queue"
    };
    await addLogEvent(I, run_log, "add_to_online_queue", det, note, null);
  } catch (error) {
    console.log(error);
    await redisClient.quit();
    let note = {
      job_id,
      system_id: system.id,
      queue: "online:queue",
      message: "Online queue insert failed"
    };
    await addLogEvent(E, run_log, "add_to_online_queue", cat, note, error);
  }
}

async function get_redis_online_queue() {
  //addLogEvent(I, run_log, "get_redis_online_queue", cal, note, null);
  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_IP
  );
  try {
    const queue_data = await redisClient.sendCommand([
      "lrange",
      "online:queue",
      "0",
      "1000"
    ]);
    await redisClient.quit();
    const online_systems = [];
    for (const system of queue_data) online_systems.push(JSON.parse(system));
    return online_systems;
  } catch (error) {
    console.log(error);
    await redisClient.quit();
    //addLogEvent(E, run_log, "get_redis_online_queue", cat, note, error);
  }
}

async function clear_redis_online_queue() {
  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_IP
  );
  try {
    const queue_data = await redisClient.sendCommand(["del", "online:queue"]);
    await redisClient.quit();
    return queue_data;
  } catch (error) {
    console.log(error);
    await redisClient.quit();
  }
}

module.exports = {
  get_redis_online_queue,
  clear_redis_online_queue,
  add_to_online_queue
};
