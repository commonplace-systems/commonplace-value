#!/usr/bin/env bash
# Land a Sol round branch onto main — FROM THE MAIN CHECKOUT, verified, pushed.
#
# WHY THIS EXISTS. 2026-08-24, twice in one day (phase 5 first attempt, phase 6
# for real): I ran `git merge sol/phase-N && git push origin main` from INSIDE
# the round's worktree, whose checked-out branch IS sol/phase-N. The merge was a
# no-op, `push origin main` pushed an unchanged main, `rev-list origin/main..main`
# printed 0, and I reported "main <sha> == origin, landed". Every command
# succeeded; the sentence was false in two ways at once. boss-clod caught it by
# measuring. A remembered rule ("merge from the main checkout") did not fire the
# second time; this file does.
#
# Usage: bin/land-round.sh sol/phase-N
set -euo pipefail

# ⛔ RUN FROM A PRIVATE COPY. This script MERGES, and a merge that changes this
# file rewrites it WHILE BASH IS STILL READING IT -- bash reads a script
# incrementally by byte offset, so the running command can be SPLICED from two
# different versions. That is undefined behaviour, not a version choice.
#
# ⚠️ WHAT THIS FIXES, STATED PRECISELY, BECAUSE I FIRST GOT IT WRONG: it makes the
# run DETERMINISTIC -- exactly the PRE-MERGE version executes, start to finish.
# It does NOT make a newly added gate run on the landing that introduces it.
# ⭐ SO THE STANDING FACT IS: A LANDING IS GATED BY THE SCRIPT AS IT WAS BEFORE
# THAT LANDING. A gate added in branch X first gates the landing AFTER X.
# Observed three times here as "the new gate line printed nothing", each time
# read as a scripting slip rather than as the rule it actually is.
# ⇒ The running version is echoed below so this is OBSERVABLE per landing rather
#   than inferred. If you need a new gate to cover its own branch, run it by
#   hand on that branch first and say so.
#
# ⚠️ --root IS PASSED AS AN ARGUMENT, NOT AN ENVIRONMENT VARIABLE, on purpose.
# bin/check-landing-refuses.sh runs a substituted copy of this script inside a
# SCRATCH repo, and an inherited root would make that copy cd into the REAL
# repository and act on it. An argument cannot leak into a grandchild; ambient
# state can. Measured: the real repo's main and origin/main are byte-unchanged
# across a full run of the gate-on-the-gate.
root=""; rm_self=0
while :; do
  case "${1:-}" in
    --root)    root="${2:?--root needs a path}"; shift 2 ;;
    # ⛔ THE PRIVATE COPY IDENTIFIES ITSELF WITH A FLAG. The first version inferred
    # it from a path prefix -- `case "$0" in /tmp/*)` -- and DELETED A CALLER-SUPPLIED
    # SCRIPT the first time one was run from a /tmp path. ⭐ "It looks like mine" is
    # not "it is mine": a heuristic that decides what to DELETE will eventually be
    # right about the pattern and wrong about the file.
    --rm-self) rm_self=1; shift ;;
    *) break ;;
  esac
done
if [ -z "$root" ]; then
  root="$(cd "$(dirname "$0")/.." && pwd)"
  self_copy="$(mktemp)"; cat "$0" > "$self_copy"
  exec bash "$self_copy" --root "$root" --rm-self "$@"
fi
# ⛔ ONE EXIT TRAP, because a second `trap ... EXIT` REPLACES the first and the
# first file leaks -- demonstrated in isolation, not assumed. Adding the
# executed-names trap further down silently disarmed this one, and the obvious
# check missed it: `land-round.sh nonexistent` exits at the branch check BEFORE
# the second trap is installed, so it measured a state that never overlapped.
# ⚠️ A cleanup that another cleanup can uninstall is not cleanup.
CLEANUP_FILES=()
cleanup() { [ "${#CLEANUP_FILES[@]}" -eq 0 ] || rm -f -- "${CLEANUP_FILES[@]}"; }
trap cleanup EXIT
[ "$rm_self" -eq 1 ] && CLEANUP_FILES+=("$0")

branch="${1:?round branch, e.g. sol/phase-6}"
cd "$root"
# ⭐ Which version of this script is doing the gating -- observable, not inferred.
echo "land-round.sh: gating with the PRE-MERGE script, sha256 $(sha256sum bin/land-round.sh | cut -c1-12)"
# ⛔ The whole defect: refuse unless we are on main in a non-worktree checkout.
# ⭐⭐ THE SLOT CHECK IS HOISTED ABOVE THE BRANCH GUARD, AND THE ORDER IS THE POINT.
# ⛔ WHY (errata V16, and commonplace-log's structural result): below the branch guard this
# check is UNREACHABLE from every checkout except `main` -- and `main` is exactly where the
# ungated copy lives until the guard lands. There is no ordering of write-it / test-it /
# land-it that avoids one unprotected run. This repo paid that: 18 commits to origin/main,
# out of turn, without a slot, because testing the gate meant standing where it did not exist.
# ⭐ Hoisting also makes the RED arm AFFORDABLE (commonplace-next): above the branch guard it
# refuses in milliseconds -- no suite, no box, no queue. An arm nobody can afford to run is an
# arm nobody has seen fail.
# ⚠️ NEGATIVE CONTROL for anyone demonstrating this (commonplace-next): a refusal from a
# NON-MAIN checkout must print rc 76. IF THE DEMO PRINTS rc 64, THE GATE WAS NOT EXERCISED --
# the branch guard refused on its behalf. rc 64 is silent about every gate below it.
bash "$root/bin/require-slot.sh" || exit 76

cur=$(git branch --show-current)
[ "$cur" = "main" ] || { echo "REFUSED: on '$cur', not main. cd to the main checkout." >&2; exit 64; }
[ "$(git rev-parse --git-dir)" = ".git" ] || { echo "REFUSED: this is a linked worktree, not the main checkout." >&2; exit 64; }
git rev-parse --verify -q "$branch" >/dev/null || { echo "REFUSED: no branch $branch" >&2; exit 65; }
before=$(git rev-parse HEAD)
# ⛔ A CONFLICTING MERGE IS A THIRD RESIDUE STATE, and until 2026-08-25 this
# script exited on it under `set -e` with NO MESSAGE AT ALL, leaving a conflicted
# merge in progress. Two states were already named -- pushed, and merged-but-not-
# pushed. This one is worse than both: the tree is mid-merge, `git status` is the
# only evidence, and a reader who saw the script "do nothing" would reasonably
# retry. ⭐ If a script can leave the repository in a state, it must be able to
# SAY which one.
# ⚠️ Resolve on the BRANCH, not here: merge origin/main into the round branch,
# fix it there, push, and land again. That keeps this script the only path to main.
if ! git merge --no-ff -q "$branch" -m "Merge branch '$branch'"; then
  echo "REFUSED: merging $branch into main CONFLICTED; nothing gated, nothing pushed." >&2
  echo "REFUSED: a conflicted merge is IN PROGRESS in this checkout." >&2
  echo "REFUSED: abort it with:  git merge --abort" >&2
  echo "REFUSED: then resolve on the branch:  git checkout $branch && git merge origin/main" >&2
  exit 68
fi
mix deps.get >/dev/null 2>&1 || true
# Gates capture their own exit status. Earlier form was `gate | tail -1`, which
# is a gate ONLY while `pipefail` is set -- commonplace-value measured (2026-08-25)
# that with `set -eu` alone the same line prints FAIL and proceeds to push. A gate
# whose teeth live in a shell option three lines away is one edit from decoration.
gate() {  # gate <label> <cmd...>: run, keep the verdict line, stop on non-zero
  local label="$1"; shift
  local out rc=0
  out=$("$@" 2>&1) || rc=$?   # `|| rc=$?`: under set -e a failing assignment exits BEFORE a following rc=$? (seen: silent rc=1, no REFUSED line)
  if [ "$rc" -ne 0 ]; then
    # ⛔ EVERY FAILING TEST NAME, FIRST, AND ALL OF THEM. `tail -20` alone loses
    # names: MEASURED on a 6-failure run, it showed 1 of 6. ⭐ A lost name turns a
    # solvable defect into a permanent asterisk on a green suite -- three repos in
    # this fleet hit an unexplained one-off failure the same afternoon and TWO of
    # them could not say which test it was, one to `tail -1` and one to not
    # recording it. The re-run is what destroys the evidence.
    # ⚠️ `|| names_rc=$?` for the same reason gate() itself needs it: under
    # `set -e` a grep that matches nothing exits 1 and would abort here.
    local names names_rc=0
    names=$(printf '%s\n' "$out" | grep -E '^[[:space:]]+[0-9]+\) (test|property|doctest) ') || names_rc=$?
    if [ "$names_rc" -eq 0 ] && [ -n "$names" ]; then
      echo "REFUSED: $label failed. EVERY failing test, in full:" >&2
      printf '%s\n' "$names" >&2
    fi
    echo "$out" | tail -20
    echo "REFUSED: $label failed (rc=$rc); not pushing." >&2
    # ⚠ THE MERGE ALREADY HAPPENED LOCALLY and is left in the tree. origin is
    # untouched -- that is the property that matters -- but local main now carries a
    # merge the gates rejected, and a naive re-run would push it. Name the way back,
    # because "nothing was pushed" and "nothing happened" are not the same state.
    echo "REFUSED: local main still holds the rejected merge. Undo with: git reset --hard $before" >&2
    exit 70
  fi
  echo "$out" | tail -1
}
# ⭐ CAPTURE THE TESTS THAT ACTUALLY RAN, and hand them to the arms gate.
# From commonplace-plan's consolidated patch (commonplace-markdown 0454e9c),
# ported by hand: their land-round.sh and mine have diverged too far for the diff
# to apply, so the FIX travels, not the file.
#
# ⛔ WHY. bin/check-plan-arms.sh certifies that a declared arm EXISTS. It cannot
# tell whether that arm RAN. Measured at commonplace-next: one
# `ExUnit.configure(exclude: [:integration])` plus `@moduletag :integration` on six
# files silently removed 38 declared arms from the run and the gate still printed
# PASS. One line, thirty-eight arms.
# ⚠️ This repo has no exclusion today -- so the defect CANNOT fire here yet. That
# is safety by ABSENCE, which is not protection: it goes live the moment anyone
# adds one. Same shape as the pipefail finding.
capture_executed() { # capture_executed <names-file> <test-command...>
  local names_file="$1"; shift
  local verdict_file trace_file rc=0 trace_rc=0 summary

  # ⛔⛔ TWO RUNS, TWO QUESTIONS -- and this is a CORRECTION, not a design.
  # Until now this drove the whole verdict from ONE `--trace` run. VERIFIED IN THE
  # INSTALLED SOURCE at ex_unit/lib/ex_unit/runner.ex:564, unconditional:
  #     defp get_timeout(config, tags) do
  #       if config.trace do :infinity else Map.get(tags, :timeout, config.timeout) end
  # ⇒ under --trace a test CANNOT time out, and an explicit --timeout cannot override
  # it because the tag is never consulted. --trace also forces --max-cases 1, so a
  # trace-gated suite never runs CONCURRENTLY either. Two blind classes, not one.
  # MEASURED HERE, one file, @tag timeout: 100 against Process.sleep(400):
  #     mix test         -> rc 2, "1 test, 1 failure", ExUnit.TimeoutError
  #     mix test --trace -> rc 0, "1 test, 0 failures"
  # ⭐ THE DIAGNOSTIC MODE AND THE GATING MODE ARE NOT THE SAME MODE, AND THE ONE
  # THAT PRINTS MORE IS THE ONE THAT OBSERVES LESS. Reported by commonplace-log,
  # which paid for it by using --trace to investigate a FLAKY failure -- choosing the
  # one mode that could not reproduce it.
  # ⚠️ This does NOT reintroduce two sources of truth: the runs answer DIFFERENT
  # questions. Plain decides pass/fail; traced enumerates. Both must pass.

  # ⭐⭐ SAMPLE THE BOX *DURING* THE RUN, NOT AT THE ENDS. commonplace-yelixer took 174
  # samples across one run: pre-flight 4286 MB, post-run 4351 MB, MINIMUM 934 MB --
  # 566 MB below the danger line, in a window a before/after pair would have
  # certified as clean. ⇒ A PRE-FLIGHT ANSWERS "MAY I START". ONLY SAMPLING ANSWERS
  # "WHAT DID MY RUN DO TO THE BOX." It is the extension of my own rule that the
  # MINIMUM is the number that matters -- and the minimum is unobtainable from the
  # ends. Costs one background shell and a file.
  local sample_file sampler_pid box_min
  sample_file=$(mktemp); CLEANUP_FILES+=("$sample_file")
  ( while :; do awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo >> "$sample_file"; sleep 2; done ) &
  sampler_pid=$!

  # ── 1. THE VERDICT RUN: plain, with real timeouts and real concurrency ──────
  verdict_file=$(mktemp); CLEANUP_FILES+=("$verdict_file")
  "$@" >"$verdict_file" 2>&1 || rc=$?
  command cat "$verdict_file"

  summary=$(grep -oE '[0-9]+ (test|tests|doctest|doctests|property|properties)[^|]*' "$verdict_file" | tail -1)
  if [ -z "$summary" ]; then
    echo "REFUSED: could not parse a test summary line; refusing rather than assuming a clean run." >&2
    echo "REFUSED: the complete verdict run is kept at $verdict_file" >&2
    return 69
  fi
  case "$summary" in
    *excluded*|*skipped*|*invalid*)
      echo "REFUSED: the run reported [$summary]. Excluded or skipped tests do not move the" >&2
      echo "         total and do not change the exit code; a declared arm may not have run." >&2
      echo "REFUSED: the complete verdict run is kept at $verdict_file" >&2
      return 69 ;;
  esac
  # ── 2. THE NAMES RUN: traced. Also the DISCRIMINATOR when the plain run failed. ──
  # ⛔ DO NOT RETURN EARLY ON A PLAIN FAILURE. The obvious implementation short-circuits
  # on the first red -- and then commonplace-log's discriminator (plain fails + traced
  # passes ⇒ timing-or-concurrency class) is UNREACHABLE BY CONSTRUCTION. commonplace-cell
  # hit exactly that in its own first cut. ⭐ Asking the second run the same question turns
  # it from a cost into the thing that IDENTIFIES the class.
  trace_file=$(mktemp); CLEANUP_FILES+=("$trace_file")
  "$@" --trace >"$trace_file" 2>&1 || trace_rc=$?

  # ⭐ Stop sampling and report the MINIMUM the box reached while I was running.
  # Kill BY CAPTURED PID -- never a pattern; a waiter or killer built on a pattern
  # that appears in its own argv is the trap this repo has hit four times today.
  # ⛔⛔ THE CLEANUP OF A SAMPLER MUST NEVER BE ABLE TO FAIL THE RUN IT WAS MEASURING.
  # commonplace-markdown measured this after filing a WRONG external cause for two of
  # its own dead landings. Under `set -e`, MEASURED HERE in isolation:
  #     wait <killed child>     -> 143   script exits 143
  #     kill <already-dead pid> ->   1   script exits 1
  # ⇒ this line could abort the landing AFTER BOTH SUITES HAD RUN and BEFORE the box
  # line or any verdict was printed. ⭐ A successful verdict run would leave NO TRACE
  # and the rc would name a signal nothing had sent -- a cleanup defect wearing the
  # costume of a gate refusal, with the log stopping exactly where it looks like the
  # suites never started.
  # ⚠️ `2>/dev/null` does NOT help: redirecting stderr does not change an exit code.
  # I had that redirect and it bought nothing.
  kill "$sampler_pid" 2>/dev/null || true
  wait "$sampler_pid" 2>/dev/null || true
  local n_samples
  n_samples=$(grep -c '^[0-9][0-9]*$' "$sample_file" || true)
  # ⛔ FILTER TO NUMBERS FIRST, then refuse on too few. commonplace-next got three wrong
  # readings from its own log because a non-numeric stamp sorted ahead of every number
  # and printed a MAXIMUM as the minimum -- a plausible value, not an error.
  # commonplace-log-reducer named the other half: sort|head with no refusal prints a
  # BLANK where a number goes, "a shape a hurried reader completes rather than questions".
  # ⚠️ Two samples is the floor: one sample is not a window.
  box_min=$(grep '^[0-9][0-9]*$' "$sample_file" | sort -n | head -1)
  if [ "${n_samples:-0}" -lt 2 ]; then
    echo "box: ⛔ ONLY ${n_samples:-0} sample(s) -- refusing to report a minimum from that." >&2
    echo "box:   Zero samples and a quiet box are otherwise the same observable." >&2
  else
    # ⭐ THE THIRD FIELD, from commonplace-next: what the window COVERS. A sampler started
    # late is a partial instrument that reads exactly like a complete one. This one is
    # started immediately before the verdict run and killed immediately after the traced
    # run, in the same function, so it covers the whole of both by construction.
    echo "box: MINIMUM available ${box_min} MB across ${n_samples} samples; WINDOW COVERS BOTH RUNS IN FULL"
  fi
  if [ -n "$box_min" ] && [ "$box_min" -lt 1500 ]; then
    echo "box: ⚠️ THAT IS BELOW THE 1500 MB DANGER LINE. This run contributed to a dip a" >&2
    echo "box:   pre-flight could not have seen. Report it; do not read the result as clean." >&2
  fi

  if [ "$rc" -ne 0 ]; then
    if [ "$trace_rc" -eq 0 ]; then
      echo "REFUSED: plain mix test FAILED (rc=$rc) but --trace PASSED." >&2
      echo "         ⇒ TIMING-OR-CONCURRENCY CLASS, not a flake. --trace disables per-test" >&2
      echo "           timeouts (ex_unit runner.ex:564, unconditional) and forces" >&2
      echo "           --max-cases 1. DO NOT RETRY THIS AWAY -- the disagreement IS the signal." >&2
    else
      echo "REFUSED: plain mix test FAILED (rc=$rc) and --trace ALSO failed (rc=$trace_rc)." >&2
      echo "         ⇒ NOT the trace class. An ordinary failure; read the verdict run." >&2
    fi
    echo "REFUSED: verdict run kept at $verdict_file ; traced run kept at $trace_file" >&2
    return "$rc"
  fi

  if [ "$trace_rc" -ne 0 ]; then
    echo "$trace_file" | tail -20 >&2
    echo "REFUSED: the traced names run failed (rc=$trace_rc) after the verdict run passed." >&2
    echo "REFUSED: the complete traced run is kept at $trace_file" >&2
    return "$trace_rc"
  fi
  # ExUnit rewrites each trace line after timing it, separated by CR; take the
  # final field so one physical test line stays one name under async output.
  # `(excluded)` entries are dropped -- the gate consumes the RUN, not the tags.
  awk -F '\r' '{ print $NF }' "$trace_file" |
    sed -nE '/^[[:space:]]*\* test .* \([^)]*\) \[L#[0-9]+\]$/ { /\(excluded\) \[L#[0-9]+\]$/d; s/^[[:space:]]*\* test //; s/ \([^)]*\) \[L#[0-9]+\]$//; p; }' > "$names_file"
  return 0
}

executed_tests=$(mktemp)
CLEANUP_FILES+=("$executed_tests")   # ⛔ NOT a second trap -- see the cleanup() note above
# ⛔⛔ WIRE THE PRE-FLIGHT, BECAUSE AN UNWIRED GATE IS A REMEMBERED RULE.
# commonplace-cell's line, which I quoted approvingly hours ago; commonplace-log
# then found it carrying the same defect it had quoted twice. Mine was worse than
# log's: log's pre-flight PRINTED AND PROCEEDED, mine was never invoked by anything.
# ⇒ `bin/preflight-host.sh` refuses correctly and NOTHING CALLED IT. A landing could
# start on any box at all. "A check whose result does not change what happens next
# is decoration" is in my own docs/STATE.md.
#
# ⭐ JITTER THEN RE-CHECK -- commonplace-log's interlock, and its own point about
# which half works: THE BACKOFF IS NOT THE PROTECTION, THE RE-CHECK IS. Jitter only
# lowers the collision probability; the SECOND observation is what makes a loser
# detect the winner. `suites == 0` is a time-of-check/time-of-use race, so every
# disciplined door observing it independently SYNCHRONISES on the same edge -- four
# suites started within seconds tonight, each having honestly read zero.
# ⚠️ Narrowed, not closed: two doors can still collide inside each other's re-check
# gap. It degrades TO the re-check rather than to nothing.
# ⚠️ And this is the INTERLOCK, not the lock. plan's queue is the lock.
# ⛔ THE LOCK FIRST, THEN THE INTERLOCK. The queue is authoritative; the box check is
# the safety interlock on top of it. Neither substitutes for the other, and three
# doors read an empty box as permission from the ordering tonight.
# ⭐ WHY THESE GATES ARE ORDERED AS THEY ARE, WHICH ARMS HAVE BEEN SEEN RED, AND WHICH
# ROWS ARE PREDICATE-ONLY: docs/GATE-AUDIT.md. ⚠️ Read it before adding, removing or
# REORDERING a gate -- it records that `require-slot` sits BELOW the merge and below the
# branch guard, and what that costs. docs/spec-errata.md V16-V20 has the incidents.
# (require-slot is HOISTED above the branch guard -- see the block near the top.
#  It is not a gate here: below the merge it could not stop a merge, and below the
#  branch guard it could not be reached at all.)
gate "pre-flight (box)" bash bin/preflight-host.sh
sleep $(( RANDOM % 26 ))
gate "pre-flight (re-check after jitter)" bash bin/preflight-host.sh

gate "mix test" capture_executed "$executed_tests" mix test
gate "check-plan-arms" bash bin/check-plan-arms.sh --executed "$executed_tests"
# Not in commonplace-doc's copy: this repo's spec is jes's and byte-identical.
gate "check-spec-pristine" bash bin/check-spec-pristine.sh
# ⭐ The gate-on-the-gate, required by jes's composition ruling §14.5: prove a
# failing gate never reaches `git push`. Hermetic -- it runs in a scratch repo
# with its own bare origin and never touches this one. Substituting the gates
# means the copy under test cannot recurse into this line.
gate "check-acceptance-arms" bash bin/check-acceptance-arms.sh
gate "check-evidence-floors" bash bin/check-evidence-floors.sh
gate "check-landing-refuses" bash bin/check-landing-refuses.sh
git push -q origin main "$branch"
git fetch -q origin
# ⭐ The verdict is what origin says, not what push returned.
if git merge-base --is-ancestor "$branch" origin/main && [ "$(git rev-parse origin/main)" = "$(git rev-parse HEAD)" ]; then
  echo "LANDED: origin/main $(git rev-parse --short origin/main) contains $branch ($(git rev-list --count "$before"..HEAD) new commits)."
else
  echo "NOT LANDED: origin/main $(git rev-parse --short origin/main) does not contain $branch or differs from HEAD." >&2; exit 1
fi
