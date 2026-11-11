-- ONE-OFF CLEAN-UP: mask device credentials in util.app_run_logs (live partitions) and
-- archive_util.app_run_logs_YYYY_MM (detached archive tables), plus
-- stats.job_runs.error_message (plain text, rule R5 below), written before the
-- util/redact.js fix was deployed. See PLAN-CREDENTIAL-LOGS.md section 6.
--
-- The credential values are unknown here (only the collector decrypts them), so the
-- rules use the STRUCTURE the old code wrote them in (same rules as
-- redact_run_log_files.js). <cred script> = ./read/sh/GE/*, ./read/sh/Philips/*,
-- ./read/sh/Siemens/siemens_c* (the scripts called with [ip, user, pass, ...]):
--   R1  "execute_path":"<cred script>","args":["<ip>","<user>","<pass>",... -> user, pass = "***"
--   R2  exec_list_dirs note {job_id, system_id, args:[ip,user,pass,...]}     -> user, pass = "***"
--   R3  Command failed: <cred script> <args...>   (to end of line)          -> <script> ***
--   R4  "cmd":"<cred script> <args...>"                                     -> "<script> ***"
-- Everything else in the row is kept (ip in args[0], script path, stderr, stack); rows
-- that only mention other commands (MMB rsync etc.) are not touched.
--
-- USAGE (psql, autocommit ON; never with -1 / --single-transaction). Every section is
-- opt-in; without a section flag the script only sets up and stops.
--   cutoff   (required) first collector run AFTER the fix was deployed, e.g. '2026-11-12 14:00+00'
--   schemas  (optional) 'util,archive_util' (default) or 'util' (e.g. if archive_util is dropped)
--
--   -v rehearse=1 [-v rehearse_tbl=util.app_run_logs_2026_11 -v rehearse_day=2026-11-10]
--                       section 2: one-day rehearsal, read-only, minutes
--   -v dryrun=1         section 1: rows that would change per table/app/month, read-only, HOURS
--   -v apply=1          section 3: the UPDATE (writes), then section 4 verify
--   -v verify=1         section 4 alone: residual count per table, read-only, hours
--   -v vacuum_list=1    section 5: prints the VACUUM FULL statements to run (does not run them)
--
--   psql "$PGURL" -v cutoff='2026-11-12 14:00+00' -v rehearse=1 -f redact_app_run_logs.sql

\set ON_ERROR_STOP on

\if :{?cutoff}
\else
  \echo 'refusing to run: pass -v cutoff=''<first post-fix run, timestamptz>'''
  \quit
\endif
\if :{?schemas}
\else
  \set schemas 'util,archive_util'
\endif

-- 0. SETUP (session-local only: pg_temp objects vanish when the session ends) -----------
SELECT set_config('credlog.cutoff', (:'cutoff')::timestamptz::text, false) AS cutoff,
       set_config('credlog.schemas', :'schemas', false) AS schemas;

CREATE OR REPLACE FUNCTION pg_temp.credlog_redact(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $f$
SELECT
-- BEGIN REDACT EXPR
regexp_replace(regexp_replace(regexp_replace(regexp_replace(
  t,
  '("execute_path":"\./read/sh/(?:GE|Philips|Siemens/siemens_c)[^"]*","args":\["(?:[^"\\]|\\.)*",)"(?:[^"\\]|\\.)*","(?:[^"\\]|\\.)*"',
  '\1"***","***"', 'g'),
  '("func":"exec_list_dirs","tag":"(?:[^"\\]|\\.)*","note":\{"job_id":"(?:[^"\\]|\\.)*","system_id":"(?:[^"\\]|\\.)*","args":\["(?:[^"\\]|\\.)*",)"(?:[^"\\]|\\.)*","(?:[^"\\]|\\.)*"',
  '\1"***","***"', 'g'),
  '(Command failed: \./read/sh/(?:GE|Philips|Siemens/siemens_c)[^ "\\]*) (?:[^"\\]|\\[^n])+',
  '\1 ***', 'g'),
  '("cmd":"\./read/sh/(?:GE|Philips|Siemens/siemens_c)[^ "\\]*) (?:[^"\\]|\\.)+"',
  '\1 ***"', 'g')
-- END REDACT EXPR
$f$;

-- Cheap prefilter: a row can only change if one of these substrings is present.
CREATE OR REPLACE FUNCTION pg_temp.credlog_candidate(v json, w json) RETURNS boolean
LANGUAGE sql IMMUTABLE AS $f$
SELECT v::text LIKE '%","args":["%' OR v::text LIKE '%Command failed: %' OR v::text LIKE '%"cmd":"%'
    OR w::text LIKE '%","args":["%' OR w::text LIKE '%Command failed: %' OR w::text LIKE '%"cmd":"%'
$f$;

-- Residual check: a credential-bearing collector script with an unmasked argument list
-- (an args array of >= 3 strings whose [1],[2] are not both "***"; a Command failed line
-- whose arguments are not "***"). 2-element args ([ip, data_path], e.g. siemens_cerb.sh in
-- early 2025) carry no credential and are not flagged.
CREATE OR REPLACE FUNCTION pg_temp.credlog_residual(t text) RETURNS boolean
LANGUAGE sql IMMUTABLE AS $f$
SELECT t ~ '"execute_path":"\./read/sh/(GE|Philips|Siemens/siemens_c)[^"]*","args":\["(?:[^"\\]|\\.)*",(?!"\*\*\*","\*\*\*")"(?:[^"\\]|\\.)*","(?:[^"\\]|\\.)*"'
    OR t ~ '"func":"exec_list_dirs","tag":"(?:[^"\\]|\\.)*","note":\{"job_id":"(?:[^"\\]|\\.)*","system_id":"(?:[^"\\]|\\.)*","args":\["(?:[^"\\]|\\.)*",(?!"\*\*\*","\*\*\*")"(?:[^"\\]|\\.)*","(?:[^"\\]|\\.)*"'
    OR t ~ 'Command failed: \./read/sh/(GE|Philips|Siemens/siemens_c)[^ "\\]* (?!\*\*\*)'
$f$;

-- stats.job_runs.error_message is PLAIN TEXT (error.message), not JSON: a quote is not a
-- delimiter there, so mask the arguments up to the real end of line.
--   R5  Command failed: <cred script> <args...>   (to end of line)          -> <script> ***
CREATE OR REPLACE FUNCTION pg_temp.credlog_redact_text(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $f$
SELECT regexp_replace(t,
  '(Command failed: \./read/sh/(?:GE|Philips|Siemens/siemens_c)[^ \n]*) [^\n]+',
  '\1 ***', 'g')
$f$;
CREATE OR REPLACE FUNCTION pg_temp.credlog_residual_text(t text) RETURNS boolean
LANGUAGE sql IMMUTABLE AS $f$
SELECT t ~ 'Command failed: \./read/sh/(GE|Philips|Siemens/siemens_c)[^ \n]* (?!\*\*\*)'
$f$;

-- Tables in scope.
CREATE OR REPLACE TEMP VIEW credlog_tables AS
SELECT c.oid::regclass AS tbl, n.nspname AS schema_name, c.relname
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r' AND c.relname ~ '^app_run_logs_\d{4}_\d{2}$'
  AND n.nspname = ANY (string_to_array(current_setting('credlog.schemas'), ','));

SELECT tbl, pg_size_pretty(pg_total_relation_size(tbl)) AS size FROM credlog_tables ORDER BY 1;

-- 1. DRY RUN (read-only, full scan of every table in scope: hours) ----------------------
\if :{?dryrun}
\echo '== 1. dry run: rows that would change'
DO $$
DECLARE r record; c record;
BEGIN
  FOR r IN SELECT tbl FROM credlog_tables ORDER BY 1 LOOP
    FOR c IN EXECUTE format($q$
      SELECT app_name, to_char(inserted_at, 'YYYY-MM') AS m, count(*) AS would_change
      FROM %s
      WHERE inserted_at < current_setting('credlog.cutoff')::timestamptz
        AND pg_temp.credlog_candidate(verbose_log, warn_error_logs)
        AND (pg_temp.credlog_redact(verbose_log::text) IS DISTINCT FROM verbose_log::text
             OR pg_temp.credlog_redact(warn_error_logs::text) IS DISTINCT FROM warn_error_logs::text)
      GROUP BY 1, 2 ORDER BY 2, 1$q$, r.tbl)
    LOOP
      RAISE NOTICE '% | % | % | would_change=%', r.tbl, c.m, c.app_name, c.would_change;
    END LOOP;
  END LOOP;
END $$;
SELECT count(*) AS job_runs_would_change FROM stats.job_runs
WHERE run_datetime < current_setting('credlog.cutoff')::timestamptz
  AND error_message LIKE '%Command failed: ./read/sh/%'
  AND pg_temp.credlog_redact_text(error_message) IS DISTINCT FROM error_message;
\endif

-- 2. REHEARSAL on one day (read-only, minutes) -------------------------------------------
-- Expect: bad_json=0, residual_after=0, not_idempotent=0, would_change=residual_before.
\if :{?rehearse}
\if :{?rehearse_tbl}
\else
  \set rehearse_tbl util.app_run_logs_2026_11
\endif
\if :{?rehearse_day}
\else
  \set rehearse_day 2026-11-10
\endif
\echo '== 2. rehearsal on' :rehearse_tbl :rehearse_day
SELECT count(*)                                                                AS candidates,
       count(*) FILTER (WHERE nv IS DISTINCT FROM ov OR nw IS DISTINCT FROM ow) AS would_change,
       count(*) FILTER (WHERE pg_temp.credlog_residual(ov)
                           OR pg_temp.credlog_residual(coalesce(ow, '')))       AS residual_before,
       count(*) FILTER (WHERE pg_temp.credlog_residual(nv)
                           OR pg_temp.credlog_residual(coalesce(nw, '')))       AS residual_after,
       count(*) FILTER (WHERE NOT pg_input_is_valid(nv, 'json')
                           OR (nw IS NOT NULL AND NOT pg_input_is_valid(nw, 'json'))) AS bad_json,
       count(*) FILTER (WHERE pg_temp.credlog_redact(nv) IS DISTINCT FROM nv)   AS not_idempotent
FROM (SELECT verbose_log::text AS ov, warn_error_logs::text AS ow,
             pg_temp.credlog_redact(verbose_log::text) AS nv,
             pg_temp.credlog_redact(warn_error_logs::text) AS nw
      FROM :rehearse_tbl
      WHERE inserted_at >= :'rehearse_day'::date AND inserted_at < :'rehearse_day'::date + 1
        AND inserted_at < current_setting('credlog.cutoff')::timestamptz
        AND pg_temp.credlog_candidate(verbose_log, warn_error_logs) OFFSET 0) s;
\endif

-- 3. APPLY (WRITES) -----------------------------------------------------------------------
-- One transaction per table per day: a failure or cancel loses at most one day's batch and
-- locks stay short. Re-runnable: already-masked rows no longer change and are skipped.
\if :{?apply}
\echo '== 3. apply'
DO $$
DECLARE r record; d date; d_min date; d_max date; n bigint; total bigint;
BEGIN
  FOR r IN SELECT tbl FROM credlog_tables ORDER BY 1 LOOP
    EXECUTE format('SELECT min(inserted_at)::date, max(inserted_at)::date FROM %s WHERE inserted_at < current_setting(''credlog.cutoff'')::timestamptz', r.tbl)
      INTO d_min, d_max;
    total := 0;
    CONTINUE WHEN d_min IS NULL;
    d := d_min;
    WHILE d <= d_max LOOP
      EXECUTE format($q$
        UPDATE %s
        SET verbose_log     = pg_temp.credlog_redact(verbose_log::text)::json,
            warn_error_logs = pg_temp.credlog_redact(warn_error_logs::text)::json
        WHERE inserted_at >= %L AND inserted_at < least(%L::timestamptz, current_setting('credlog.cutoff')::timestamptz)
          AND pg_temp.credlog_candidate(verbose_log, warn_error_logs)
          AND (pg_temp.credlog_redact(verbose_log::text) IS DISTINCT FROM verbose_log::text
               OR pg_temp.credlog_redact(warn_error_logs::text) IS DISTINCT FROM warn_error_logs::text)$q$,
        r.tbl, d::timestamptz, (d + 1)::timestamptz);
      GET DIAGNOSTICS n = ROW_COUNT;
      total := total + n;
      COMMIT;
      d := d + 1;
    END LOOP;
    RAISE NOTICE '% updated=%', r.tbl, total;
  END LOOP;
END $$;
-- stats.job_runs (small: ~345k rows, 151 with an error_message on 2026-11-11, 0 with a
-- credential shape; this catches any written between that check and the deploy)
UPDATE stats.job_runs
SET error_message = pg_temp.credlog_redact_text(error_message)
WHERE run_datetime < current_setting('credlog.cutoff')::timestamptz
  AND error_message LIKE '%Command failed: ./read/sh/%'
  AND pg_temp.credlog_redact_text(error_message) IS DISTINCT FROM error_message;
\set verify 1
\endif

-- 4. VERIFY (read-only). Expect residual=0 for every table. -----------------------------
\if :{?verify}
\echo '== 4. verify'
DO $$
DECLARE r record; n bigint;
BEGIN
  FOR r IN SELECT tbl FROM credlog_tables ORDER BY 1 LOOP
    EXECUTE format($q$SELECT count(*) FROM %s
      WHERE inserted_at < current_setting('credlog.cutoff')::timestamptz
        AND pg_temp.credlog_candidate(verbose_log, warn_error_logs)
        AND (pg_temp.credlog_residual(verbose_log::text) OR pg_temp.credlog_residual(coalesce(warn_error_logs::text, '')))$q$, r.tbl)
      INTO n;
    RAISE NOTICE '% residual=%', r.tbl, n;
  END LOOP;
END $$;
SELECT count(*) FILTER (WHERE error_message LIKE '%Command failed:%') AS job_runs_with_command_failed,
       count(*) FILTER (WHERE pg_temp.credlog_residual_text(error_message)) AS job_runs_residual  -- expect 0
FROM stats.job_runs
WHERE run_datetime < current_setting('credlog.cutoff')::timestamptz;
\endif

-- 5. RECLAIM -----------------------------------------------------------------------------
-- UPDATE leaves the old row versions (with the credentials) in the table files until they
-- are vacuumed away; plain VACUUM only marks them reusable, VACUUM FULL rewrites the table
-- without them. VACUUM FULL takes an ACCESS EXCLUSIVE lock and needs free space for one copy
-- of the table. Archive tables and closed months: any time. The current month blocks
-- collector INSERTs while it runs (~minutes for ~3 GB): pick a quiet window. VACUUM cannot
-- run inside a transaction or DO block, so this prints the statements for you to run.
-- (pg_repack is available on the server but not installed; it would do the same online.)
\if :{?vacuum_list}
SELECT format('VACUUM (FULL, ANALYZE, VERBOSE) %s;', tbl) AS run_these FROM credlog_tables ORDER BY 1;
\endif

-- ALTERNATIVE TO 3: DELETE instead of redact (loses those rows' diagnostics). Same reclaim.
--   DELETE FROM <table>
--   WHERE inserted_at < current_setting('credlog.cutoff')::timestamptz
--     AND pg_temp.credlog_candidate(verbose_log, warn_error_logs)
--     AND (pg_temp.credlog_redact(verbose_log::text) IS DISTINCT FROM verbose_log::text
--          OR pg_temp.credlog_redact(warn_error_logs::text) IS DISTINCT FROM warn_error_logs::text);
-- ALTERNATIVE for archive_util (detached, not read by any app code): DROP TABLE
--   archive_util.app_run_logs_YYYY_MM;  frees the space at once, no VACUUM needed.
