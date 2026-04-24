#!/usr/bin/env bash
# Philips CT post-processing: convert Logger.mdb to Events.output and
# EALInfo.output. Called by exec-hhm_postprocess.js after a successful
# phil_ct_data_grab_*.sh run.
#
# Usage: phil_ct_convert.sh DEST_DIR
# Reads:  DEST_DIR/Logger.mdb
# Writes: DEST_DIR/Events.output, DEST_DIR/EALInfo.output
#
# This logic is shared across all 4 phil_ct_data_grab variants. Previously
# each pull script inlined its own copy of this block; the copies were
# byte-identical aside from whether the input was named Logger.mdb or
# Output.mdb. phil_ct_data_grab_3.sh now renames its scp target to
# Logger.mdb so this script can be uniform.

dest=$1

if [ -z "$dest" ]; then
  echo "Usage: $0 DEST_DIR" >&2
  exit 2
fi

if [ ! -f "$dest/Logger.mdb" ]; then
  echo "Logger.mdb not found in $dest" >&2
  exit 1
fi

test "$(ls -l "$dest/Logger.mdb" | awk '{print $5}')" -gt "0" && chmod +0644 "$dest/Logger.mdb"

EALINFO_TABLEVAR=$(mdb-tables "$dest/Logger.mdb" | sed 's/ /\n/g' | sed -n 1p)
EVENTS_TABLEVAR=$(mdb-tables "$dest/Logger.mdb" | sed 's/ /\n/g' | sed -n 2p)

touch "$dest/Events.output"
test "$(ls -l "$dest/Events.output" | awk '{print $5}')" -gt "0" && echo -n "" >"$dest/Events.output"

touch "$dest/EALInfo.output"
test "$(ls -l "$dest/EALInfo.output" | awk '{print $5}')" -gt "0" && echo -n "" >"$dest/EALInfo.output"

echo "Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime" >>"$dest/Events.output"
# IN ORDER PIPED COMMANDS:
# EXPORT FROM MDB
# REMOVE ALL NON-ALPHANUMERIC CHARACTERS, KEEP THOSE IN SINGLE QUOTES
# REORDER COLUMNS
# SORT REORDERED COLUMNS
# REMOVE ALL NON-COMPLIANT ROWS
# OUTPUT FILE
mdb-export "$dest/Logger.mdb" "$EVENTS_TABLEVAR" | tr -cd [:alnum:]'\n''\ ''"'',''['']'':''\-''_''.''/''=' | awk -v FS="," '{print $9, $1, $2, $3, $4, $5, $6, $7, $8}' | sort | sed -n -e "/^\"[0-9][0-9]\/.*/p" >>"$dest/Events.output"

echo "DTime,Controller,DataType,LogNumber,TmStamp,ERR_TYPE,ErrNum,vxwErrNo,File,Line,Param1,Param2,Info,EalTime" >>"$dest/EALInfo.output"
mdb-export "$dest/Logger.mdb" "$EALINFO_TABLEVAR" | tail -n +2 | sort | awk 'NF > 2' >>"$dest/EALInfo.output"
