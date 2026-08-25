#!/usr/bin/env bash
# Run a mutation against a file WITHOUT touching git, and always restore it.
#
# WHY THIS EXISTS. 2026-08-24, phase 6: to prove an ARM test could go red I
# sed-mutated lib/commonplace/doc_host.ex in Sol's worktree and reverted with
# `git checkout -- <file>`. That file also carried Sol's UNCOMMITTED round work
# (uncommitted BY CONSTRUCTION: the fence mounts .git read-only), and checkout
# discarded it. Phase 5 used the same habit and was harmless only because the
# files I reverted were not Sol's. BRIEFING-SOL.md already said never to do
# this. A remembered rule did not fire; this file does.
#
# Usage:  bin/mutate.sh <file> '<sed expression>' -- <command to run...>
# The sed expression must CHANGE the file (a no-op mutation proves nothing —
# "an inert mutation is indistinguishable from a gate that works"), the command
# runs, and the ORIGINAL BYTES are restored from a copy regardless of outcome.
# yepochs, 2026-08-24 19:44Z, the same trap from the other side: a single-line
# sed that never matched because `mix format` had wrapped the target across
# three lines "survived" and read as an ornamental gate. That is why this script
# refuses when the bytes did not change — a malformed mutation and an ornamental
# gate share the observable "I changed it and nothing happened".
set -uo pipefail
file="${1:?file}"; expr="${2:?sed expression}"; shift 2
[ "${1:-}" = "--" ] && shift
[ -f "$file" ] || { echo "FAIL: no such file $file" >&2; exit 2; }
keep=$(mktemp); cp -- "$file" "$keep"
trap 'cp -- "$keep" "$file"; rm -f "$keep"' EXIT
sed -i -e "$expr" -- "$file"
if cmp -s "$keep" "$file"; then
  echo "FAIL: mutation did not change $file -- inert mutation, proves nothing." >&2
  exit 3
fi
echo "MUTATED $file ($(diff "$keep" "$file" | grep -c '^[<>]') changed lines); running: $*"
"$@"; rc=$?
echo "MUTATION RESULT rc=$rc (restored $file)"
exit $rc
