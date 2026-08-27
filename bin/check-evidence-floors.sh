#!/usr/bin/env bash
# Gate: every tunable that sets an arm's EVIDENTIARY STRENGTH meets a declared floor.
#
# WHY THIS EXISTS. commonplace-cell, 2026-08-27, found an arm whose assertion built
# its expectation from the thing under test:
#
#     @rounds System.get_env("R2B_STABILITY_ROUNDS", "150") |> String.to_integer()
#     assert length(rounds) == @rounds
#
# It asserts the loop ran as many times as it was TOLD to, which is true for every
# value. At 1 round it runs 24 decisions instead of 3600, prints its own number, and
# PASSES -- the claimed bound falling from ~1-in-3600 to ~1-in-24 with nothing red.
#
# ⭐ THE CLASS IS "COVERAGE PRESENT, EVIDENCE ABSENT", AND EVERY OTHER MECHANISM IN
# THE 2026-08-27 THREAD IS BLIND TO IT: the arm is declared, counted, executed and
# unexcluded, so exclusion parsing, the three-number protocol, excluded-in-total,
# gated-arm inventories and source-vs-runner divergence all see a healthy arm.
#
# ⚠️ THIS REPO DOES NOT HAVE CELL'S VECTOR -- measured: 0 System.get_env and 0
# Application.get_env under test/, and all five max_runs values are literals. IT
# HAS THE SHAPE ANYWAY. Nothing pins those literals, so `max_runs: 75` -> 1 would
# still pass, still count one test, still be unexcluded, and still prove far less.
# A literal is safer than an env var only because a diff shows it; the arm itself
# cannot tell it was weakened.
#
# ⇒ cell's generalisation, applied: ASSERT THE PARAMETER MEETS A FLOOR, rather than
# asserting the loop honoured the parameter. The floor lives here, in a gate that
# reads source and starts no BEAM.
#
# Exit: 0 all floors met · 1 a tunable is below its floor · 2 instrument blind.
set -uo pipefail
cd "$(dirname "$0")/.."

FLOOR_MAX_RUNS=50   # property runs. Raise deliberately; never lower to make a run pass.

# ⛔ A FLOOR BOUNDS THE WORST CASE; IT DOES NOT PIN THE INTENDED ONE -- commonplace-log,
# stating the limit of its own fix unprompted. With a floor alone, 75 -> 50 clears the
# gate having quietly shed a third of the evidence; cell's 3600 -> 24 is caught and
# 3600 -> 150 is not. ⭐ So the complete form pins the INTENDED values where the GATE
# reads them, not where the caller chooses them.
# ⚠️ Changing a value here is meant to be deliberate and visible in a diff, exactly like
# commonplace-log's gated-arm inventory: adding or altering one FAILS until someone
# records it. Raising a run count is a one-line pin update; silently lowering one is not
# possible.
PINNED_MAX_RUNS="50 50 75 75 75"

# ⛔ Corpus first. A grep against a path that does not exist returns 0 hits and looks
# exactly like "every floor is met".
files=$(find test -name '*.exs' | wc -l)
[ "$files" -gt 0 ] || { echo "INSTRUMENT BLIND: no test .exs files found" >&2; exit 2; }

# ⛔⛔ A NON-EMPTINESS CONTROL DETECTS A SCANNER THAT READ NOTHING. IT CANNOT
# DETECT ONE READING THE WRONG POPULATION. commonplace-biscuit, 2026-08-27: its
# inventory globbed the top level only, a gated module sat in a subdirectory, and it
# reported rc 0 with "0 gated modules, 10 files scanned" -- the control asked "did I
# scan anything" and got yes, while "did I scan everything" was no.
# ⭐ So the corpus is cross-checked against an INDEPENDENT enumerator. git does not
# share this script glob, so a glob that silently narrows -- top-level-only, a missed
# directory level, a bad -path prune -- disagrees with git and REFUSES.
# ⚠️ It compares against TRACKED files, so an untracked new test file is a real
# difference and is meant to be reported, not tolerated.
tracked=$(git ls-files 2>/dev/null | grep -c "^test/.*\.exs$" || true)
if [ "${tracked:-0}" -gt 0 ] && [ "$files" -ne "$tracked" ]; then
  echo "INSTRUMENT BLIND: my glob sees $files test .exs files; git tracks $tracked." >&2
  echo "      The two enumerations disagree, so one of them is reading the wrong" >&2
  echo "      population. Non-emptiness would not have caught this." >&2
  exit 2
fi

runs=$(grep -rhoE 'max_runs: *[0-9]+' test/ | grep -oE '[0-9]+' || true)
n_runs=$(printf '%s\n' "$runs" | grep -c . || true)
if [ "${n_runs:-0}" -eq 0 ]; then
  echo "INSTRUMENT BLIND: no max_runs: settings found in $files test files." >&2
  echo "      Either the property arms lost their explicit run counts, or this" >&2
  echo "      pattern no longer matches how they are written. Both need a look." >&2
  exit 2
fi

# ⛔ AN ENV-DERIVED TUNABLE IS CELL'S ACTUAL VECTOR. Refuse it outright: a floor
# checked in source cannot bind a value chosen at run time.
env_derived=$(grep -rnE '(max_runs|rounds|iterations|samples)[^=]*(System\.get_env|Application\.get_env)' test/ || true)
if [ -n "$env_derived" ]; then
  echo "REFUSED: an evidentiary tunable is derived from the environment:" >&2
  printf '%s\n' "$env_derived" >&2
  echo "      A source-side floor cannot bind a run-time value. Pin it, or assert the" >&2
  echo "      floor inside the test against the value actually used." >&2
  exit 1
fi

low=0
for r in $runs; do
  if [ "$r" -lt "$FLOOR_MAX_RUNS" ]; then
    echo "  BELOW FLOOR  max_runs: $r  (floor $FLOOR_MAX_RUNS)"
    low=$((low + 1))
  else
    echo "  ok           max_runs: $r"
  fi
done

# Pin check: the exact multiset, order-independent.
actual_sorted=$(printf '%s\n' $runs | sort -n | tr '\n' ' ' | sed 's/ $//')
pinned_sorted=$(printf '%s\n' $PINNED_MAX_RUNS | sort -n | tr '\n' ' ' | sed 's/ $//')
drift=0
if [ "$actual_sorted" != "$pinned_sorted" ]; then
  echo "  PIN DRIFT    pinned [$pinned_sorted] but found [$actual_sorted]"
  echo "               A floor bounds the worst case; this pin bounds the INTENDED one."
  echo "               If the change is deliberate, update PINNED_MAX_RUNS in this file."
  drift=1
fi

echo "---"
echo "test files: $files   max_runs settings: $n_runs   below floor: $low   pin drift: $drift   env-derived: 0"
# ⚠️ The two failures are DIFFERENT and must not share a sentence: "below the floor"
# means an arm is weaker than the minimum this repo will accept; "pin drift" means it
# changed at all. Reporting drift as a floor breach would send the reader looking for
# a value under 50 that is not there.
if [ "$low" -eq 0 ] && [ "$drift" -eq 0 ]; then
  echo "VERDICT: PASS -- every evidentiary tunable meets its floor and matches its pin."
  exit 0
fi
msg="VERDICT: FAIL --"
[ "$low" -gt 0 ]   && msg="$msg $low tunable(s) below the floor;"
[ "$drift" -gt 0 ] && msg="$msg the pinned set changed;"
msg="$msg the arms still pass but prove less."
echo "$msg" >&2
echo "$msg"
exit 1
