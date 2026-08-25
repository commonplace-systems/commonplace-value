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
branch="${1:?round branch, e.g. sol/phase-6}"
cd "$(dirname "$0")/.."
# ⛔ The whole defect: refuse unless we are on main in a non-worktree checkout.
cur=$(git branch --show-current)
[ "$cur" = "main" ] || { echo "REFUSED: on '$cur', not main. cd to the main checkout." >&2; exit 64; }
[ "$(git rev-parse --git-dir)" = ".git" ] || { echo "REFUSED: this is a linked worktree, not the main checkout." >&2; exit 64; }
git rev-parse --verify -q "$branch" >/dev/null || { echo "REFUSED: no branch $branch" >&2; exit 65; }
before=$(git rev-parse HEAD)
git merge --no-ff -q "$branch" -m "Merge branch '$branch'"
mix deps.get >/dev/null 2>&1 || true
mix test 2>&1 | tail -1
bash bin/check-plan-arms.sh | tail -1
# ⛔ ADDED HERE, not inherited: commonplace-doc's copy of this script has no
# spec-pristine line, so the gate existed in bin/ and was on NO path to main.
# A gate nothing invokes is indistinguishable from one that always passes.
# Its RED arm is demonstrated in docs/STATE.md §2; pipefail above is what makes
# this line a gate rather than a print.
bash bin/check-spec-pristine.sh | tail -1
git push -q origin main "$branch"
git fetch -q origin
# ⭐ The verdict is what origin says, not what push returned.
if git merge-base --is-ancestor "$branch" origin/main && [ "$(git rev-parse origin/main)" = "$(git rev-parse HEAD)" ]; then
  echo "LANDED: origin/main $(git rev-parse --short origin/main) contains $branch ($(git rev-list --count "$before"..HEAD) new commits)."
else
  echo "NOT LANDED: origin/main $(git rev-parse --short origin/main) does not contain $branch or differs from HEAD." >&2; exit 1
fi
