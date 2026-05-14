const { get_hhm, get_phil_mri_host, getHhmCreds } = require("../../sql/qf-provider");
const { decrypt_string } = require("../../util/encrypt/decrypt");

// Central registry of per-job configs for the HHM shared runner. Both the
// main-run adapters (jobs/hhm/{ge,philips,siemens}/*.js) and the
// tunnel_reset retry path import from here — ensures the two paths can
// never drift.
//
// Registry key: `${manufacturer}:${modality}` where modality is the DB value
// stored on system rows (NOT the SQL LIKE pattern some main-run jobs use
// for initial fetch). The main-run config may fetch with `%CT`, but the
// DB rows that come back have modality="CT", which is what tunnel_reset's
// lookup will see.
//
// philips_cv (outlier — multi-stage exec_phil_cv_data_grab pipeline) is
// deliberately NOT in this registry. tunnel_reset still dispatches it
// through its dedicated file.

const PHILIPS_MRI_SHELL_TIMEOUT_S =
  Number(process.env.PHILIPS_MRI_SHELL_TIMEOUT_S) || 300;

const ge_credDecryptArgs = (system, creds) => [
  system.host_ip,
  decrypt_string(creds.user_enc),
  decrypt_string(creds.password_enc),
];

const geCt = {
  jobName: "ge_ct",
  logLabel: "get_ge_ct_data",
  manufacturer: "GE",
  modality: "CT",
  shellSubdir: "GE",
  fetchSystems: get_hhm,
  fetchCredentials: getHhmCreds,
  argsBuilder: ge_credDecryptArgs,
};

const geCv = {
  jobName: "ge_cv",
  logLabel: "get_ge_cv_data",
  manufacturer: "GE",
  modality: "CV/IR",
  shellSubdir: "GE",
  fetchSystems: get_hhm,
  fetchCredentials: getHhmCreds,
  argsBuilder: ge_credDecryptArgs,
};

const geMri = {
  jobName: "ge_mri",
  logLabel: "get_ge_mri_data",
  manufacturer: "GE",
  modality: "MRI",
  shellSubdir: "GE",
  fetchSystems: get_hhm,
  fetchCredentials: getHhmCreds,
  argsBuilder: ge_credDecryptArgs,
};

const philipsCt = {
  jobName: "philips_ct",
  logLabel: "get_philips_ct_data",
  manufacturer: "Philips",
  modality: "CT",
  shellSubdir: "Philips",
  fetchSystems: get_hhm,
  fetchCredentials: getHhmCreds,
  argsBuilder: ge_credDecryptArgs,
  postProcessScript: "./read/sh/Philips/phil_ct_convert.sh",
};

const philipsMri = {
  jobName: "philips_mri",
  logLabel: "get_philips_mri_data",
  manufacturer: "Philips",
  modality: "MRI",
  shellSubdir: "Philips",
  fetchSystems: get_phil_mri_host,
  fetchCredentials: getHhmCreds,
  argsBuilder: ge_credDecryptArgs,
  extraExecArgs: [PHILIPS_MRI_SHELL_TIMEOUT_S],
};

const siemensCt = {
  jobName: "siemens_ct",
  logLabel: "get_siemens_ct_data",
  manufacturer: "Siemens",
  // Main-run SQL uses "%CT" LIKE pattern, but DB rows that match store
  // modality="CT" (which is what the registry lookup sees on retry).
  modality: "%CT",
  shellSubdir: "Siemens",
  fetchSystems: get_hhm,
  argsBuilder: (system) => [system.host_ip],
};

const siemensCv = {
  jobName: "siemens_cv",
  logLabel: "get_siemens_cv_data",
  manufacturer: "Siemens",
  modality: "CV/IR",
  shellSubdir: "Siemens",
  fetchSystems: get_hhm,
  fetchCredentials: getHhmCreds,
  hostPredicate: (sys) => Boolean(sys.acquisition_script && sys.host_ip),
  argsBuilder: (system, creds) => [
    system.host_ip,
    decrypt_string(creds.user_enc),
    decrypt_string(creds.password_enc),
    system.host_path,
    system.cerb_file,
  ],
};

const siemensMri = {
  jobName: "siemens_mri",
  logLabel: "get_siemens_mri_data",
  manufacturer: "Siemens",
  modality: "MRI",
  shellSubdir: "Siemens",
  fetchSystems: get_hhm,
  argsBuilder: (system) => [system.host_ip],
};

// Lookup map for tunnel_reset retry path. Keyed on (manufacturer, system.modality)
// where system.modality is the DB value. For siemens_ct, that's "CT" — not the
// "%CT" LIKE pattern used for main-run fetch.
//
// "Siemens:PET/CT" alias: PET/CT scanners are operated as CT scanners — same
// acquisition_script, same log files, same retry semantics. The main-run
// siemens_ct path already picks them up because its SQL filter uses
// `modality LIKE '%CT'` (matches both "CT" and "PET/CT"), but on retry the
// system row carries modality="PET/CT" and would hit "No HHM config registered"
// without this alias. Pointing the alias at the same siemensCt object keeps
// per-(manufacturer, modality) credential caching coherent in tunnel_reset.
const registry = {
  "GE:CT": geCt,
  "GE:CV/IR": geCv,
  "GE:MRI": geMri,
  "Philips:CT": philipsCt,
  "Philips:MRI": philipsMri,
  "Siemens:CT": siemensCt,
  "Siemens:PET/CT": siemensCt,
  "Siemens:CV/IR": siemensCv,
  "Siemens:MRI": siemensMri,
};

const getConfig = (manufacturer, modality) =>
  registry[`${manufacturer}:${modality}`] || null;

module.exports = {
  geCt,
  geCv,
  geMri,
  philipsCt,
  philipsMri,
  siemensCt,
  siemensCv,
  siemensMri,
  getConfig,
};
