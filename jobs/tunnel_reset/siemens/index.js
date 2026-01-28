const get_siemens_ct_data = require("./siemens_ct");
const get_siemens_cv_data = require("./siemens_cv");
const get_siemens_mri_data = require("./siemens_mri");
const [addLogEvent] = require("../../../utils/logger/log");
const {
  type: { E },
  tag: { cat }
} = require("../../../utils/logger/enums");

async function get_siemens_data(job_id, run_log, system, capture_datetime, ip_reset) {
  try {
    switch (system.modality) {
      case "CT":
        await get_siemens_ct_data(job_id, run_log, system, capture_datetime, ip_reset);
        break;
      case "CV/IR":
        await get_siemens_cv_data(job_id, run_log, system, capture_datetime, ip_reset);
        break;
      case "MRI":
        await get_siemens_mri_data(job_id, run_log, system, capture_datetime, ip_reset);
        break;
      default:
        break;
    }
  } catch (error) {
    await addLogEvent(E, run_log, "get_siemens_data:tunnel_reset", cat, { system: system.id }, error);
  }
}

module.exports = get_siemens_data;
