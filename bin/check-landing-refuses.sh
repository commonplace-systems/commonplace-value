#!/usr/bin/env bash
# Gate-on-the-gate: prove bin/land-round.sh NEVER REACHES `git push` when a
# required gate fails -- and DOES reach it when they pass.
#
# WHY THIS IS A FILE. jes's composition ruling §14 (2026-08-25) states the repo
# rule this enforces:
#
#   "5. a regression test substitutes a deliberately failing gate and proves the
#       push command is never reached."
#
# The property had been demonstrated here twice BY HAND -- once against the
# tail-piped form, once against a pipefail-stripped copy. ⭐ A demonstration is
# not a regression test: it fires when someone remembers to run it, and the
# whole point of the finding was that a future tidy-up would silently disarm the
# gates. A REMEMBERED RULE DOES NOT FIRE; A FILED ARTIFACT DOES.
#
# ⛔ THIS RUNS ENTIRELY IN A SCRATCH REPOSITORY. It never touches this repo, its
# branches, or its origin -- the property under test is "does it push", and a
# test of that which used the real remote would be the last thing you want
# wrong. The scratch origin is a local bare repo, so the REAL `git push` line
# executes for real in the green arm rather than being stubbed out. A stub would
# prove the stub.
#
# ⭐ BOTH ARMS, ALWAYS. A gate never seen fail is not known to work, and one that
# fires on correct state is worse than none:
#   RED   gate fails -> rc 70, scratch origin UNCHANGED
#   GREEN gates pass -> rc 0,  scratch origin ADVANCED
#
# Exit: 0 both arms correct · 1 a property failed · 2 instrument blind.
set -uo pipefail
cd "$(dirname "$0")/.."
SCRIPT=bin/land-round.sh
[ -f "$SCRIPT" ] || { echo "INSTRUMENT BLIND: no $SCRIPT" >&2; exit 2; }

# The substitution below must actually match. ⚠️ An inert sed leaves the real
# gates in place, the scratch run fails for an unrelated reason (no mix project),
# and the RED arm passes FOR THE WRONG REASON -- the exact vacuous-control trap
# bin/mutate.sh exists for. So: count the matches, and refuse on zero.
n_gates=$(grep -c '^gate ' "$SCRIPT")
[ "$n_gates" -ge 1 ] || {
  echo "INSTRUMENT BLIND: no 'gate ' invocations in $SCRIPT -- it may have been" >&2
  echo "                 restructured. This check no longer knows what it is testing." >&2
  exit 2
}

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

build_scratch() {  # build_scratch <gate-command>
  rm -rf "$T/repo" "$T/origin.git"
  git init -q --bare "$T/origin.git"
  git init -q -b main "$T/repo"
  cd "$T/repo"
  git config user.email t@t; git config user.name t
  mkdir -p bin
  # Substitute EVERY gate line with the controllable probe, and drop the
  # mix-specific line that has no meaning in a scratch repo.
  sed -e "s|^gate .*|gate \"probe\" $1|" -e '/^mix deps.get/d' "$OLDPWD/$SCRIPT" > bin/land-round.sh
  echo seed > seed.txt; git add -A; git commit -qm seed
  git remote add origin "$T/origin.git"; git push -q -u origin main
  git checkout -q -b feature; echo work > work.txt; git add -A; git commit -qm work
  git checkout -q main
  cd - >/dev/null
}

run_arm() {  # run_arm <gate-command>; echoes "<rc> <origin-before> <origin-after>"
  build_scratch "$1"
  local before after rc
  before=$(git -C "$T/repo" rev-parse origin/main)
  ( cd "$T/repo" && bash bin/land-round.sh feature ) > "$T/out.$2" 2>&1
  rc=$?
  git -C "$T/repo" fetch -q origin
  after=$(git -C "$T/repo" rev-parse origin/main)
  echo "$rc $before $after"
}

fail=0

# ── RED ARM: a deliberately failing gate ──────────────────────────────────────
read -r rc before after <<< "$(run_arm false red)"
if [ "$rc" -eq 70 ] && [ "$before" = "$after" ]; then
  echo "  ok   RED   failing gate -> rc 70, scratch origin unchanged (push NOT reached)"
else
  echo "  FAIL RED   expected rc 70 with origin unchanged; got rc $rc, ${before:0:7} -> ${after:0:7}"
  sed 's/^/         | /' "$T/out.red"; fail=1
fi
grep -q 'not pushing' "$T/out.red" || { echo "  FAIL RED   refusal text absent from output"; fail=1; }

# ── GREEN ARM: gates pass. ⭐ Without this, a script that refused ALWAYS would
#    pass the red arm and be reported as correct.
read -r rc before after <<< "$(run_arm true green)"
if [ "$rc" -eq 0 ] && [ "$before" != "$after" ]; then
  echo "  ok   GREEN passing gates -> rc 0, scratch origin advanced (push reached)"
else
  echo "  FAIL GREEN expected rc 0 with origin advanced; got rc $rc, ${before:0:7} -> ${after:0:7}"
  sed 's/^/         | /' "$T/out.green"; fail=1
fi
grep -q '^LANDED:' "$T/out.green" || { echo "  FAIL GREEN no LANDED verdict"; fail=1; }

echo "---"
echo "gate invocations substituted: $n_gates"
if [ "$fail" -eq 0 ]; then
  echo "VERDICT: PASS -- a failing gate never reaches git push; passing gates do."
  exit 0
fi
echo "VERDICT: FAIL -- the landing script's refusal property is broken." >&2
echo "VERDICT: FAIL -- the landing script's refusal property is broken."
exit 1
