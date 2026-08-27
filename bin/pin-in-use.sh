#!/usr/bin/env bash
# Is a sibling pin worktree still referenced by ANY checkout of this repo?
#
# WHY THIS EXISTS. 2026-08-24, phase 8b: I removed the merkle-crdt pin worktree
# at 31e6dca after bumping main to a newer pin — while the phase 8b round, branched
# BEFORE the bump, still pointed its mix.exs at 31e6dca. The round's final compile
# died with "the dependency is not available"; Sol reported "compile blocked in
# fence" exactly as briefed, and the cause was me, one layer up. A pin is in use
# by every checkout that names it, not only by main.
#
# Usage: bin/pin-in-use.sh <pin-dir e.g. /home/jes/commonplace-merkle-crdt-pin-31e6dca>
# Exit 0 = safe to remove (no checkout references it). Exit 1 = in use; lists them.
# ⛔ `-e` IS DELIBERATELY ABSENT AND THAT IS LOAD-BEARING, NOT AN OVERSIGHT.
# This script reports on a corpus, so it MUST survive commands that legitimately
# return non-zero: `grep -c` on no match, a false `[ ]` in a `&&` chain, a diff that
# finds a difference. Under `set -e` several of those abort MID-REPORT, and the abort
# looks exactly like a clean early finish.
# ⚠️ commonplace-biscuit's rule: WHEN YOU CHECK AND COME BACK CLEAN, CHECK WHETHER YOUR
# CLEANLINESS IS LOAD-BEARING OR INCIDENTAL. Mine is load-bearing, and `set -e` is the
# single most natural hardening someone would later apply -- it would arm silently.
set -uo pipefail
pin="${1:?pin worktree path}"
cd "$(dirname "$0")/.."
hits=0
while read -r wt _; do
  [ -f "$wt/mix.exs" ] || continue
  if grep -qF -- "$pin" "$wt/mix.exs"; then echo "IN USE by $wt ($(git -C "$wt" branch --show-current 2>/dev/null))"; hits=$((hits+1)); fi
done < <(git worktree list | awk '{print $1}')
if [ "$hits" -eq 0 ]; then echo "UNUSED: no checkout of this repo references $pin"; exit 0; fi
exit 1
