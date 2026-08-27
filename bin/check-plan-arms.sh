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
# DECLARE a landing-suite arm in a plan with a marker line:
#   <!-- ARM: substring that must appear in a test name -->
# Declare an intentionally excluded red arm separately:
#   <!-- ARM-DIVERGENCE: substring that must appear in a test name -->
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
EXECUTED_FILE=""
if [ "${1:-}" = "--executed" ] && [ "$#" -eq 2 ]; then
  EXECUTED_FILE=$2
  if [ ! -r "$EXECUTED_FILE" ]; then
    echo "FAIL: executed-test names file is not readable: $EXECUTED_FILE" >&2
    exit 2
  fi
elif [ "$#" -gt 0 ] && { [ "${1:-}" != "--self-test" ] || [ "$#" -ne 1 ]; }; then
  echo "FAIL: unrecognised arguments. Usage: $(basename "$0") [--self-test | --executed <file>]" >&2
  echo "      (exit 2 = the gate did not run. 1 would mean it ran and arms are missing.)" >&2
  exit 2
fi

if [ "${1:-}" = "--self-test" ]; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  mkdir -p "$T/docs" "$T/test" "$T/lib" "$T/bin"
  printf '<!-- ARM: widget alignment -->\n<!-- ARM: gasket tolerance -->\n<!-- ARM-DIVERGENCE: spring tension -->\n' > "$T/docs/p.md"
  printf '# widget alignment and spring tension are handled here\ndef gasket_tolerance, do: :ok\n' > "$T/lib/impl.ex"
  printf '  test "something entirely unrelated" do\n  end\n' > "$T/test/a_test.exs"
  printf 'something entirely unrelated\n' > "$T/executed.names"
  cp "$0" "$T/bin/"
  out=$("$T/bin/$(basename "$0")" --executed "$T/executed.names" 2>&1); rc=$?
  n_miss=$(printf '%s\n' "$out" | grep -c 'MISSING')
  counted=$(printf '%s\n' "$out" | grep -c 'executed tests: 1')
  printf '  test "widget alignment" do\n  end\n  test "gasket tolerance" do\n  end\n  @tag :divergence\n  test "spring tension" do\n  end\n' > "$T/test/a_test.exs"
  printf 'ExUnit.configure(exclude: [:divergence])\n' > "$T/test/test_helper.exs"
  no_run=$("$T/bin/$(basename "$0")" 2>&1); no_run_rc=$?
  if [ "$rc" -eq 1 ] && [ "$n_miss" -eq 3 ] && [ "$counted" -eq 1 ] &&
     [ "$no_run_rc" -eq 2 ] && printf '%s\n' "$no_run" | tail -1 | grep -q '^VERDICT: NO RUN --'; then
    echo "SELF-TEST PASS: executed matcher missed 3/3 code/comment-only arms; count named 1 executed test; no-run mode refused with NO RUN (rc 2)."
    exit 0
  fi
  echo "SELF-TEST FAIL: matcher rc=$rc missing=$n_miss counted=$counted; no-run rc=$no_run_rc." >&2
  printf '%s\n' "$out" >&2
  printf '%s\n' "$no_run" >&2
  exit 3
fi

# ⭐ ARM vs ARM-PLANNED. An arm declared for a round that has NOT been dispatched
# is absent for a different reason than an arm missing from landed work, and
# mixing them makes RED ambiguous -- which is how a gate becomes permanently red
# and then ignored. `ARM:` = contract on landed work, and its absence FAILS.
# `ARM-PLANNED:` = contract on a future round, reported and NOT failing. Promote
# the marker to `ARM:` when that round is dispatched.
# ⛔ docs/evidence/ IS EXCLUDED, AND THE MARKER MATCH IS NON-GREEDY. Both were found the hard way.
# 2026-08-27: this repo published a DIFF OF THIS SCRIPT into docs/evidence/ so five other repos could
# apply a tested change. That diff's context contains this file's own --self-test fixture, whose
# literal text includes `<!-- ARM: widget alignment -->`. ⇒ the gate read its own test data as
# DECLARED ARMS and failed looking for a test named after them. Prose about a pattern contains the
# pattern -- and here the prose was the gate's own patch, filed in the directory the gate scans.
# The greedy `.*` made it worse by spanning from one marker into the next, producing an arm name
# that never existed in either place.
# ARMS ARE DECLARED IN PLANS. Evidence documents quote syntax; they must not be able to declare it.
# ⛔ AND A BACKTICKED MARKER IS PROSE, NOT A DECLARATION -- the same convention this repo already
# uses for section citations (bare `§N` cites, `` `§N` `` mentions), which nobody had transferred here.
# 2026-08-27: M6's plan EXPLAINS this gate's marker/tag defect and, doing so, writes `<!-- ARM: -->`
# inside backticks. The gate read it as a declared arm with an EMPTY NAME -- and an empty name is a
# substring of every test, so it matched the first test it saw and reported a mismatch against a
# marker that does not exist. ⇒ prose about a pattern contains the pattern, for the sixth time in
# one day, and this time inside the document explaining the pattern.
# An empty arm name is ALWAYS a defect: it cannot be checked and it matches everything.
_arm_docs() { find docs -name '*.md' -not -path 'docs/evidence/*' -print0; }
_strip_prose() { sed 's/`[^`]*`//g'; }   # drop backticked spans before looking for markers
mapfile -t ARMS    < <(_arm_docs | xargs -0 sed 's/`[^`]*`//g' 2>/dev/null | grep -o '<!-- ARM: [^>]*-->' | sed 's/<!-- ARM: //; s/ *-->//')
mapfile -t PLANNED < <(_arm_docs | xargs -0 sed 's/`[^`]*`//g' 2>/dev/null | grep -o '<!-- ARM-PLANNED: [^>]*-->' | sed 's/<!-- ARM-PLANNED: //; s/ *-->//')
mapfile -t DIVERGENCE < <(_arm_docs | xargs -0 sed 's/`[^`]*`//g' 2>/dev/null | grep -o '<!-- ARM-DIVERGENCE: [^>]*-->' | sed 's/<!-- ARM-DIVERGENCE: //; s/ *-->//')
mapfile -t DIVERGENCE_PLANNED < <(_arm_docs | xargs -0 sed 's/`[^`]*`//g' 2>/dev/null | grep -o '<!-- ARM-DIVERGENCE-PLANNED: [^>]*-->' | sed 's/<!-- ARM-DIVERGENCE-PLANNED: //; s/ *-->//')
for _a in "${ARMS[@]}" "${DIVERGENCE[@]}"; do
  if [ -z "$_a" ]; then
    echo "FAIL: an ARM marker declares an EMPTY name. An empty name is a substring of every test," >&2
    echo "      so it would match anything and certify nothing. Name the arm or delete the marker." >&2
    exit 2
  fi
done
if [ "${#ARMS[@]}" -eq 0 ]; then
  echo "FAIL: no ARM markers found in docs/ -- the gate has nothing to check." >&2
  echo "      (A gate with an empty corpus passes vacuously. That is the bug this file exists for.)" >&2
  exit 2
fi

SOURCE_TESTS=$(grep -rho '^\s*test "[^"]*"' test/ | sed 's/.*test "//; s/"$//')
if [ -n "$EXECUTED_FILE" ]; then
  TESTS=$(grep -v '^$' "$EXECUTED_FILE")
  POPULATION_LABEL="executed tests"
else
  TESTS=$SOURCE_TESTS
  POPULATION_LABEL="test source lines"
fi

# ⭐ EXCLUDED-BY-TAG RECONCILIATION (added 2026-08-27 by commonplace-markdown; see the demonstration
# in that repo's docs/evidence/2026-08-27-arm-marker-tag-mismatch.md).
# WHY: source-only operation reads DEFINED test names. Whether a test RUNS is decided by its `@tag`,
# test_helper's exclude list, and CLI exclusions. So adding
# `@tag :something_excluded` to a test while leaving its `<!-- ARM: -->` marker in place makes
# ExUnit skip it and made the old source matcher print "ok" for it. Demonstrated live against
# landed work: an arm guarding a document-bricking fix was switched off and still counted as
# covered. `--executed` closes both exclusion routes for ordinary arms by observing the run.
# Same family as a `--min` that counts defined rather than executed tests, reached by a different
# route: a MARKER that asserts a test runs while the CODE decides it does not.
# THE RULE: the TAG decides whether an arm runs; the marker declares intent; disagreement FAILS.
# RETIREMENT CONDITION FOR THE CLI-EXCLUSION WARNING: do not claim that route closed until
# `--executed` is wired at every gating call site. M10 wires the landing call; direct no-run use
# remains a declared-configuration check. Keep this reconciliation even then: it also catches an
# arm that runs in the wrong population, which an executed-name hit alone cannot diagnose.
EXCLUDED_TAGS=$(sed -n 's/^[[:space:]]*ExUnit.configure(exclude:[[:space:]]*\[\(.*\)\]).*/\1/p' test/test_helper.exs 2>/dev/null | tr -d ' :' | tr ',' ' ')
# ⚠️ @moduletag EXCLUDES EVERY TEST IN THE MODULE -- measured, and the first version of this
# reconciliation was blind to it, which would have let ONE line switch off a whole file of declared
# arms while this gate still reported them covered. That is the defect this patch exists to fix,
# surviving inside the patch. A module-level tag applies until the next `defmodule`.
TAGGED=$(awk '
  # REPRODUCED HERE BEFORE FIXING: a nested defmodule plus a real @moduletag gave
  # "0 marker/tag mismatch(es)" where the un-nested case gave 11, and the silence was
  # masked because the --executed half still failed the landing -- two halves that
  # agree hide the silence of either.
  # ⛔ @tag PERSISTS UNTIL THE NEXT test -- MEASURED by commonplace-markdown, and it is the
  # OPPOSITE of what the first fleet fix assumed. ExUnit excluded all three of these:
  #     @tag :p1 / a comment  / test ...   -> EXCLUDED
  #     @tag :p2 / a def      / test ...   -> EXCLUDED
  #     @tag :p3 / test ...               -> EXCLUDED
  # ⇒ clearing a pending tag at a nested defmodule, a comment or a def is a FALSE
  # NEGATIVE: the arm is excluded and the gate says nothing. I had the nested-clear
  # line applied for four minutes on the strength of a relay; it is removed here.
  # Only a COLUMN-0 defmodule ends a scope; only a test line consumes pending tags.
  # Tags ACCUMULATE -- several may precede one test and ExUnit honours all.
  # ⚠ Column-0 is a PROXY, NOT A PARSER: it fails on an indented top-level test
  # module. Detect with:  grep -rn "^[[:space:]]\+defmodule .*Test do" test/
  /^defmodule[[:space:]]/ { modtag=""; pending=""; next }
  /^[[:space:]]*@moduletag[[:space:]]+:/ { t=$0; sub(/^[[:space:]]*@moduletag[[:space:]]+:/,"",t); sub(/[^A-Za-z0-9_].*$/,"",t); modtag = (modtag=="" ? t : modtag " " t); next }
  /^[[:space:]]*@tag[[:space:]]+:/ { t=$0; sub(/^[[:space:]]*@tag[[:space:]]+:/,"",t); sub(/[^A-Za-z0-9_].*$/,"",t); pending = (pending=="" ? t : pending " " t); next }
  /^[[:space:]]*test[[:space:]]+"/ {
    n=$0; sub(/^[^"]*"/,"",n); sub(/".*$/,"",n)
    k=split(pending, P, " "); for (i=1; i<=k; i++) print P[i] "\t" n
    k=split(modtag,  M, " "); for (i=1; i<=k; i++) print M[i] "\t" n
    pending=""; next
  }
  # \u26d4 THE CATCH-ALL THAT USED TO LIVE HERE -- `{ pending="" }` -- WAS A THIRD
  # INSTANCE OF THE SAME DEFECT, and no fleet message named it: both fixes were
  # framed as being about the defmodule line. It cleared a pending @tag on ANY
  # unmatched line, so `@tag :x` followed by a `def` lost the tag while ExUnit
  # still excluded the test. MEASURED HERE: ExUnit reported `3 tests, 0 failures,
  # 1 excluded` while this gate reported 0 mismatches.
  # \u2b50 Nothing but a `test` line clears pending. Removing the catch-all is the
  # whole of it; the blank-line skip went with it because it existed only to feed it.
' $(find test -name '*.exs' 2>/dev/null) 2>/dev/null)
mismatch=0
for arm in "${ARMS[@]}"; do
  hit_tag=""
  while IFS=$'\t' read -r _tag _name; do
    [ -z "$_name" ] && continue
    [ -n "$hit_tag" ] && continue          # one report per ARM, not per matching test instance:
    case "$_name" in *"$arm"*)             # a generated arm matches many tests and would inflate the count
      for e in $EXCLUDED_TAGS; do [ "$_tag" = "$e" ] && hit_tag="$_tag"; done;;
    esac
  done <<< "$TAGGED"
  if [ -n "$hit_tag" ]; then
    printf '  MISMATCH  ARM "%s" is declared as a covered arm but its test carries tag :%s (via @tag or @moduletag), which test_helper excludes -- it does not run\n' "$arm" "$hit_tag"
    mismatch=$((mismatch+1))
  fi
done
# my copy also carries an ARM-DIVERGENCE population: an arm declared there must actually be excluded,
# or it is silently running inside the gated suite instead of the expected-red one.
for arm in "${DIVERGENCE[@]}"; do
  found=0
  while IFS=$'\t' read -r _tag _name; do
    [ -z "$_name" ] && continue
    case "$_name" in *"$arm"*) for e in $EXCLUDED_TAGS; do [ "$_tag" = "$e" ] && found=1; done;; esac
  done <<< "$TAGGED"
  if [ "$found" -eq 0 ]; then
    printf '  MISMATCH  ARM-DIVERGENCE "%s" carries no excluded tag -- it runs inside the gated suite, not the expected-red population\n' "$arm"
    mismatch=$((mismatch+1))
  fi
done
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
mapfile -t DECLARED < <(_arm_docs | xargs -0 sed 's/`[^`]*`//g' 2>/dev/null | grep -o '<!-- MODULE: [^>]*-->' | sed 's/<!-- MODULE: //; s/ -->//')
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

divergence_miss=0
for arm in "${DIVERGENCE[@]}"; do
  if grep -qiF -- "$arm" <<< "$SOURCE_TESTS"; then
    printf '  divergence ok      %s\n' "$arm"
  else
    printf '  divergence MISSING %s\n' "$arm"; divergence_miss=$((divergence_miss+1))
  fi
done

echo "---"
echo "declared arms: ${#ARMS[@]}   planned (not failing): ${#PLANNED[@]}   divergence arms (separate): ${#DIVERGENCE[@]}   divergence planned: ${#DIVERGENCE_PLANNED[@]}   $POPULATION_LABEL: $N_TESTS   missing: $miss   divergence missing: $divergence_miss   undeclared modules: $undeclared"
miss=$((miss + divergence_miss + undeclared))

# ⛔ THE VERDICT IS PRINTED TO STDOUT AS THE LAST LINE, ON PURPOSE.
# A caller who writes `check-plan-arms.sh | tail -4; echo $?` reads TAIL's exit
# code, not this script's -- it printed FAIL and the caller read 0. That happened
# on this gate's first external verification. The exit code is still the contract,
# but a pipeline that swallows it must still SEE the verdict.
if [ "$miss" -eq 0 ] && [ "$mismatch" -eq 0 ] && [ -n "$EXECUTED_FILE" ]; then
  echo "VERDICT: PASS -- every declared arm ran in the observed gating population; ${#DIVERGENCE[@]} divergence arm(s) tracked as a separate, not-covered population."
  exit 0
elif [ "$miss" -eq 0 ] && [ "$mismatch" -eq 0 ]; then
  echo "VERDICT: NO RUN -- declared configuration only; no run observed; exiting 2 because landing execution was not certified."
  exit 2
else
  n_arm=$((miss - divergence_miss - undeclared))
  [ -n "$EXECUTED_FILE" ] && arm_absence="with no executed test" || arm_absence="with no test source line"
  echo "VERDICT: FAIL -- $n_arm declared arm(s) $arm_absence, $divergence_miss divergence arm(s) with no test source line, $undeclared undeclared module(s), $mismatch marker/tag mismatch(es); divergence is a separate, not-covered population." >&2
  echo "VERDICT: FAIL -- $n_arm declared arm(s) $arm_absence, $divergence_miss divergence arm(s) with no test source line, $undeclared undeclared module(s), $mismatch marker/tag mismatch(es); divergence is a separate, not-covered population."
  exit 1
fi
