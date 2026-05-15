const db = require("../../../db/pgPool");
const { demo_mag, demo_edu, demo_phil_mri } = require("./sql");

const get_demo_mag_systems = async () => db.any(demo_mag);
const get_demo_edu_systems = async () => db.any(demo_edu);
const get_demo_phil_mri_systems = async () => db.any(demo_phil_mri);

module.exports = {
  get_demo_mag_systems,
  get_demo_edu_systems,
  get_demo_phil_mri_systems,
};
