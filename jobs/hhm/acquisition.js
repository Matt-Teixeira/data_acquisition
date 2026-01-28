const exec_hhm_data_grab = require("../../read/exec-hhm_data_grab");
const { get_hhm, getHhmCreds, get_phil_mri_host } = require("../../sql/qf-provider");
const { decryptString } = require("../../util");
const { v4: uuidv4 } = require("uuid");
const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat }
} = require("../../utils/logger/enums");

/**
 * Configuration for each manufacturer/modality combination.
 * Defines how to fetch systems, whether credentials are needed,
 * and how to build exec arguments.
 */
const ACQUISITION_CONFIG = {
  "GE:CT": {
    queryFn: get_hhm,
    queryParams: ["GE", "CT"],
    useCredentials: true,
    buildExecArgs: (system, user, pass) => [system.host_ip, user, pass]
  },
  "GE:CV/IR": {
    queryFn: get_hhm,
    queryParams: ["GE", "CV/IR"],
    useCredentials: true,
    buildExecArgs: (system, user, pass) => [system.host_ip, user, pass]
  },
  "GE:MRI": {
    queryFn: get_hhm,
    queryParams: ["GE", "MRI"],
    useCredentials: true,
    buildExecArgs: (system, user, pass) => [system.host_ip, user, pass]
  },
  "Philips:CT": {
    queryFn: get_hhm,
    queryParams: ["Philips", "CT"],
    useCredentials: true,
    buildExecArgs: (system, user, pass) => [system.host_ip, user, pass]
  },
  "Philips:MRI": {
    queryFn: get_phil_mri_host,
    queryParams: ["Philips", "MRI"],
    useCredentials: true,
    buildExecArgs: (system, user, pass) => [system.host_ip, user, pass]
  },
  "Siemens:CT": {
    queryFn: get_hhm,
    queryParams: ["Siemens", "%CT"],
    useCredentials: false,
    buildExecArgs: (system) => [system.host_ip]
  },
  "Siemens:MRI": {
    queryFn: get_hhm,
    queryParams: ["Siemens", "MRI"],
    useCredentials: false,
    buildExecArgs: (system) => [system.host_ip]
  }
};

/**
 * Generic HHM data acquisition function.
 * Replaces the individual manufacturer/modality-specific functions.
 *
 * @param {Object} run_log - The run log object for tracking
 * @param {string} capture_datetime - ISO timestamp for the capture
 * @param {string} manufacturer - "GE", "Philips", or "Siemens"
 * @param {string} modality - "CT", "CV", "MRI" (CV gets mapped to CV/IR)
 */
async function acquireHhmData(run_log, capture_datetime, manufacturer, modality) {
  // Map "CV" to "CV/IR" for consistency with database values
  const normalizedModality = modality === "CV" ? "CV/IR" : modality;
  const configKey = `${manufacturer}:${normalizedModality}`;
  const funcName = `acquireHhmData:${manufacturer}:${normalizedModality}`;

  await addLogEvent(I, run_log, funcName, cal, null, null);

  const config = ACQUISITION_CONFIG[configKey];
  if (!config) {
    const error = new Error(`Unsupported manufacturer/modality combination: ${configKey}`);
    await addLogEvent(E, run_log, funcName, cat, { configKey }, error);
    throw error;
  }

  // Fetch systems
  const systems = await config.queryFn(config.queryParams);

  // Fetch credentials if needed
  let credentials = [];
  if (config.useCredentials) {
    credentials = await getHhmCreds(config.queryParams);
  }

  const child_processes = [];

  for (const system of systems) {
    const job_id = uuidv4();
    const note = { job_id, system };

    try {
      await addLogEvent(I, run_log, funcName, det, note, null);

      // Skip systems without required fields
      if (!system.host_ip) continue;
      if (config.useCredentials && !system.credentials_group) continue;
      if (!system.acquisition_script) continue;

      // Build script path
      const scriptPath = `./read/sh/${manufacturer}/${system.acquisition_script}`;

      // Get credentials if needed
      let execArgs;
      if (config.useCredentials) {
        const systemCreds = credentials.find(
          (credential) => credential.id === system.credentials_group
        );
        if (!systemCreds) {
          await addLogEvent(W, run_log, funcName, cat, {
            job_id,
            system: system.id,
            message: "No matching credentials found"
          }, null);
          continue;
        }
        const user = decryptString(systemCreds.user_enc);
        const pass = decryptString(systemCreds.password_enc);
        execArgs = config.buildExecArgs(system, user, pass);
      } else {
        execArgs = config.buildExecArgs(system);
      }

      child_processes.push(
        async () =>
          await exec_hhm_data_grab(
            job_id,
            run_log,
            system.id,
            scriptPath,
            system,
            execArgs,
            capture_datetime
          )
      );
    } catch (error) {
      await addLogEvent(E, run_log, funcName, cat, note, error);
    }
  }

  try {
    await addLogEvent(I, run_log, `${funcName}:run_child_processes`, cal, null, null);
    const promises = child_processes.map((child_process) => child_process());
    await Promise.all(promises);
  } catch (error) {
    await addLogEvent(E, run_log, `${funcName}:run_child_processes`, cat, null, error);
  }
}

module.exports = { acquireHhmData, ACQUISITION_CONFIG };
