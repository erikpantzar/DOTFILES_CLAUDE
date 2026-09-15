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

RESET=$'\033[0m'
DIM=$'\033[2m'
BOLD=$'\033[1m'

fg() { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }

C_OPUS=$(fg 139 92 246)
C_SONNET=$(fg 14 165 233)
C_HAIKU=$(fg 22 163 74)
C_FABLE=$(fg 234 88 12)
C_MODEL_OTHER=$(fg 148 163 184)

C_CTX_LOW=$(fg 22 163 74)
C_CTX_MID=$(fg 217 119 6)
C_CTX_HIGH=$(fg 234 88 12)
C_CTX_CRIT=$(fg 220 38 38)
C_CTX_EMPTY=$(fg 203 213 225)

repeat_char() {
  local char="$1" count="$2" out="" i
  for ((i = 0; i < count; i++)); do
    out="$out$char"
  done
  printf '%s' "$out"
}

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
  [ "$filled" -lt 0 ] && filled=0
  empty=$((bar_width - filled))

  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 90 ]; then
    ctx_color="$C_CTX_CRIT"
  elif [ "$used_int" -ge 75 ]; then
    ctx_color="$C_CTX_HIGH"
  elif [ "$used_int" -ge 50 ]; then
    ctx_color="$C_CTX_MID"
  else
    ctx_color="$C_CTX_LOW"
  fi

  ctx="${BOLD}${ctx_color}$(repeat_char '█' "$filled")${RESET}${C_CTX_EMPTY}$(repeat_char '░' "$empty")${RESET} ${BOLD}${ctx_color}${used_int}%${RESET}"
else
  ctx="${DIM}n/a${RESET}"
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

case "$(echo "$model" | tr '[:upper:]' '[:lower:]')" in
  *opus*) model_color="$C_OPUS" ;;
  *sonnet*) model_color="$C_SONNET" ;;
  *haiku*) model_color="$C_HAIKU" ;;
  *fable*) model_color="$C_FABLE" ;;
  *) model_color="$C_MODEL_OTHER" ;;
esac

model_display="${BOLD}${model_color}${model}${RESET}"
if [ -n "$effort" ]; then
  model_display="$model_display ${model_color}${DIM}${effort}${RESET}"
fi

if [ -n "$git" ]; then
  printf '%s %s%s%s %s %s%s%s' "$model_display" "$DIM" "$git" "$RESET" "$ctx" "$DIM" "$rl" "$RESET"
else
  printf '%s %s %s%s%s' "$model_display" "$ctx" "$DIM" "$rl" "$RESET"
fi
