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
# ⛔ `-e` IS DELIBERATELY ABSENT AND THAT IS LOAD-BEARING, NOT AN OVERSIGHT.
# This script reports on a corpus, so it MUST survive commands that legitimately
# return non-zero: `grep -c` on no match, a false `[ ]` in a `&&` chain, a diff that
# finds a difference. Under `set -e` several of those abort MID-REPORT, and the abort
# looks exactly like a clean early finish.
# ⚠️ commonplace-biscuit's rule: WHEN YOU CHECK AND COME BACK CLEAN, CHECK WHETHER YOUR
# CLEANLINESS IS LOAD-BEARING OR INCIDENTAL. Mine is load-bearing, and `set -e` is the
# single most natural hardening someone would later apply -- it would arm silently.
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
  # ⛔ NO `cd`. commonplace-log-reducer, 2026-08-27, and it is the structural fix rather
  # than a guard: CWD IS THE ONE PIECE OF A COMMAND'S STATE THAT APPEARS NOWHERE IN THE
  # COMMAND. A ref appears in `git show main:`; a path appears in a grep; an arm appears
  # in an rc. `cwd` appears in none of them, and it is inherited from a statement that has
  # already finished.
  # ⚠️ WHAT THIS PREVENTS, CONCRETELY: below are `git add -A`, `git commit` and two
  # `git commit -qam`. Under the old `cd "$T/repo"` -- unguarded, in a script where `-e`
  # is deliberately absent -- a failed `cd` ran every one of them against THIS repository.
  # commonplace-plan hit exactly that at 19:11Z in another tree: a `cd` that had outlived
  # its statement, and `-a` meaning nothing in the command could disagree with its belief
  # about where it was standing.
  # ⛔ A GUARD WAS NOT ENOUGH AND I TRIED IT FIRST: `cd ... || exit 2` sits inside
  # `$(run_arm ...)`, a command substitution, so the `exit` left only the subshell and the
  # run continued to a generic FAIL at rc 1. The red arm is what found that -- the fix I
  # had just written did not work, and reasoning about it said it did.
  local R="$T/repo"
  rm -rf "$R" "$T/origin.git"
  git init -q --bare "$T/origin.git"
  git init -q -b main "$R"
  git -C "$R" config user.email t@t; git -C "$R" config user.name t
  mkdir -p "$R/bin"
  # Substitute EVERY gate line with the controllable probe, and drop the
  # mix-specific line that has no meaning in a scratch repo.
  # ⛔ ALSO NEUTRALISE THE HOISTED SLOT CHECK. It is a HOST-level interlock about the shared
  # box; a scratch repo in /tmp holds no slot and needs none, and the property under test here
  # is "does the landing script reach `git push`", not "did someone queue".
  # ⚠️ FOUND BY THIS GATE GOING RED THE MOMENT require-slot was hoisted (errata V16): every arm
  # returned rc 76 before reaching the logic it exists to test. That is the gate working -- and
  # I had already written "all 6 arms ok" into the errata from EXPECTATION while the screen said
  # FAIL. The output was on the screen and I did not read it.
  sed -e "s|^gate .*|gate \"probe\" $1|" \
      -e 's|^bash "$root/bin/require-slot.sh" .*|true  # slot check: not applicable in a scratch repo|' \
      -e '/^mix deps.get/d' "$SCRIPT" > "$R/bin/land-round.sh"
  echo seed > "$R/seed.txt"; echo shared > "$R/shared.txt"
  git -C "$R" add -A; git -C "$R" commit -qm seed
  git -C "$R" remote add origin "$T/origin.git"; git -C "$R" push -q -u origin main
  git -C "$R" checkout -q -b feature; echo work > "$R/work.txt"
  git -C "$R" add -A; git -C "$R" commit -qm work
  git -C "$R" checkout -q main
  if [ "${2:-}" = "conflict" ]; then
    # Both sides rewrite the same line -> the merge cannot succeed.
    git -C "$R" checkout -q feature; echo from-feature > "$R/shared.txt"
    git -C "$R" commit -q shared.txt -m feature-side
    git -C "$R" checkout -q main;    echo from-main    > "$R/shared.txt"
    git -C "$R" commit -q shared.txt -m main-side
    git -C "$R" push -q origin main
  fi
}

run_arm() {  # run_arm <gate-command> <label> [conflict]; echoes "<rc> <before> <after>"
  build_scratch "$1" "${3:-}"
  local before after rc
  before=$(git -C "$T/repo" rev-parse origin/main)
  # ⛔ NO --root, and no inherited root: the scratch copy must resolve its own
  # repository from its own location. If it ever resolved to the real repo this
  # test would act on it, which is the one outcome worse than not testing.
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

# ── CONFLICT ARM: the merge itself fails ──────────────────────────────────────
# ⛔ THE THIRD RESIDUE STATE. Before 2026-08-25 this exited under `set -e` with NO
# OUTPUT, leaving a conflicted merge in progress. It was found by hitting it for
# real while landing round P2, and the hand demonstration of the fix cost two
# rounds of lost work in the live repository. ⭐ THAT IS WHY IT IS AN ARM HERE:
# this file is hermetic and has never cost anything, and the hand demonstrations
# it replaces cost something twice.
read -r rc before after <<< "$(run_arm true conflict conflict)"
if [ "$rc" -eq 68 ] && [ "$before" = "$after" ]; then
  echo "  ok   CONF  conflicting merge -> rc 68, scratch origin unchanged"
else
  echo "  FAIL CONF  expected rc 68 with origin unchanged; got rc $rc, ${before:0:7} -> ${after:0:7}"
  sed 's/^/         | /' "$T/out.conflict"; fail=1
fi
for want in 'CONFLICTED' 'IN PROGRESS' 'git merge --abort' 'resolve on the branch'; do
  grep -qF -- "$want" "$T/out.conflict" || { echo "  FAIL CONF  refusal text missing: $want"; fail=1; }
done

# ── DISCRIMINATOR ARMS: does capture_executed CLASSIFY a plain/trace disagreement? ──
# ⛔ WHY THESE ARE ARMS AND NOT A ONE-OFF DEMO. I proved the classification once with
# hand-written stubs. commonplace-markdown and commonplace-cell both refused to land
# the same branch on the grounds that it had never been SEEN TO FIRE, and they are
# right that reasoned-about and watched-working are different objects. ⭐ A stub demo
# run once is a demonstration; the same stub run by a gate on every landing is an arm.
# The real function is sourced out of land-round.sh, so this exercises the shipped
# code path rather than a copy of it.
# ⚠️ STATED BOUNDARY: this proves the CLASSIFICATION LOGIC on synthetic rc values. It
# does not prove that a real ExUnit timeout travels through the whole wiring -- both
# halves of that are measured separately (plain rc 2 with TimeoutError vs traced rc 0,
# on this tree) but their composition in one live landing is not yet watched.
disc() {  # disc <label> <plain-rc> <trace-rc> <expected-substring>
  local label="$1" prc="$2" trc="$3" want="$4" out rc=0
  ( set +u
    CLEANUP_FILES=()
    # shellcheck disable=SC1090
    source <(sed -n '/^capture_executed()/,/^}/p' "$OLDPWD/bin/land-round.sh")
    n=$(mktemp)
    capture_executed "$n" sh -c '
      if [ "$1" = "--trace" ]; then printf "  * test a (M) [L#1]\n\n1 test, 0 failures\n"; exit '"$trc"';
      else printf "\n1 test, 0 failures\n"; exit '"$prc"'; fi' _
    rm -f "$n"
  ) > "$T/disc.$label" 2>&1 || rc=$?
  if grep -qF -- "$want" "$T/disc.$label"; then
    echo "  ok   DISC  $label -> names the class"
  else
    echo "  FAIL DISC  $label -> expected [$want]"
    sed 's/^/         | /' "$T/disc.$label"; fail=1
  fi
}
disc plain-fails-trace-passes 2 0 "TIMING-OR-CONCURRENCY CLASS"
disc both-fail               2 2 "NOT the trace class"
disc trace-only-fails        0 3 "traced names run failed"

echo "---"
echo "gate invocations substituted: $n_gates"
if [ "$fail" -eq 0 ]; then
  echo "VERDICT: PASS -- failing gate and conflicting merge both refuse; passing gates push."
  exit 0
fi
echo "VERDICT: FAIL -- the landing script's refusal property is broken." >&2
echo "VERDICT: FAIL -- the landing script's refusal property is broken."
exit 1
