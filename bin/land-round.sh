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
[ "$rm_self" -eq 1 ] && trap 'rm -f "$0"' EXIT

branch="${1:?round branch, e.g. sol/phase-6}"
cd "$root"
# ⭐ Which version of this script is doing the gating -- observable, not inferred.
echo "land-round.sh: gating with the PRE-MERGE script, sha256 $(sha256sum bin/land-round.sh | cut -c1-12)"
# ⛔ The whole defect: refuse unless we are on main in a non-worktree checkout.
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
gate "mix test" mix test
gate "check-plan-arms" bash bin/check-plan-arms.sh
# Not in commonplace-doc's copy: this repo's spec is jes's and byte-identical.
gate "check-spec-pristine" bash bin/check-spec-pristine.sh
# ⭐ The gate-on-the-gate, required by jes's composition ruling §14.5: prove a
# failing gate never reaches `git push`. Hermetic -- it runs in a scratch repo
# with its own bare origin and never touches this one. Substituting the gates
# means the copy under test cannot recurse into this line.
gate "check-acceptance-arms" bash bin/check-acceptance-arms.sh
gate "check-landing-refuses" bash bin/check-landing-refuses.sh
git push -q origin main "$branch"
git fetch -q origin
# ⭐ The verdict is what origin says, not what push returned.
if git merge-base --is-ancestor "$branch" origin/main && [ "$(git rev-parse origin/main)" = "$(git rev-parse HEAD)" ]; then
  echo "LANDED: origin/main $(git rev-parse --short origin/main) contains $branch ($(git rev-list --count "$before"..HEAD) new commits)."
else
  echo "NOT LANDED: origin/main $(git rev-parse --short origin/main) does not contain $branch or differs from HEAD." >&2; exit 1
fi
