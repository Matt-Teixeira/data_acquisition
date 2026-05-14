// TEST stderr / stdout / error.message FOR CONNECTION OR EXTRACTION ERROR
// Returns the first matching regex-entry object, or null.
// Each entry carries a structured error_category that is persisted downstream.
//
// NOTE: regex patterns below deliberately do NOT use the /g flag.
// RegExp.prototype.test() with /g is stateful - it advances lastIndex on each
// match, so calling .test() repeatedly on the same (shared) regex object against
// different inputs produces order-dependent false negatives. Since we only need
// a boolean match here, /g is unnecessary and actively harmful. Keep /i where
// case-insensitivity matters.
//
// ORDERING PRINCIPLE: first match wins. Order patterns so ROOT-CAUSE signals
// beat DOWNSTREAM symptoms. Example: when SSH auth fails (`Permission denied
// (publickey)`), rsync reports `connection unexpectedly closed` as a downstream
// symptom in the same stderr - the auth signal must be checked first.
function extractConnectionError(text, regexes) {
  for (let regex of regexes) {
    const is_match = regex.re.test(text);

    if (is_match) return regex;
  }
  return null;
}

const connection_regexes = [
  // -- Connectivity (network layer) --
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "connection_timeout",
    message: "Connection timed out",
    manual_intervention: false,
    successful_acquisition: false,
    re: /Connection timed out/
  },
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "max_retries",
    message: "max-retries exceeded",
    manual_intervention: false,
    successful_acquisition: false,
    re: /error: max-retries exceeded/
  },
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "connection_timeout",
    message: "host may be offline",
    manual_intervention: false,
    successful_acquisition: false,
    re: /Connection to (?<ip>\d{1,3}(?:\.\d{1,3}){3}) port (?<port>\d+) timed out/i
  },
  // Session-level timeout: TCP/SSH handshake succeeded but the server went
  // silent mid-session (common scp/lftp signature when a host accepts the
  // connection but then stops responding). Ranked BEFORE host_key_new so that
  // when both signals appear in one stderr (auto-accepted key + server drop),
  // the hard failure signal wins over the soft warning.
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "session_timeout",
    message: "server stopped responding mid-session",
    manual_intervention: false,
    successful_acquisition: false,
    re: /Timeout, server \d{1,3}(?:\.\d{1,3}){3} not responding/
  },
  // -- curl-specific families (mined from real logs) --
  // Partial transfer: remote accepted the connection but stalled mid-stream.
  // Check this BEFORE the generic curl-28 timeout so the more specific pattern wins.
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "partial_transfer_timeout",
    message: "partial transfer - remote stalled mid-stream",
    manual_intervention: false,
    successful_acquisition: false,
    re: /curl: \(28\) Operation timed out after \d+ milliseconds with \d+(?: out of \d+)? bytes received/
  },
  // curl exit 28 (CURLE_OPERATION_TIMEDOUT). Four real-log shapes:
  //   1. "curl: (28) Connection timed out"
  //   2. "curl: (28) Operation timed out"
  //   3. "curl: (28) Failed to connect to <host> port <p> after <N> ms:
  //       Timeout was reached"
  //   4. "curl: (28) Connection timeout after <N> ms"   (noun form)
  // Shapes 3 and 4 fell through to error_category="unknown" on the Siemens
  // curl-based pipeline (siemens_443/80_data_grab.sh hitting dead hospital
  // hosts; different curl builds emit different message bodies — observed
  // on ip_reset retries against SME00874, SME01118). All four are
  // connect-timeout signals → same category, retry-eligible.
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "connection_timeout",
    message: "curl timeout",
    manual_intervention: false,
    successful_acquisition: false,
    re: /curl: \(28\) (?:Connection|Operation) timed out|curl: \(28\) Failed to connect to .+? port \d+ after \d+ ms|curl: \(28\) Connection timeout after \d+ ms/
  },
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "connection_reset",
    message: "peer reset connection",
    manual_intervention: false,
    successful_acquisition: false,
    re: /curl: \(56\) Recv failure: Connection reset by peer/
  },
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "http2_cancel",
    message: "HTTP/2 stream cancelled",
    manual_intervention: false,
    successful_acquisition: false,
    re: /curl: \(92\) HTTP\/2 stream \d+ was not closed cleanly/
  },
  // -- ssh/scp/rsync transport --
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "host_unreachable",
    message: "no route to host",
    manual_intervention: false,
    successful_acquisition: false,
    re: /(?:ssh|scp|rsync): connect to host \d{1,3}(?:\.\d{1,3}){3} port \d+: No route to host/
  },
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "connection_refused",
    message: "connection refused",
    manual_intervention: false,
    successful_acquisition: false,
    re: /(?:ssh|scp|rsync): connect to host \d{1,3}(?:\.\d{1,3}){3} port \d+: Connection refused/
  },
  // -- SSH auth / host-key signals (ROOT CAUSES) --
  // These live HERE - above the generic rsync-symptom block - because when
  // SSH auth fails, rsync downstream reports "connection unexpectedly closed"
  // as a symptom in the same stderr. The auth signal is the real cause and
  // must win so the system skips the tunnel-reset retry cycle (which wouldn't
  // help an auth failure anyway) and lands in the right category.
  {
    connection_error: false,
    extraction_error: true,
    error_type: "key",
    error_category: "host_key_changed",
    message: "remote host identification has changed",
    manual_intervention: true,
    successful_acquisition: false,
    re: /remote host identification has changed/i
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "key",
    error_category: "host_key_new",
    // Container's ssh has lax StrictHostKeyChecking and silently auto-accepts
    // new host keys. A "Permanently added" warning with a non-zero exit is a
    // signal that the host's key changed - admin should verify the fingerprint
    // against the real host (it may indicate a legitimate reinstall, or a real
    // MITM / identification-has-changed scenario the container masked away).
    message: "host key changed - container auto-accepted new key, verify fingerprint",
    manual_intervention: true,
    successful_acquisition: false,
    // NOTE: the former "|Error:\sCommand failed" branch was removed - it matched
    // every execFile rejection (Node wraps shell failures as "Command failed: ...")
    // and produced false-positive "key" classifications on unrelated errors.
    re: /Warning:\sPermanently\sadded\s'\d+\.\d+\.\d+\.\d+'.+to\sthe\slist\sof\sknown\shosts/
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "key",
    error_category: "key_exchange",
    message: "no matching key exchange method found",
    manual_intervention: true,
    successful_acquisition: false,
    re: /Unable to negotiate with \d+\.\d+\.\d+\.\d+.+/i
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "credentials",
    error_category: "credentials",
    message: "update credentials",
    manual_intervention: true,
    successful_acquisition: false,
    re: /Login failed|Login incorrect/i
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "credentials",
    error_category: "credentials",
    message: "publickey auth refused",
    manual_intervention: true,
    successful_acquisition: false,
    re: /Permission denied \(publickey/
  },
  // -- rsync-specific (MMB path) - downstream symptoms --
  // rsync peer disconnected mid-transfer or broken pipe during send/receive.
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "connection_reset",
    message: "rsync connection closed by peer",
    manual_intervention: false,
    successful_acquisition: false,
    re: /rsync: connection unexpectedly closed|Broken pipe/
  },
  // rsync I/O timeout (exit code 30): connection established, data transfer
  // stalled mid-stream. Common MMB failure when a host becomes unresponsive
  // after the rsync handshake.
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "rsync_io_timeout",
    message: "rsync I/O timeout - data transfer stalled",
    manual_intervention: false,
    successful_acquisition: false,
    re: /rsync error: timeout in data send\/receive/
  },
  // rsync protocol / stream error - transient network disruption mid-transfer.
  {
    connection_error: true,
    extraction_error: false,
    error_type: "connection",
    error_category: "rsync_protocol_error",
    message: "rsync protocol / stream error",
    manual_intervention: false,
    successful_acquisition: false,
    re: /error in rsync protocol data stream/
  },
  // -- Per-file extraction errors --
  // lftp mget partial failures: connection worked, script pulled most files,
  // but some files hit per-file permission or missing-file errors. These are
  // PARTIAL successes - data was acquired, just flag for ops review.
  {
    connection_error: false,
    extraction_error: true,
    error_type: "file",
    error_category: "permission_denied_partial",
    message: "file-level permission denied on host (partial pull)",
    manual_intervention: true,
    successful_acquisition: true,
    re: /mget: Access failed: Permission denied/
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "file",
    error_category: "file_missing_partial",
    message: "some requested files not present on host (partial pull)",
    manual_intervention: false,
    successful_acquisition: true,
    re: /mget: Access failed: No such file/
  },
  // Philips CV (Windows FTP): file-not-found via FTP 550 response code.
  // Analog to GE's "mget: Access failed: No such file" above.
  {
    connection_error: false,
    extraction_error: true,
    error_type: "file",
    error_category: "file_missing_partial",
    message: "some requested files not present on host (partial pull)",
    manual_intervention: false,
    successful_acquisition: true,
    re: /mget: Access failed: 550/
  },
  // lftp wildcard non-match: when an mget pattern matches zero files on the
  // remote, lftp emits "<pattern>: no files found" and (with cmd:fail-exit yes,
  // as in GE shell scripts) terminates the whole script non-zero. Connection
  // and earlier transfers were healthy; this is benign partial-pull state.
  {
    connection_error: false,
    extraction_error: true,
    error_type: "file",
    error_category: "file_missing_partial",
    message: "no files matched mget wildcard (partial pull)",
    manual_intervention: false,
    successful_acquisition: true,
    re: /mget: \S+: no files found/i
  },
  // lftp mirror per-file failure - common on Philips CV where Windows file
  // locks during scanner operation prevent lftp from opening specific .zip
  // files (Logging.zip, PersistentData.zip, Setup.zip). The mirror command
  // continues and transfers other files; just the locked ones get skipped.
  //
  // Two stderr shapes occur in practice:
  //   1. "mirror: <file>: <cause>"           e.g. "mirror: Logging.zip: open failed"
  //   2. "mirror: Access failed: 550 ..."    Windows FTP 550 with the filename
  //                                          in trailing parens
  // The second shape was previously falling through to error_category="unknown"
  // (e.g. SME00444 / Setup.zip), so the alternation below catches both.
  {
    connection_error: false,
    extraction_error: true,
    error_type: "file",
    error_category: "mirror_file_skipped",
    message: "some files skipped by lftp mirror (likely host-side file locks)",
    manual_intervention: false,
    successful_acquisition: true,
    re: /mirror: \S+: |mirror: Access failed: 550/
  },
  // rsync [sender] source file missing - typically means upstream remote-rsync
  // step didn't produce the expected file. Local-step symptom of upstream
  // failure. MUST be checked before rsync_partial so the specific cause wins.
  {
    connection_error: false,
    extraction_error: true,
    error_type: "file",
    error_category: "rsync_source_missing",
    message: "rsync source file missing (upstream pull likely incomplete)",
    manual_intervention: false,
    successful_acquisition: false,
    re: /rsync: \[sender\] link_stat .+ failed: No such file or directory/
  },
  // rsync exit code 23 wrapper: "some files/attrs were not transferred".
  // Connection worked and at least some files moved; some were skipped.
  {
    connection_error: false,
    extraction_error: true,
    error_type: "file",
    error_category: "rsync_partial",
    message: "rsync partial transfer - some files skipped",
    manual_intervention: false,
    successful_acquisition: true,
    re: /rsync error: some files\/attrs were not transferred/
  },
  {
    connection_error: false,
    extraction_error: true,
    error_type: "file",
    error_category: "file_missing",
    message: "file not present",
    manual_intervention: true,
    successful_acquisition: false,
    re: /(scp|tar): No match/i
  }
];

module.exports = { extractConnectionError, connection_regexes };
