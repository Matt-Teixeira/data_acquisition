// db/pg-pool.js
"use strict";

const fs = require("fs");
const path = require("path");
const pgp = require("pg-promise")();

function buildSsl() {
  const mode = (process.env.PG_SSLMODE || "disable").toLowerCase();

  if (mode === "disable") return false; // local Docker

  if (mode === "require") {
    // Encrypted, no CA verification (easy path if system trust is fine)
    return { rejectUnauthorized: false };
  }

  // verify-ca / verify-full — FAIL CLOSED: a verify mode without a readable CA
  // is a configuration error, never a silent downgrade to an unverified
  // connection (that would turn a typo into an unauthenticated TLS session).
  if (mode === "verify-ca" || mode === "verify-full") {
    const caPath = process.env.PG_SSL_PATH;
    if (!caPath) {
      throw new Error(`[pg] PG_SSLMODE=${mode} requires PG_SSL_PATH to be set`);
    }
    const resolved = path.isAbsolute(caPath) ? caPath : path.resolve(process.cwd(), caPath);
    // readFileSync throws if the path is missing/unreadable — exactly what we want.
    return { ca: fs.readFileSync(resolved, "utf8"), rejectUnauthorized: true };
  }

  throw new Error(`[pg] unknown PG_SSLMODE '${mode}' (use disable | require | verify-ca | verify-full)`);
}

const config = {
  // NOTE: use PGHOST/PGPORT/etc. (what you pass in docker run)
  host: process.env.PGHOST || "pg_db",
  port: Number(process.env.PGPORT || 5432),
  database: process.env.PGDATABASE || "dev",
  // No fallback: an unset PGUSER must fail authentication, never quietly
  // connect as the superuser (runbook 4.0.4; the app's role is data_acquisition_rw).
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  ssl: buildSsl(),
  // DB-001 -- fleet pool standard (decided 2026-08-27), previously applied to
  // utils/db/pg-pool.js only. A hung connect must ERROR by 10s: with no
  // timeout an unreachable DB hangs the run FOREVER, the run never reaches
  // finalizeRun so no row lands in util.app_run_logs, the empty cron .out
  // reads as "never ran", and `flock -n` then silently skips every later
  // cycle of that job. This pool is the first query for mmb, demo_systems,
  // the hhm config/credential reads and ip_sec.
  max: 15,
  idleTimeoutMillis: 60000,
  connectionTimeoutMillis: 10000,
  application_name: process.env.PG_APP_NAME || "pg_manage",
};

module.exports = pgp(config);
