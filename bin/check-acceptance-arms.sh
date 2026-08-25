#!/usr/bin/env bash
# Gate: every arm name cited by docs/ACCEPTANCE-20.md is a REAL test name.
#
# WHY THIS IS A FILE. 2026-08-25: errata V15 claimed "all twenty of §20's
# acceptance items have a named green arm" and cited "round P6's report" for the
# mapping. ⛔ THAT REPORT WAS A 1 MB UNTRACKED FILE IN A SCRATCH ROUND DIRECTORY.
# The repo's completion claim rested on something not in the repo -- and on a
# directory I had, an hour earlier, been discussing removing as housekeeping.
# Found by commonplace-plan's README survey, not by me.
#
# ⭐ AND EXTRACTING THE TABLE FOUND TWO MORE DEFECTS THAT WOULD HAVE BEEN
# COMMITTED VERBATIM:
#   · item 20.2 cited "the named `domain rejects …` category arms" -- AN ELLIPSIS
#     NAMES NO ARM. That is an item claimed without naming the arm, which is the
#     one thing docs/STATE.md §1 forbids.
#   · item 20.16 cited `equal? is canonical-byte equality`, HYPHENATED. The test
#     is `equal? is canonical byte equality`. A citation that does not match is a
#     citation of nothing, and bin/check-plan-arms.sh cannot see it because the
#     acceptance table is prose, not ARM markers.
# ⇒ A claim-citing document needs the same gate the plans have, or it drifts the
#   moment a test is renamed.
#
# Exit: 0 all cited arms exist · 1 a citation names no test · 2 instrument blind.
set -uo pipefail
cd "$(dirname "$0")/.."
DOC=docs/ACCEPTANCE-20.md
[ -f "$DOC" ] || { echo "INSTRUMENT BLIND: $DOC not found" >&2; exit 2; }

# Cited arms are backticked spans on table rows. ⚠️ `|| rc=$?` on every capture:
# under `set -e` a grep matching nothing exits 1 and would abort the report.
# ⛔ TABLE ROWS ONLY. The prose above the table DESCRIBES the two defective
# citations this gate exists to catch -- an ellipsis and a hyphenated name -- so
# reading the whole file makes the gate flag its own explanation. That is the
# THIRD time in this repo that documentation about a checker entered the
# checker's corpus: the STATE.md phantom ARM marker, the args-based round
# counter matching prose about itself, and now this. ⭐ EVERY TIME, THE FIX WAS
# CORPUS SCOPE, never more careful wording. Rows start with `|`.
cited_rc=0
cited=$(grep '^|' "$DOC" | grep -oE '`[^`]+`' | tr -d '`' | sort -u) || cited_rc=$?
n_cited=$(printf '%s\n' "$cited" | grep -c . || true)
if [ "$cited_rc" -ne 0 ] || [ "${n_cited:-0}" -eq 0 ]; then
  echo "INSTRUMENT BLIND: no backticked citations in $DOC -- an empty corpus passes vacuously." >&2
  exit 2
fi

tests=$(grep -rho '^[[:space:]]*test "[^"]*"' test/ | sed 's/.*test "//; s/"$//' | sort -u)
n_tests=$(printf '%s\n' "$tests" | grep -c . || true)
[ "${n_tests:-0}" -gt 0 ] || { echo "INSTRUMENT BLIND: no test names under test/ -- wrong referent." >&2; exit 2; }

# ⛔ NOT every backticked span is an arm citation. Module names, function
# references like `send/2`, file paths and spec section numbers are prose. An arm
# citation is a span that looks like a test NAME: lowercase words, no slash-arity,
# no dot-separated module path. Anything else is skipped and COUNTED, so a future
# reader can see how much was skipped rather than trusting a bare PASS.
miss=0; ok=0; skipped=0
while IFS= read -r span; do
  [ -n "$span" ] || continue
  case "$span" in
    *"…"*|*"..."*)
      echo "  ⛔ ELLIPSIS   $span"
      echo "               An ellipsis names no arm. Spell every arm out."
      miss=$((miss + 1)); continue ;;
    *[A-Z]*.*|*/[0-9]|*/[0-9]*|"%"*|*".ex"*|*".exs"*|*".md"*|§*)
      skipped=$((skipped + 1)); continue ;;
  esac
  if grep -qiF -- "$span" <<< "$tests"; then
    ok=$((ok + 1))
  else
    echo "  MISSING    $span"
    miss=$((miss + 1))
  fi
done <<< "$cited"

echo "---"
echo "cited spans: $n_cited   arm citations checked: $ok   skipped as prose: $skipped   missing: $miss   tests: $n_tests"
if [ "$miss" -eq 0 ]; then
  echo "VERDICT: PASS -- every arm cited by the acceptance table is a real test."
  exit 0
fi
echo "VERDICT: FAIL -- $miss acceptance citation(s) name no test." >&2
echo "VERDICT: FAIL -- $miss acceptance citation(s) name no test."
exit 1
