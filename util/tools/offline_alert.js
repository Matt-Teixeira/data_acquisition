const db = require("../../utils/db/pg-pool");
const {
  get_redis_online_queue,
  clear_redis_online_queue
} = require("../../redis");

const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");

// Minimal SQL-literal safety for strings that get interpolated into VALUES.
// The DB accepts null for missing values; quoting is deferred to sqlLit.
const sqlLit = (v) => {
  if (v === null || v === undefined) return "NULL";
  return `'${String(v).replace(/'/g, "''")}'`;
};
const sqlBool = (v) => (v === null || v === undefined ? "NULL" : v ? "TRUE" : "FALSE");

async function insertHeartbeat(run_log) {
  await addLogEvent(I, run_log, "insertHeartbeat", cal, null, null);
  const queue = await get_redis_online_queue();

  await clear_redis_online_queue();
  await upsert_query_builder(queue);
}

const upsert_query_builder = async (queue) => {
  const dup_systems = {
    mmb: [],
    hhm: []
  };

  const success_queue = [];
  const failed_queue = [];

  // Seperate queued systems based on successful acquisition
  for (let system of queue) {
    if (!system.conn_err) {
      success_queue.push(system);
    }
    if (system.conn_err) {
      failed_queue.push(system);
    }
  }

  console.log("\nsuccess_queue");
  console.log(success_queue);
  console.log("\nfailed_queue");
  console.log(failed_queue);

  const hhm_success_values = [];
  const hhm_insert_str = `INSERT INTO alert.offline_hhm_conn (system_id, capture_datetime, successful_acquisition, host_intervention, connection_error, error_category, phase) VALUES `;
  const hhm_on_conflict = `ON CONFLICT (system_id) DO UPDATE SET `;
  const hhm_set_str = `capture_datetime = EXCLUDED.capture_datetime, inserted_at = EXCLUDED.inserted_at, successful_acquisition = EXCLUDED.successful_acquisition, host_intervention = EXCLUDED.host_intervention, connection_error = EXCLUDED.connection_error, error_category = EXCLUDED.error_category, phase = EXCLUDED.phase;`;

  const hhm_failed_values = [];
  const hhm_failed_insert_str = `INSERT INTO alert.offline_hhm_conn (system_id, successful_acquisition, host_intervention, connection_error, error_category, phase) VALUES `;
  const hhm_failed_on_conflict = `ON CONFLICT (system_id) DO UPDATE SET `;
  const hhm_failed_set_str = `inserted_at = EXCLUDED.inserted_at, successful_acquisition = EXCLUDED.successful_acquisition, host_intervention = EXCLUDED.host_intervention, connection_error = EXCLUDED.connection_error, error_category = EXCLUDED.error_category, phase = EXCLUDED.phase;`;

  const mmb_success_values = [];
  const mmb_insert_str = `INSERT INTO alert.offline_mmb_conn (system_id, capture_datetime, successful_acquisition, host_intervention, connection_error, error_category, phase) VALUES `;
  const mmb_on_conflict = `ON CONFLICT (system_id) DO UPDATE SET `;
  const mmb_set_str = `capture_datetime = EXCLUDED.capture_datetime, inserted_at = EXCLUDED.inserted_at, successful_acquisition = EXCLUDED.successful_acquisition, host_intervention = EXCLUDED.host_intervention, connection_error = EXCLUDED.connection_error, error_category = EXCLUDED.error_category, phase = EXCLUDED.phase;`;

  const mmb_failed_values = [];
  const mmb_failed_insert_str = `INSERT INTO alert.offline_mmb_conn (system_id, successful_acquisition, host_intervention, connection_error, error_category, phase) VALUES `;
  const mmb_failed_on_conflict = `ON CONFLICT (system_id) DO UPDATE SET `;
  const mmb_failed_set_str = `inserted_at = EXCLUDED.inserted_at, successful_acquisition = EXCLUDED.successful_acquisition, host_intervention = EXCLUDED.host_intervention, connection_error = EXCLUDED.connection_error, error_category = EXCLUDED.error_category, phase = EXCLUDED.phase;`;

  // SEPARATE SUCCESSFUL HHM AND MMB. FILTER DUPLICATE ENTRIES.
  for (const system of success_queue) {
    if (system.data_source === "hhm") {
      // Check for possible duplicates in queue and prevent double runs
      let is_duplicate = dup_systems.hhm.indexOf(system.id);
      if (is_duplicate !== -1) continue;

      hhm_success_values.push(
        `(${sqlLit(system.id)}, ${sqlLit(system.capture_datetime)}, ${sqlBool(
          system.successful_acquisition
        )}, ${sqlBool(system.host_intervention)}, ${sqlLit(
          system.connection_error
        )}, ${sqlLit(system.error_category)}, ${sqlLit(system.phase)})`
      );

      dup_systems.hhm.push(system.id);
    }

    if (system.data_source === "mmb") {
      // Check for possible duplicates in queue and prevent double runs
      let is_duplicate = dup_systems.mmb.indexOf(system.id);
      if (is_duplicate !== -1) continue;

      mmb_success_values.push(
        `(${sqlLit(system.id)}, ${sqlLit(system.capture_datetime)}, ${sqlBool(
          system.successful_acquisition
        )}, ${sqlBool(system.host_intervention)}, ${sqlLit(
          system.connection_error
        )}, ${sqlLit(system.error_category)}, ${sqlLit(system.phase)})`
      );

      dup_systems.mmb.push(system.id);
    }
  }

  let hhm_values_str = "";
  let mmb_values_str = "";

  // Loop through and build query for successful hhm
  for (let i = 0; i < hhm_success_values.length; i++) {
    if (i === hhm_success_values.length - 1) {
      hhm_values_str += hhm_success_values[i] + " ";
      continue;
    }
    hhm_values_str += hhm_success_values[i] + ", ";
  }

  // Loop through and build query for successful mmb
  for (let i = 0; i < mmb_success_values.length; i++) {
    if (i === mmb_success_values.length - 1) {
      mmb_values_str += mmb_success_values[i] + " ";
      continue;
    }
    mmb_values_str += mmb_success_values[i] + ", ";
  }

  let hhm_query_string = `${hhm_insert_str}${hhm_values_str}${hhm_on_conflict}${hhm_set_str}`;
  let mmb_query_string = `${mmb_insert_str}${mmb_values_str}${mmb_on_conflict}${mmb_set_str}`;

  if (hhm_success_values.length) await db.any(hhm_query_string);
  if (mmb_success_values.length) await db.any(mmb_query_string);

  // SEPARATE FAILED HHM AND MMB. FILTER DUPLICATE ENTRIES.
  for (const system of failed_queue) {
    if (system.data_source === "hhm") {
      // Check for possible duplicates in queue and prevent double runs
      let is_duplicate = dup_systems.hhm.indexOf(system.id);
      if (is_duplicate !== -1) continue;
      dup_systems.hhm.push(system.id);

      hhm_failed_values.push(
        `(${sqlLit(system.id)}, ${sqlBool(
          system.successful_acquisition
        )}, ${sqlBool(system.host_intervention)}, ${sqlLit(
          system.connection_error
        )}, ${sqlLit(system.error_category)}, ${sqlLit(system.phase)})`
      );
    }

    if (system.data_source === "mmb") {
      // Check for possible duplicates in queue and prevent double runs
      let is_duplicate = dup_systems.mmb.indexOf(system.id);
      if (is_duplicate !== -1) continue;
      dup_systems.mmb.push(system.id);

      mmb_failed_values.push(
        `(${sqlLit(system.id)}, ${sqlBool(
          system.successful_acquisition
        )}, ${sqlBool(system.host_intervention)}, ${sqlLit(
          system.connection_error
        )}, ${sqlLit(system.error_category)}, ${sqlLit(system.phase)})`
      );
    }
  }

  let hhm_failed_values_str = "";
  let mmb_failed_values_str = "";

  for (let i = 0; i < hhm_failed_values.length; i++) {
    if (i === hhm_failed_values.length - 1) {
      hhm_failed_values_str += hhm_failed_values[i] + " ";
      continue;
    }
    hhm_failed_values_str += hhm_failed_values[i] + ", ";
  }

  for (let i = 0; i < mmb_failed_values.length; i++) {
    if (i === mmb_failed_values.length - 1) {
      mmb_failed_values_str += mmb_failed_values[i] + " ";
      continue;
    }
    mmb_failed_values_str += mmb_failed_values[i] + ", ";
  }

  let hhm_failed_query_string = `${hhm_failed_insert_str}${hhm_failed_values_str}${hhm_failed_on_conflict}${hhm_failed_set_str}`;
  let mmb_failed_query_string = `${mmb_failed_insert_str}${mmb_failed_values_str}${mmb_failed_on_conflict}${mmb_failed_set_str}`;

  if (hhm_failed_values.length) await db.any(hhm_failed_query_string);
  if (mmb_failed_values.length) await db.any(mmb_failed_query_string);
};

module.exports = { insertHeartbeat };
