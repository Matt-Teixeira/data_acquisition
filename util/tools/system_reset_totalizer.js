const db = require("../../utils/db/pg-pool");
const {
  get_redis_system_total_queue,
  clear_redis_system_total_queue
} = require("../../redis");

const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");

async function increment_system_reset_totals(run_log) {
  await addLogEvent(
    I,
    run_log,
    "increment_system_reset_totals",
    cal,
    null,
    null
  );
  const queue = await get_redis_system_total_queue();

  // await clear_redis_system_total_queue();
  await update_system_reset_total(queue);
}

const update_system_reset_total = async (queue) => {
  const query = `
    UPDATE alert.offline_hhm_conn
    SET 
      daily_total = daily_total + 1,
      lifetime_total = lifetime_total + 1
    WHERE system_id = $1;
  `;

  let duplicate_systems = [];

  for await (let system of queue) {

    // Filter out any duplicate entries
    let is_duplicate = duplicate_systems.indexOf(system.id);
    if (is_duplicate !== -1) continue;
    duplicate_systems.push(system.id);

    try {
      if (system.data_source === "HHM") {
        await db.any(query, [system.id]);
      }
    } catch (error) {
      console.log(error);
    }
  }
};

module.exports = { increment_system_reset_totals };
