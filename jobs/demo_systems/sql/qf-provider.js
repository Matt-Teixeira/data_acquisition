const db = require("../../../db/pgPool");
const {
  demo_mag,
  demo_edu,
  demo_phil_mri,
  demo_ge_hhm,
  demo_siemens_hhm,
  demo_philips_hhm,
} = require("./sql");

const get_demo_mag_systems = async () => db.any(demo_mag);
const get_demo_edu_systems = async () => db.any(demo_edu);
const get_demo_phil_mri_systems = async () => db.any(demo_phil_mri);
const get_demo_ge_hhm_systems = async () => db.any(demo_ge_hhm);
const get_demo_siemens_hhm_systems = async () => db.any(demo_siemens_hhm);
const get_demo_philips_hhm_systems = async () => db.any(demo_philips_hhm);

module.exports = {
  get_demo_mag_systems,
  get_demo_edu_systems,
  get_demo_phil_mri_systems,
  get_demo_ge_hhm_systems,
  get_demo_siemens_hhm_systems,
  get_demo_philips_hhm_systems,
};
