#!/bin/bash

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue

RECENTFILE="$(find $1 -type f -name 'Event.zip' -printf "%T+ - %p\n" | sort -n | tail -1 | awk '{print $3}')"
unzip -o "$RECENTFILE" -d $1

# RECENTFILE="$(find /home/prod/hhm_data_acquisition/files/SMExxxxx/*/* -type f -name 'Event.zip' -printf "%T+ - %p\n" | sort -n | tail -1 | awk '{print $3}')"
# unzip -o "$RECENTFILE" -d /home/prod/hhm_data_acquisition/files/SME01391
