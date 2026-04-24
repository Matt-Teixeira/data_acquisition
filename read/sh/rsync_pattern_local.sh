#!/bin/bash

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue

# Batch-sync files matching a filename glob from a source directory into a
# destination directory in a SINGLE rsync invocation (replaces per-file forks).

# $1: source dir   (e.g., /workspace/files/SME18368/host_logfiles)
# $2: dest dir     (e.g., /workspace/files/SME18368/rmmu)
# $3: include glob (e.g., rmmu[0-9]*.log)

mkdir -p "$2"

rsync -rz \
  --include="$3" \
  --exclude='*' \
  "$1/" \
  "$2/"
