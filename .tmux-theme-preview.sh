#!/usr/bin/env bash
# ~/.tmux-theme-preview.sh
# Launch via tmux: prefix + t
# Renders the current tmux theme with live status bar data and 256-color reference.

bold=$(printf '\033[1m')
dim=$(printf '\033[2m')
nobold=$(printf '\033[22m')
reset=$(printf '\033[0m')
fg() { printf '\033[38;5;%sm' "$1"; }
bg() { printf '\033[48;5;%sm' "$1"; }

C_ORANGE=214; C_DARK=232; C_GREY=238; C_RED=196; C_PINK=217

W=$(tput cols)

strip_ansi() { printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g'; }

center() {
  local raw; raw=$(strip_ansi "$(printf '%b' "$1")")
  local pad=$(( (W - ${#raw}) / 2 ))
  [[ $pad -lt 0 ]] && pad=0
  printf "%*s" "$pad" ""
  printf '%b\n' "$1"
}

rline() { printf '%*s\n' "$W" '' | tr ' ' "${1:- }"; }

section() {
  echo
  center "$(fg $C_ORANGE)${bold}── $1 ──${reset}"
  echo
}

# ── gather live tmux data ─────────────────────────────
SESSION=$(tmux display-message -p '#S' 2>/dev/null)
WINDOWS=$(tmux display-message -p '#{session_windows}' 2>/dev/null)
PANES=$(tmux display-message -p '#{window_panes}' 2>/dev/null)
PPATH=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
PTITLE=$(tmux display-message -p '#{pane_title}' 2>/dev/null)
WIN_NAME=$(tmux display-message -p '#W' 2>/dev/null)
GIT_BRANCH=$(cd "$PPATH" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
GIT_DIRTY=$(cd "$PPATH" 2>/dev/null && { git diff --quiet HEAD 2>/dev/null && echo 0 || echo 1; } || echo 0)

# ── header ────────────────────────────────────────────
echo
center "${bold}$(fg $C_ORANGE)✦$(reset)  tmux theme preview  $(fg $C_ORANGE)✦${reset}"
rline '─'

# ── LIVE STATUS BAR ───────────────────────────────────
section "STATUS BAR  (live)"

context="${PTITLE:-$(basename "$PPATH")}"

left_raw=" ${SESSION}  ${WINDOWS}w ${PANES}p │ ${context} │ "
left_fmt="$(fg $C_DARK)${bold} ${SESSION} ${nobold} ${WINDOWS}w ${PANES}p $(fg $C_DARK)│ ${context} │ "

git_part=""
[[ -n "$GIT_BRANCH" ]] && git_part="${GIT_BRANCH}$([[ $GIT_DIRTY != 0 ]] && echo ' ±')  "
right_raw="${git_part}$(date '+%d %b  %H:%M:%S') "
right_fmt="$(fg $C_DARK)${bold}${git_part}$(date '+%d %b  %H:%M:%S') "

left_visible=${#left_raw}
right_visible=${#right_raw}
pad=$(( W - left_visible - right_visible ))
[[ $pad -lt 0 ]] && pad=0

printf '%b' "$(bg $C_ORANGE)"
printf '%b' "$left_fmt"
printf '%*s' "$pad" ""
printf '%b' "$right_fmt"
printf '%b\n' "${reset}"
echo
printf '  %b%bstatus-left%b   fg=colour232  bg=colour214  bold\n' "$(fg $C_ORANGE)" "${bold}" "${reset}"
printf '  %b%bstatus-right%b  fg=colour232  bg=colour214  bold  (git branch + dirty + clock)\n' "$(fg $C_ORANGE)" "${bold}" "${reset}"

# ── WINDOW TABS ───────────────────────────────────────
section "WINDOW TABS"

printf '%b' "$(bg $C_ORANGE)$(fg $C_DARK)"
printf '%b' "${bold} ● ${WIN_NAME} "
for idle in vim lazygit; do
  printf '%b' "${nobold}${dim}  ${idle} "
done
printf '%b\n' "${reset}"
echo
printf '  %b%bactive%b   window-status-current-format  →  bold ● #W\n' "$(fg $C_ORANGE)" "${bold}" "${reset}"
printf '  %b%bidle%b     window-status-format           →  nobold dim  #W\n' "$(fg $C_GREY)" "${bold}" "${reset}"

# ── PANE BORDERS ──────────────────────────────────────
section "PANE BORDERS"

printf '  %b┌─────────────┐%b  pane-border         colour238 (inactive)\n' "$(fg $C_GREY)" "${reset}"
printf '  %b│             │%b\n' "$(fg $C_GREY)" "${reset}"
printf '  %b└─────────────┘%b\n' "$(fg $C_GREY)" "${reset}"
echo
printf '  %b┌─────────────┐%b  pane-active-border  colour214 (active)\n' "$(fg $C_ORANGE)" "${reset}"
printf '  %b│             │%b\n' "$(fg $C_ORANGE)" "${reset}"
printf '  %b└─────────────┘%b\n' "$(fg $C_ORANGE)" "${reset}"

# ── MESSAGE STYLE ─────────────────────────────────────
section "MESSAGE STYLE"

printf '  %b%b Config reloaded %b   fg=colour217  bg=colour196  bold\n' \
  "$(bg $C_RED)$(fg $C_PINK)" "${bold}" "${reset}"

# ── ANSI 256-COLOR CONFIG ─────────────────────────────
section "ANSI 256-COLOR CONFIG"

printf '  %-32s  %s\n' "Role" "colour  ANSI escape       Swatch"
printf '  %-32s  %s\n' "────────────────────────────────" "──────────────────────────────"

role_214="status bg / active border / tabs"
role_232="status fg / text"
role_238="inactive pane border"
role_217="message fg"
role_196="message bg / alert"
role_255="bright white (reference)"

for c in 214 232 238 217 196 255; do
  eval role=\$role_$c
  printf '  %-32s  colour%-5s  \033[38;5;%sm\\033[38;5;%sm\033[0m  %b  %b\n' \
    "$role" "$c" "$c" "$c" "$(bg $c)     " "${reset}"
done

# ── 256-COLOR REFERENCE ───────────────────────────────
section "256-COLOR REFERENCE"

contrast() {
  local c=$1
  if   [[ $c -le 6 ]] || [[ $c -eq 8 ]] || [[ $c -ge 232 && $c -le 243 ]]; then
    printf '\033[38;5;255m'
  elif [[ $c -ge 244 ]] || [[ $c -ge 7 && $c -le 15 ]]; then
    printf '\033[38;5;232m'
  else
    printf '\033[38;5;255m'
  fi
}

# system colors 0-15
for row in 0 1; do
  printf '  '
  for col in $(seq 0 7); do
    c=$(( row * 8 + col ))
    printf '%b%b %3d %b' "$(bg $c)" "$(contrast $c)" "$c" "${reset}"
  done
  printf '\n'
done
echo

# color cube 16-231
for band in $(seq 0 5); do
  for row in $(seq 0 5); do
    printf '  '
    for col in $(seq 0 5); do
      c=$(( 16 + band * 36 + row * 6 + col ))
      printf '%b%b %3d %b' "$(bg $c)" "$(contrast $c)" "$c" "${reset}"
    done
    printf '\n'
  done
  echo
done

# grayscale 232-255
printf '  '
for c in $(seq 232 255); do
  printf '%b%b %3d %b' "$(bg $c)" "$(contrast $c)" "$c" "${reset}"
done
printf '\n'

echo
rline '─'
