# shellcheck shell=bash
# Sourced by phil_mri_data_grab_{1,2,3,4,5,6,7,8,10}.sh.
#
# Centralizes the two axes that previously drifted across 9 near-identical
# scripts: the SSH KexAlgorithm bundles and the directory-setup boilerplate.
# Category and path combinations are NOT consolidated here — each script
# still owns its own lftp command body because every host pulls a different
# mix of files from different remote paths.
#
# MODERN: most Philips MRI hosts. LEGACY: older hosts that only accept
# deprecated algorithms (+ssh-rsa/ssh-dss + group14-sha1 enabled, strict
# host-key check relaxed to accept-new).

SSH_OPTS_MODERN='-oConnectTimeout=10 -oServerAliveInterval=10 -oServerAliveCountMax=6 -oKexAlgorithms=diffie-hellman-group14-sha1'
SSH_OPTS_LEGACY='-oConnectTimeout=10 -oServerAliveInterval=10 -oServerAliveCountMax=6 -oKexAlgorithms=+diffie-hellman-group14-sha1 -oHostKeyAlgorithms=+ssh-rsa,ssh-dss -oPubkeyAcceptedAlgorithms=+ssh-rsa -oStrictHostKeyChecking=accept-new'

# ensure_dirs DEST SUBDIR1 [SUBDIR2 ...]
# Creates DEST then each SUBDIR under it (only if missing).
ensure_dirs() {
  local dest=$1
  shift
  [ ! -d "$dest" ] && mkdir "$dest"
  for sub in "$@"; do
    [ ! -d "$dest/$sub" ] && mkdir "$dest/$sub"
  done
}
