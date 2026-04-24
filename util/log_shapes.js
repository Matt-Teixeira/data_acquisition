// Shared log-shape helpers used across data_acquisition jobs and exec wrappers.
// Kept here (not in utils/logger) because they assume this app's data shapes
// and should not leak into the shared logger.

// Return a copy of args with the given indexes replaced by "***". The caller's
// live args array is untouched. Default [1, 2] matches the HHM shell-script
// convention of [host_ip, user, password, ...]; callers with a different
// positional layout (e.g. rsync wrappers with user_id elsewhere) pass their own.
const redactArgsForLog = (args, indexes = [1, 2]) => {
  const copy = Array.isArray(args) ? [...args] : [];
  for (const i of indexes) if (i >= 0 && i < copy.length) copy[i] = "***";
  return copy;
};

// Compact subset of a `systems`-table row for log notes. The full row is
// ~300 chars and repeats per-system per-event; the subset keeps enough for
// debugging across HHM / MMB / philips_mri row shapes. Unknown columns drop.
const SYSTEM_LOG_FIELDS = [
  "id",
  "host_ip",
  "modality",
  "manufacturer",
  "acquisition_script",
  "vpn",
  "system_id",
  "mmb_ip",
  "user_id",
  "host_path",
];
const systemLogShape = (s) => {
  if (!s || typeof s !== "object") return s;
  const out = {};
  for (const k of SYSTEM_LOG_FIELDS) if (s[k] !== undefined) out[k] = s[k];
  return out;
};

module.exports = { redactArgsForLog, systemLogShape };
