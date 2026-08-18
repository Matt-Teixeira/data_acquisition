("use strict");
const { log } = require("../logger");
const redis = require("redis");

async function initRedis(PORT, REDIS_IP) {
  // SETUP ENV BASED RESOURCES -> REDIS CLIENT, JOB SCHEDULES
  const clienConfig = {
    socket: {
      port: PORT,
      host: REDIS_IP,
    },
  };
  // Auth is opt-in: inert until REDIS_PW is set in this app's .env AND the
  // server has requirepass enabled (redis-admin rollout).
  if (process.env.REDIS_PW) clienConfig.password = process.env.REDIS_PW;

  const redisClient = redis.createClient(clienConfig);

  redisClient.on(
    "error",
    async (error) =>
      await log("error", "NA", "NA", "redisClient", `ON ERROR`, {
        // TODO: KILL APP?
        error: error,
      })
  );

  await redisClient.connect();

  return redisClient;
}

module.exports = initRedis;
