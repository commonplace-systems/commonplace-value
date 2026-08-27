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
# ⛔ `-e` IS DELIBERATELY ABSENT AND THAT IS LOAD-BEARING, NOT AN OVERSIGHT.
# This script reports on a corpus, so it MUST survive commands that legitimately
# return non-zero: `grep -c` on no match, a false `[ ]` in a `&&` chain, a diff that
# finds a difference. Under `set -e` several of those abort MID-REPORT, and the abort
# looks exactly like a clean early finish.
# ⚠️ commonplace-biscuit's rule: WHEN YOU CHECK AND COME BACK CLEAN, CHECK WHETHER YOUR
# CLEANLINESS IS LOAD-BEARING OR INCIDENTAL. Mine is load-bearing, and `set -e` is the
# single most natural hardening someone would later apply -- it would arm silently.
set -uo pipefail
# ⛔⛔ FACE (3) OF THE MUTATION TRAP, and until 2026-08-27 nobody was checking it.
# The three faces: (1) the mutation never applied · (2) it applied but the red came
# from a broken harness · (3) IT APPLIED AND MOVED THE EXPECTATION WITH IT.
# This file already refused (1). commonplace-markdown hit (3): its sed was a BLANKET
# replace that changed the implementation line AND THE SELF-TEST'S EXPECTED STRING,
# so the check moved with the thing it checks and the demonstration printed PASS.
# ⭐ A MUTATION THAT ALSO MUTATES THE EXPECTATION IS A FUNCTION ASSERTED EQUAL TO
# ITSELF -- this repo's own round-trip rule, met from the mutation side.
#
# ⇒ The tractable guard: DECLARE HOW MANY LINES YOU MEANT TO CHANGE. A scoped
# mutation changes one; a blanket replace changes several and must say so out loud.
# `--lines N` (default 1). diff reports a `-` and a `+` per changed line, so the
# comparison is against 2N.
expect_lines=1
if [ "${1:-}" = "--lines" ]; then expect_lines="${2:?--lines needs a count}"; shift 2; fi
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
changed=$(diff "$keep" "$file" | grep -c '^[<>]')
if [ "$changed" -ne "$((expect_lines * 2))" ]; then
  echo "FAIL: mutation changed $((changed / 2)) line(s); --lines says $expect_lines." >&2
  echo "      A blanket replace can change the ASSERTION as well as the target, and then" >&2
  echo "      the check moves with the thing it checks and the demonstration prints PASS." >&2
  echo "      Scope the sed to the asserted line, or pass --lines $((changed / 2)) deliberately." >&2
  diff "$keep" "$file" | sed 's/^/      | /' >&2
  exit 4
fi
echo "MUTATED $file ($((changed / 2)) line(s), as declared); running: $*"
"$@"; rc=$?
echo "MUTATION RESULT rc=$rc (restored $file)"
exit $rc
