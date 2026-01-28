/**
 * Centralized configuration module.
 * Provides environment-aware paths and validates required environment variables.
 */

const REQUIRED_ENV_VARS = [
  'RUN_ENV',
  'PG_HOST',
  'PG_PORT',
  'PG_DB',
  'PG_USER',
  'PG_PW'
];

const PATH_ENV_VARS = {
  dev: 'DEV_HHM_FILES',
  staging: 'STAGING_HHM_FILES',
  prod: 'PROD_HHM_FILES'
};

/**
 * Validates that all required environment variables are set.
 * Call this at application startup.
 * @throws {Error} If any required variable is missing
 */
function validateEnvironment() {
  const missing = REQUIRED_ENV_VARS.filter(varName => !process.env[varName]);

  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }

  const runEnv = process.env.RUN_ENV;
  if (!['dev', 'staging', 'prod'].includes(runEnv)) {
    throw new Error(`Invalid RUN_ENV value: ${runEnv}. Must be 'dev', 'staging', or 'prod'`);
  }

  // Validate path env var exists for current environment
  const pathVar = PATH_ENV_VARS[runEnv];
  if (!process.env[pathVar]) {
    throw new Error(`Missing path environment variable for ${runEnv}: ${pathVar}`);
  }
}

/**
 * Gets the current runtime environment.
 * @returns {'dev' | 'staging' | 'prod'}
 */
function getEnvironment() {
  return process.env.RUN_ENV;
}

/**
 * Gets the HHM files storage path for the current environment.
 * Replaces scattered switch statements on RUN_ENV.
 * @returns {string} The data store path
 */
function getHhmFilesPath() {
  const runEnv = process.env.RUN_ENV;
  const pathVar = PATH_ENV_VARS[runEnv];
  return process.env[pathVar] || '';
}

/**
 * Gets the full path for a specific system's data.
 * @param {string} systemId - The system ID (e.g., 'SME00001')
 * @returns {string} Full path like '/home/prod/hhm_data_acquisition/files/prod_hhm/SME00001'
 */
function getSystemDataPath(systemId) {
  return `${getHhmFilesPath()}/${systemId}`;
}

/**
 * Checks if running in development mode.
 * @returns {boolean}
 */
function isDev() {
  return process.env.RUN_ENV === 'dev';
}

/**
 * Checks if running in production mode.
 * @returns {boolean}
 */
function isProd() {
  return process.env.RUN_ENV === 'prod';
}

/**
 * Checks if running in staging mode.
 * @returns {boolean}
 */
function isStaging() {
  return process.env.RUN_ENV === 'staging';
}

module.exports = {
  validateEnvironment,
  getEnvironment,
  getHhmFilesPath,
  getSystemDataPath,
  isDev,
  isProd,
  isStaging,
  REQUIRED_ENV_VARS
};
