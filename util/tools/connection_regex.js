// TEST stderr FOR CONNECTION ERROR
function extractConnectionError(text, regexes) {
  for (let regex of regexes) {
    const is_match = regex.re.test(text);

    if (is_match) return regex;
  }
  return null;
}

const connection_regexes = [
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    message: "Connection timed out",
    manual_intervention: false,
    successful_acquisition: false,
    re: /Connection timed out/
  },
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    message: "max-retries exceeded",
    manual_intervention: false,
    successful_acquisition: false,
    re: /error: max-retries exceeded/
  },
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    message: "host may be offline",
    manual_intervention: false,
    successful_acquisition: false,
    re: /Connection to (?<ip>\d{1,3}(?:\.\d{1,3}){3}) port (?<port>\d+) timed out/gi
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "file",
    message: "file not present",
    manual_intervention: true,
    successful_acquisition: false,
    re: /(scp|tar): No match/gi
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "key",
    message: "remote host identification has changed",
    manual_intervention: true,
    successful_acquisition: false,
    re: /remote host identification has changed/gi
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "key",
    message: "confirm the new fingerprint and update known hosts",
    manual_intervention: true,
    successful_acquisition: true,
    re: /Warning:\sPermanently\sadded\s'\d+\.\d+\.\d+\.\d+'.+to\sthe\slist\sof\sknown\shosts|Error:\sCommand\sfailed/g
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "key",
    message: "no matching key exchange method found",
    manual_intervention: true,
    successful_acquisition: false,
    re: /Unable to negotiate with \d+\.\d+\.\d+\.\d+.+/gi
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "credentials",
    message: "update credentials",
    manual_intervention: true,
    successful_acquisition: false,
    re: /Login failed|Login incorrect/gi
  }
];
// /Login failed|Login incorrect/gi
module.exports = { extractConnectionError, connection_regexes };
