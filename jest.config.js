module.exports = {
  // Test environment
  testEnvironment: 'node',

  // Test file patterns
  testMatch: [
    '**/tests/**/*.test.js',
    '**/__tests__/**/*.js'
  ],

  // Files to ignore
  testPathIgnorePatterns: [
    '/node_modules/'
  ],

  // Coverage configuration
  collectCoverageFrom: [
    'config/**/*.js',
    'jobs/**/*.js',
    'read/**/*.js',
    'util/**/*.js',
    '!**/node_modules/**'
  ],

  // Coverage thresholds (start low, increase as tests are added)
  coverageThreshold: {
    global: {
      branches: 10,
      functions: 10,
      lines: 10,
      statements: 10
    }
  },

  // Setup files
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],

  // Timeout for tests (useful for async operations)
  testTimeout: 10000,

  // Verbose output
  verbose: true
};
