const fs = require("fs").promises;
const path = require("path");

async function file_exists(directory, filename) {
  try {
    await fs.access(path.join(directory, filename));
    return true;
  } catch {
    return false;
  }
}

module.exports = { file_exists };
