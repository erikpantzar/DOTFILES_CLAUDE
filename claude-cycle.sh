#!/bin/bash
set -euo pipefail

kind="${1:-}"
pane="${2:-}"
if [[ -z "$kind" || -z "$pane" ]]; then
  echo "usage: claude-cycle.sh model|effort <tmux-pane-id>" >&2
  exit 1
fi

models=(fable opus sonnet haiku)
efforts=(medium high xhigh)

state_file="${TMPDIR:-/tmp}/claude-cycle/${pane#%}"
settings="$HOME/.claude/settings.json"

if [[ -f "$state_file" ]]; then
  current_model=$(sed -n 1p "$state_file")
  current_effort=$(sed -n 2p "$state_file")
else
  current_model=$(jq -r '.model // empty' "$settings")
  current_effort=$(jq -r '.effortLevel // empty' "$settings")
fi

next_in() {
  local current="$1"; shift
  local list=("$@")
  local i
  for i in "${!list[@]}"; do
    if [[ "$current" == "${list[$i]}" ]]; then
      echo "${list[$(( (i + 1) % ${#list[@]} ))]}"
      return
    fi
  done
  echo "${list[0]}"
}

model_alias() {
  local lower
  lower=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  local m
  for m in "${models[@]}"; do
    if [[ "$lower" == *"$m"* ]]; then
      echo "$m"
      return
    fi
  done
  echo ""
}

case "$kind" in
  model)
    next=$(next_in "$(model_alias "$current_model")" "${models[@]}")
    tmux send-keys -t "$pane" "/model $next" Enter
    ;;
  effort)
    next=$(next_in "$current_effort" "${efforts[@]}")
    tmux send-keys -t "$pane" "/effort $next" Enter
    ;;
  *)
    echo "unknown kind: $kind" >&2
    exit 1
    ;;
esac

tmux display-message "$kind → $next"
