#!/usr/bin/env bash
# Launch a Sol round in a tmux pane — refusing to launch NOTHING.
#
# WHY THIS EXISTS. 2026-08-24, phase 7: the prompt file was written by a link
# of an && chain that never ran (an earlier link failed on "nothing to commit"),
# and the launcher happily dispatched an EMPTY prompt. Sol asked "What would
# you like me to work on?" and exited clean at 2.6k tokens. Cheap that time;
# the same shape with a partially written prompt would not be. Same rule as
# bin/mutate.sh refusing an inert mutation: a launcher that can dispatch
# nothing must refuse to.
#
# Also refuses if the plan commit the round is built on is not on origin —
# a round whose description exists on one disk is a round you cannot rebuild.
#
# Usage: bin/dispatch-round.sh <round-dir e.g. /home/jes/sol-docp8> <round-name e.g. phase 8>
set -euo pipefail
dir="${1:?round dir}"; name="${2:?round name as it appears in the prompt}"
wt="$dir/wt"; prompt="$dir/prompt.txt"
[ -d "$wt/.git" ] || [ -f "$wt/.git" ] || { echo "REFUSED: no worktree at $wt" >&2; exit 64; }
[ -s "$prompt" ] || { echo "REFUSED: $prompt is missing or empty — nothing to dispatch." >&2; exit 65; }
grep -qF -- "$name" "$prompt" || { echo "REFUSED: prompt does not name the round '$name'." >&2; exit 65; }
[ "$(wc -w < "$prompt")" -ge 100 ] || { echo "REFUSED: prompt is $(wc -w < "$prompt") words; a real brief is longer." >&2; exit 65; }
base=$(git -C "$wt" rev-parse HEAD)
git -C "$wt" fetch -q origin
git -C "$wt" branch -r --contains "$base" | grep -q . || { echo "REFUSED: worktree HEAD $base is on no remote ref. Push first." >&2; exit 66; }
[ -z "$(git -C "$wt" status --porcelain)" ] || { echo "REFUSED: worktree is dirty; a round must start from a committed state." >&2; exit 67; }
win="$(basename "$dir")"
tmux new-window -d -t 0: -n "$win" -c "$dir" \
  "SOL_WORKDIR=$wt /home/jes/boss-clod/sol-egress-run.sh \"\$(cat $prompt)\" 2>&1 | tee $dir/sol-run.log; echo \"=== sol EXITED rc=\${PIPESTATUS[0]} ===\"; sleep 86400"
sleep 20
# ⭐ Verify on the RUNNING pids, both fence layers, and capture the outer pid.
n=0
for pid in $(ps -eo pid,cmd | awk -v d="$wt" '/[c]odex exec -m gpt-5.6-sol/ && index($0,d) {print $1}'); do
  n=$((n+1))
  echo "$pid prompt=$(tr '\0' '\n' < /proc/$pid/cmdline | grep -cF -- "$name") masks=$(grep -c tmpfs /proc/$pid/mountinfo) -C=$(tr '\0' '\n' < /proc/$pid/cmdline | grep -A1 -x -- '-C' | tail -1)"
  [ -z "${outer:-}" ] && outer=$pid && echo "$pid" > "$dir/outer.pid"
done
[ "$n" -gt 0 ] || { echo "NOT RUNNING: no codex process on $wt after 20s. Read $dir/sol-run.log." >&2; exit 1; }
echo "DISPATCHED $name in tmux window $win, outer pid $(cat "$dir/outer.pid"); wait on it by pid."
