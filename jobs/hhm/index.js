const { acquireHhmData, ACQUISITION_CONFIG } = require("./acquisition");
const { get_philips_cv_data } = require("./philips/philips_cv");
const get_siemens_cv_data = require("./siemens/siemens_cv");

const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, E },
  tag: { cal, cat }
} = require("../../utils/logger/enums");

/**
 * Main entry point for HHM data acquisition.
 * Routes to the generic factory for standard acquisitions,
 * or to specialized functions for complex workflows (Philips CV, Siemens CV).
 */
const get_hhm_data = async (run_log, manufacturer, modality, capture_datetime) => {
  const funcName = "get_hhm_data";
  await addLogEvent(I, run_log, funcName, cal, { manufacturer, modality }, null);

  try {
    // Special cases with complex workflows that can't use the generic factory
    if (manufacturer === "Philips" && modality === "CV") {
      await get_philips_cv_data(run_log, capture_datetime);
      return;
    }
    if (manufacturer === "Siemens" && modality === "CV") {
      await get_siemens_cv_data(run_log, capture_datetime);
      return;
    }

    // Check if combination is supported by the factory
    const normalizedModality = modality === "CV" ? "CV/IR" : modality;
    const configKey = `${manufacturer}:${normalizedModality}`;

    if (!ACQUISITION_CONFIG[configKey]) {
      await addLogEvent(E, run_log, funcName, cat, {
        message: `Unsupported combination: ${configKey}`
      }, null);
      return;
    }

    // Use generic factory for standard acquisitions
    await acquireHhmData(run_log, capture_datetime, manufacturer, modality);
  } catch (error) {
    await addLogEvent(E, run_log, funcName, cat, { manufacturer, modality }, error);
  }
};

module.exports = get_hhm_data;
