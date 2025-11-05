const initRedis = require("./redis_instance");
const [addLogEvent] = require("../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../utils/logger/enums");

async function add_to_redis_queue(job_id, run_log, system) {
  let note = {
    job_id,
    system_id: system.id
  };
  await addLogEvent(I, run_log, "add_to_redis_queue", cal, note, null);

  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_HOST
  );
  try {
    await redisClient.sendCommand([
      "RPUSH",
      "ip:queue",
      JSON.stringify(system)
    ]);
    await redisClient.quit();
    let note = {
      job_id,
      system_id: system.id,
      queue: "ip:queue",
      message: "Sent to Redis queue"
    };
    await addLogEvent(I, run_log, "add_to_redis_queue", det, note, null);
  } catch (error) {
    console.log(error);
    await redisClient.quit();
    let note = {
      job_id,
      system_id: system.id,
      queue: "ip:queue",
      message: "Queue insert failed"
    };
    await addLogEvent(E, run_log, "add_to_redis_queue", cat, note, error);
  }
}

async function get_redis_ip_queue() {
  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_HOST
  );
  try {
    const queue_data = await redisClient.sendCommand([
      "lrange",
      "ip:queue",
      "0",
      "1000"
    ]);
    await redisClient.quit();
    const ip_systems = [];
    for (const system of queue_data) ip_systems.push(JSON.parse(system));
    return ip_systems;
  } catch (error) {
    console.log(error);
    await redisClient.quit();
  }
}

async function clear_redis_ip_queue() {
  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_HOST
  );
  try {
    const queue_data = await redisClient.sendCommand(["del", "ip:queue"]);
    await redisClient.quit();
    return queue_data;
  } catch (error) {
    console.log(error);
    await redisClient.quit();
  }
}

async function add_system_reset_totalizer(job_id, run_log, system) {
  console.log("add_system_reset_totalizer");
  console.log(system);
  let note = {
    job_id,
    system_id: system.id
  };
  await addLogEvent(I, run_log, "add_system_reset_totalizer", cal, note, null);

  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_HOST
  );

  try {
    await redisClient.sendCommand([
      "RPUSH",
      "system_reset_totalizer:queue",
      JSON.stringify(system)
    ]);
    await redisClient.quit();
    let note = {
      job_id,
      system_id: system.id,
      queue: "system_reset_totalizer:queue",
      message: "Sent to Redis queue"
    };
    await addLogEvent(
      I,
      run_log,
      "add_system_reset_totalizer",
      det,
      note,
      null
    );
  } catch (error) {
    console.log(error);
    await redisClient.quit();
    let note = {
      job_id,
      system_id: system.id,
      queue: "system_reset_totalizer:queue",
      message: "Queue insert failed"
    };
    await addLogEvent(
      E,
      run_log,
      "add_system_reset_totalizer",
      cat,
      note,
      error
    );
  }
}

async function get_redis_system_total_queue() {
  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_HOST
  );
  try {
    const queue_data = await redisClient.sendCommand([
      "lrange",
      "system_reset_totalizer:queue",
      "0",
      "1000"
    ]);
    await redisClient.quit();
    const systems = [];
    for (const system of queue_data) systems.push(JSON.parse(system));
    return systems;
  } catch (error) {
    console.log(error);
    await redisClient.quit();
  }
}

async function clear_redis_system_total_queue() {
  const redisClient = await initRedis(
    process.env.REDIS_PORT,
    process.env.REDIS_HOST
  );
  try {
    const queue_data = await redisClient.sendCommand(["del", "system_reset_totalizer:queue"]);
    await redisClient.quit();
    return queue_data;
  } catch (error) {
    console.log(error);
    await redisClient.quit();
  }
}


module.exports = {
  add_to_redis_queue,
  get_redis_ip_queue,
  clear_redis_ip_queue,
  add_system_reset_totalizer,
  get_redis_system_total_queue,
  clear_redis_system_total_queue
};
