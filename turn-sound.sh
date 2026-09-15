#!/bin/bash

BIG_TURN_SECONDS=60
QUIET_VOLUME=0.4

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
stamp="${TMPDIR:-/tmp}/claude-turn-start-${session_id}"

case "$1" in
  start)
    date +%s > "$stamp"
    ;;
  stop)
    now=$(date +%s)
    started=$(cat "$stamp" 2>/dev/null || echo "$now")
    rm -f "$stamp"
    elapsed=$(( now - started ))
    if (( elapsed >= BIG_TURN_SECONDS )); then
      afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
    else
      afplay -v "$QUIET_VOLUME" /System/Library/Sounds/Tink.aiff 2>/dev/null || true
    fi
    ;;
esac
