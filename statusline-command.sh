#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // empty')

proj_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
cur_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')

if [ -n "$proj_dir" ]; then
  proj_name=$(basename "$proj_dir")
  if [ "$cur_dir" = "$proj_dir" ]; then
    ws="$proj_name"
  else
    rel="${cur_dir#"$proj_dir"/}"
    ws="$proj_name/$rel"
  fi
else
  ws=$(basename "$cur_dir")
fi
if [ -n "$worktree" ]; then
  ws="$ws (wt:$worktree)"
fi

cwd_display="${cur_dir/#$HOME/~}"

ICON_BRANCH='🌱'
ICON_DIRTY='🔥'
ICON_CLEAN='✨'
ICON_AHEAD='⇡'
ICON_BEHIND='⇣'

git=""
if git -C "$cur_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cur_dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$cur_dir" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    if [ -n "$(git -C "$cur_dir" status --porcelain 2>/dev/null)" ]; then
      state_icon="$ICON_DIRTY"
    else
      state_icon="$ICON_CLEAN"
    fi

    ahead_behind=$(git -C "$cur_dir" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
    ab=""
    if [ -n "$ahead_behind" ]; then
      behind=$(echo "$ahead_behind" | cut -f1)
      ahead=$(echo "$ahead_behind" | cut -f2)
      [ "$ahead" != "0" ] && ab="$ab $ICON_AHEAD$ahead"
      [ "$behind" != "0" ] && ab="$ab $ICON_BEHIND$behind"
    fi

    git="$ICON_BRANCH $branch $state_icon$ab"
  fi
fi

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  bar_width=10
  filled=$(printf '%.0f' "$(echo "$used $bar_width" | awk '{print ($1/100)*$2}')")
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width
  empty=$((bar_width - filled))
  bar=$(printf '█%.0s' $(seq 1 $filled) 2>/dev/null)
  bar="$bar$(printf '░%.0s' $(seq 1 $empty) 2>/dev/null)"
  ctx="$bar $(printf '%.0f' "$used")%"
else
  ctx="n/a"
fi

# Formats a reset timestamp (Unix epoch seconds, or ISO-8601 string) as a
# "left until reset" duration, e.g. "2h14m".
time_until() {
  local resets_at="$1"
  local reset_epoch now_epoch diff
  if [[ "$resets_at" =~ ^[0-9]+$ ]]; then
    reset_epoch="$resets_at"
  else
    reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$resets_at" "+%s" 2>/dev/null)
    if [ -z "$reset_epoch" ]; then
      reset_epoch=$(date -d "$resets_at" "+%s" 2>/dev/null)
    fi
  fi
  [ -z "$reset_epoch" ] && return 1
  now_epoch=$(date "+%s")
  diff=$((reset_epoch - now_epoch))
  [ "$diff" -lt 0 ] && diff=0
  printf '%dh%02dm' $((diff / 3600)) $(((diff % 3600) / 60))
}

five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

rl=""
if [ -n "$week" ]; then
  if [ -n "$rl" ]; then
    rl="$rl $(printf '%.0f' "$week")%"
  else
    rl="$(printf '%.0f' "$week")%"
  fi
fi
if [ -z "$rl" ]; then
  rl="RL: n/a"
fi

if [ -n "$effort" ]; then
  model_display="$model $effort"
else
  model_display="$model"
fi

if [ -n "$git" ]; then
  printf '\033[2m%s\033[0m \033[2m%s\033[0m \033[2m%s\033[0m \033[2m%s\033[0m' "$model_display" "$git" "$ctx" "$rl"
else
  printf '\033[2m%s\033[0m \033[2m%s\033[0m \033[2m%s\033[0m' "$model_display" "$ctx" "$rl"
fi
