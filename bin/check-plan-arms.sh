#!/usr/bin/env bash
# Gate: every test arm a plan DECLARES must exist in the suite.
#
# WHY THIS EXISTS. Phase 2's plan listed "a legal verb name mounts" as a required
# green arm. It was never written. 31 tests passed and nothing indicated a gap:
# green-because-ABSENT is indistinguishable from green-because-PASSED, so counting
# tests can never find it. Only mutating the rule did -- over-tightening the verb
# charset to forbid hyphens changed no test result at all.
#
# A plan that names required tests is a checklist, and a checklist nobody diffs
# against the suite is a wish. This diffs it, and FAILS.
#
# DECLARE an arm in a plan with a marker line:
#   <!-- ARM: substring that must appear in a test name -->
#
# THE MARKER IS THE CONTRACT: name the test to match the marker, not the other way
# round. On its first run this gate reported 4 misses of which only ONE was real --
# the other three were tests that existed under different wording. A gate that
# fires on correct state is worse than no gate, because it trains people to ignore
# it. If a marker misses, first check whether the test exists under another name;
# if it does, the MARKER is wrong.
set -uo pipefail
cd "$(dirname "$0")/.."

# --self-test : prove the MATCHER cannot pass an arm that has no test.
# Offered by commonplace-dir. This gate restricts matching to `test "..."` NAMES,
# so a token appearing in implementation code or comments must NOT satisfy an arm.
# That restriction was asserted and never demonstrated -- and a gate never seen to
# fail is not known to work. This builds a corpus where every token appears ONLY
# as code and comments, plus one unrelated test, and requires every arm to MISS.
#
# BOTH ARMS OF THIS SELF-TEST ARE DEMONSTRATED:
#   matcher correct                     -> PASS, exit 0
#   matcher reads implementation text   -> "ok  widget alignment", exit 3
#
# AND A MUTATION-TESTING TRAP FOUND WHILE PROVING IT. My first attempt to break
# the matcher used a glob that did not read the file holding the tokens. The
# broken matcher therefore returned the CORRECT answer for the wrong reason, the
# self-test passed, and I briefly concluded the self-test was decoration.
# => AN INERT MUTATION IS INDISTINGUISHABLE FROM A GATE THAT WORKS.
# Mutation testing has the same vacuous-control failure as everything else:
# before believing a mutation proved something, CONFIRM THE MUTATION ACTUALLY
# PERTURBED THE THING UNDER TEST. Here that means the break must read the file
# containing the arm tokens; a break that reads nothing only proves exit 2.
# ⛔ ARGV IS A THIRD CAUSE OF "THE GATE NEVER RAN", and it was unmodelled.
# Found by commonplace-dir on their own gate: invoked wrongly it exited 1, which
# IS its missing-arms verdict -- so "I typed the command wrong" was
# indistinguishable from "the round skipped required tests." A gate returning a
# verdict about work it never examined is the exact failure it exists to catch,
# aimed at itself. This script had the same hole in a different shape: an
# unrecognised flag fell through and ran the NORMAL gate, so `--slef-test`
# reported FAIL and a caller could read that as "the self-test failed".
# Two causes were already modelled (no ARM markers, no test names). argv is a third.
if [ "$#" -gt 0 ] && [ "${1:-}" != "--self-test" ]; then
  echo "FAIL: unrecognised argument '${1}'. Usage: $(basename "$0") [--self-test]" >&2
  echo "      (exit 2 = the gate did not run. 1 would mean it ran and arms are missing.)" >&2
  exit 2
fi

if [ "${1:-}" = "--self-test" ]; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  mkdir -p "$T/docs" "$T/test" "$T/lib" "$T/bin"
  printf '<!-- ARM: widget alignment -->\n<!-- ARM: gasket tolerance -->\n' > "$T/docs/p.md"
  printf '# widget alignment is handled here\ndef gasket_tolerance, do: :ok\n' > "$T/lib/impl.ex"
  printf '  test "something entirely unrelated" do\n  end\n' > "$T/test/a_test.exs"
  cp "$0" "$T/bin/"
  out=$("$T/bin/$(basename "$0")" 2>&1); rc=$?
  n_miss=$(printf '%s\n' "$out" | grep -c 'MISSING')
  if [ "$rc" -eq 1 ] && [ "$n_miss" -eq 2 ]; then
    echo "SELF-TEST PASS: tokens present only in code/comments matched 0 arms (2/2 MISSING, exit 1)."
    exit 0
  fi
  echo "SELF-TEST FAIL: expected exit 1 with 2 MISSING; got exit $rc with $n_miss." >&2
  printf '%s\n' "$out" >&2
  exit 3
fi

# ⭐ ARM vs ARM-PLANNED. An arm declared for a round that has NOT been dispatched
# is absent for a different reason than an arm missing from landed work, and
# mixing them makes RED ambiguous -- which is how a gate becomes permanently red
# and then ignored. `ARM:` = contract on landed work, and its absence FAILS.
# `ARM-PLANNED:` = contract on a future round, reported and NOT failing. Promote
# the marker to `ARM:` when that round is dispatched.
mapfile -t ARMS    < <(grep -rho '<!-- ARM: .* -->'         docs/ | sed 's/<!-- ARM: //; s/ -->//')
mapfile -t PLANNED < <(grep -rho '<!-- ARM-PLANNED: .* -->' docs/ | sed 's/<!-- ARM-PLANNED: //; s/ -->//')
if [ "${#ARMS[@]}" -eq 0 ]; then
  echo "FAIL: no ARM markers found in docs/ -- the gate has nothing to check." >&2
  echo "      (A gate with an empty corpus passes vacuously. That is the bug this file exists for.)" >&2
  exit 2
fi

TESTS=$(grep -rho '^\s*test "[^"]*"' test/ | sed 's/.*test "//; s/"$//')
N_TESTS=$(printf '%s\n' "$TESTS" | grep -c .)
if [ "$N_TESTS" -eq 0 ]; then
  echo "FAIL: no test names found under test/ -- wrong referent, not an empty suite." >&2
  exit 2
fi

# ── MODULE COVERAGE ───────────────────────────────────────────────────────────
# ⛔ WHY. Two repos found unbriefed Sol machinery within an hour: a DocHost.Reducer
# here, an async checkpoint worker in commonplace-dir against a brief forbidding
# "timers, debounce, scheduler, watches" -- none of which it was.
# ⭐ AN ENUMERATION IS SATISFIABLE BY ANYTHING NOT ON THE LIST. My phase-3 plan
# listed what was in scope and what was out; DocHost.Reducer was on neither list
# and was therefore permitted by omission. "Out of scope: A, B, C" is not a
# property, it is a denylist, and a denylist of machinery is the same defect as a
# denylist of secrets.
# => The property: EVERY MODULE IN lib/ IS DECLARED IN A PLAN. Adding one is fine
#    -- adding one SILENTLY is not. Declare with:  <!-- MODULE: Full.Module.Name -->
mapfile -t DECLARED < <(grep -rho '<!-- MODULE: .* -->' docs/ | sed 's/<!-- MODULE: //; s/ -->//')
mapfile -t ACTUAL   < <(grep -rho '^defmodule [A-Za-z0-9_.]*' lib/ | sed 's/defmodule //' | sort -u)
undeclared=0
if [ "${#ACTUAL[@]}" -gt 0 ]; then
  for m in "${ACTUAL[@]}"; do
    hit=0
    for d in "${DECLARED[@]:-}"; do [ "$d" = "$m" ] && hit=1 && break; done
    [ "$hit" -eq 1 ] || { printf '  UNDECLARED MODULE  %s\n' "$m"; undeclared=$((undeclared+1)); }
  done
fi

miss=0
for arm in "${ARMS[@]}"; do
  # ⛔ HERESTRING, NOT `printf | grep -q`. Under pipefail the old form was a
  # false-MISS race: printf writes one line per write(), grep -q exits on the
  # first match, the next write() gets EPIPE/SIGPIPE, the pipeline fails, and a
  # PRESENT arm reports MISSING. Found by commonplace-dir (18:28Z) in the sibling
  # of this script; MEASURED here on an unchanged tree: 12/150 false FAIL with
  # the pipe, 0/150 with the herestring. It had shown up earlier today as a
  # "transient 1 missing" and was dismissed as mid-priming noise. A gate that
  # sometimes goes red on correct state is worse than no gate: it trains people
  # to re-run it until green.
  if grep -qiF -- "$arm" <<< "$TESTS"; then
    printf '  ok      %s\n' "$arm"
  else
    printf '  MISSING %s\n' "$arm"; miss=$((miss+1))
  fi
done

echo "---"
echo "declared arms: ${#ARMS[@]}   planned (not failing): ${#PLANNED[@]}   tests: $N_TESTS   missing: $miss   undeclared modules: $undeclared"
miss=$((miss + undeclared))

# ⛔ THE VERDICT IS PRINTED TO STDOUT AS THE LAST LINE, ON PURPOSE.
# A caller who writes `check-plan-arms.sh | tail -4; echo $?` reads TAIL's exit
# code, not this script's -- it printed FAIL and the caller read 0. That happened
# on this gate's first external verification. The exit code is still the contract,
# but a pipeline that swallows it must still SEE the verdict.
if [ "$miss" -eq 0 ]; then
  echo "VERDICT: PASS -- every declared arm exists."
  exit 0
else
  n_arm=$((miss - undeclared))
  echo "VERDICT: FAIL -- $n_arm declared arm(s) with no test, $undeclared undeclared module(s)." >&2
  echo "VERDICT: FAIL -- $n_arm declared arm(s) with no test, $undeclared undeclared module(s)."
  exit 1
fi
