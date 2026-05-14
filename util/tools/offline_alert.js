const db = require("../../utils/db/pg-pool");
const pgp = require("pg-promise")();
const { pg_column_sets } = require("../../utils/db/sql/pg-helpers");
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
  await writeStatsHistory(run_log, queue);
}

const upsert_query_builder = async (queue) => {
  const dup_systems = {
    mmb: [],
    hhm: []
  };

  // A single system can push multiple entries into online:queue within one
  // run (e.g. list-step success followed by transfer-step failure). Redis
  // RPUSH + LRANGE returns items in chronological order, so the LAST entry
  // represents the most-final processing-stage classification. Dedupe by
  // (data_source, id) keeping the last seen, before partitioning - otherwise
  // the later stage's state gets dropped by the first-wins dup_systems check
  // and the alert row misrepresents reality (e.g. a transfer failure gets
  // masked by an earlier successful list step).
  const latestByKey = new Map();
  for (const system of queue) {
    const key = `${system.data_source}:${system.id}`;
    latestByKey.set(key, system);
  }
  const deduped_queue = [...latestByKey.values()];

  const success_queue = [];
  const failed_queue = [];

  // Seperate queued systems based on successful acquisition
  for (let system of deduped_queue) {
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

// Persist per-run, per-system tunnel/IP health to stats.* tables. Runs after the
// alert.offline_*_conn UPSERTs and is wrapped so any failure here does not
// affect the existing alert path.
const writeStatsHistory = async (run_log, queue) => {
  try {
    if (!queue || queue.length === 0) return;

    // Match upsert_query_builder's last-wins dedupe by (data_source, id).
    const latestByKey = new Map();
    for (const system of queue) {
      latestByKey.set(`${system.data_source}:${system.id}`, system);
    }
    const deduped = [...latestByKey.values()];

    // Resolve host_ip + tunnel_id + endpoint_id in one batched lookup. host(inet)
    // strips any /N suffix so we can re-use the value as a plain dotted-quad.
    const system_ids = deduped.map((s) => s.id);
    const enrichRows = await db.any(
      `SELECT ac.system_id,
              host(ac.host_ip) AS host_ip,
              ips.tunnel_id,
              ips.endpoint_id
         FROM config.acquisition ac
         LEFT JOIN util.ip_sec ips ON ac.host_ip = ips.remote_subnet_ip
        WHERE ac.system_id = ANY($1::text[])`,
      [system_ids]
    );
    const ipMap = new Map(enrichRows.map((r) => [r.system_id, r]));

    const history_rows = deduped.map((s) => {
      const ip = ipMap.get(s.id) || {};
      return {
        run_id: run_log.run_id,
        acq_run_id: s.acq_run_id || null,
        app_name: s.app_name || s.data_source,
        system_id: s.id,
        data_source: s.data_source,
        manufacturer: s.manufacturer || null,
        modality: s.modality || null,
        capture_datetime: s.capture_datetime || null,
        successful_acquisition: !!s.successful_acquisition,
        host_intervention:
          s.host_intervention === undefined || s.host_intervention === null
            ? null
            : !!s.host_intervention,
        connection_error: s.connection_error || null,
        error_category: s.error_category || null,
        phase: s.phase || null,
        host_ip: ip.host_ip || null,
        tunnel_id: ip.tunnel_id == null ? null : ip.tunnel_id,
        endpoint_id: ip.endpoint_id == null ? null : ip.endpoint_id,
      };
    });

    if (history_rows.length) {
      const q = pgp.helpers.insert(
        history_rows,
        pg_column_sets.stats.acquisition_history
      );
      await db.none(q);
    }

    const groups = new Map();
    for (const row of history_rows) {
      const key = `${row.app_name}::${row.tunnel_id == null ? "null" : row.tunnel_id}`;
      let g = groups.get(key);
      if (!g) {
        g = {
          run_id: run_log.run_id,
          app_name: row.app_name,
          tunnel_id: row.tunnel_id,
          endpoint_id: row.endpoint_id,
          subnet_24: row.host_ip ? toSubnet24(row.host_ip) : null,
          systems_total: 0,
          systems_success: 0,
          systems_failed: 0,
          systems_intervention: 0,
          err_cat_breakdown: {},
        };
        groups.set(key, g);
      }
      g.systems_total += 1;
      if (row.successful_acquisition) g.systems_success += 1;
      else g.systems_failed += 1;
      if (row.host_intervention) g.systems_intervention += 1;
      if (row.error_category) {
        g.err_cat_breakdown[row.error_category] =
          (g.err_cat_breakdown[row.error_category] || 0) + 1;
      }
    }
    const summary_rows = [...groups.values()];

    if (summary_rows.length) {
      const q = pgp.helpers.insert(
        summary_rows,
        pg_column_sets.stats.tunnel_run_summary
      );
      await db.none(q);
    }

    await addLogEvent(
      I,
      run_log,
      "writeStatsHistory",
      det,
      { history_count: history_rows.length, summary_count: summary_rows.length },
      null
    );
  } catch (error) {
    await addLogEvent(E, run_log, "writeStatsHistory", cat, null, error);
  }
};

const toSubnet24 = (ip) => {
  const parts = ip.split(".");
  if (parts.length !== 4) return null;
  return `${parts[0]}.${parts[1]}.${parts[2]}.0/24`;
};

module.exports = { insertHeartbeat };
