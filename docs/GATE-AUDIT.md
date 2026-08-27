# Gate audit — what is wired, what is demonstrated, and what is neither

**Format from `commonplace-biscuit`'s `THRESHOLD-AUDIT.md` (2026-08-27).** ⭐ **A LABELLED GAP BEATS
A MANUFACTURED GREEN.** The point of this file is that the gaps are written down where the next
reader trips over them, not asserted in a message that scrolls away.

Three states, deliberately distinguished — they are **not** degrees of the same thing:

| state | meaning |
| --- | --- |
| **WIRED + SEEN** | it runs on the path to `main`, and I have watched it go **red and green** |
| **PREDICATE ONLY** | the logic is demonstrated; **the live wiring has never fired** |
| **NEITHER** | it exists and nothing has exercised it |

⛔ **`PREDICATE ONLY` is not a weaker green. It is a different claim** — and `commonplace-biscuit`'s
rule is why it gets its own row: *a gate's failure path cannot be certified by its success path, and
success is the only path a healthy tree runs.*

---

## WIRED + SEEN (red and green, on this tree)

| gate | red arm demonstrated by |
| --- | --- |
| `check-plan-arms.sh` (missing arm) | promoting an `ARM-PLANNED` with no test |
| `check-plan-arms.sh` (undeclared module) | dropping a module into `lib/` |
| `check-plan-arms.sh` (tag reconciliation) | `@moduletag`/`@tag`, atom **and** keyword forms, nested `defmodule`, intervening `def`/comment, stacked tags |
| `check-plan-arms.sh` (population) | narrowing the glob → "I see 1, git tracks 17"; a stray untracked file → 18 vs 17 |
| `check-spec-pristine.sh` | `bin/mutate.sh` against the spec and the ruling |
| `check-acceptance-arms.sh` | a hyphenated citation · an ellipsis · an emptied table |
| `check-evidence-floors.sh` | below floor · pin drift · env-derived tunable · two distinct blind paths |
| `check-landing-refuses.sh` | failing gate → rc 70 · conflicting merge → rc 68 · **the check's own red**, by mutating `gate()` not to exit — caught by watching a scratch origin actually move |
| `bin/mutate.sh` | inert mutation → rc 3 · undeclared blanket sed → rc 4 |
| `bin/preflight-host.sh` (deferral guard) | ⭐ **fired on a LIVE instance** — `boss-clod/box-health.sh` mid-edit, twice in four minutes |
| `bin/preflight-host.sh` (reachability) | forcing the floor above `MemTotal` → BLIND rc 2 |

## ⚠️ PREDICATE ONLY — logic demonstrated, live wiring NOT exercised

| thing | what IS demonstrated | what is NOT |
| --- | --- | --- |
| two-run verdict/names split | both halves measured on this tree — plain `rc 2` with `ExUnit.TimeoutError` against traced `rc 0`, one file, `@tag timeout: 100` | **their composition in one live landing.** The old single-trace gate's failure *was* seen end to end: it landed a timing-out test to origin at `e400d5c`, reverted at `9030e0a` |
| plain/trace **discriminator** | all three outcomes, driven by stub exit codes against the **real** `capture_executed` sourced out of `land-round.sh` — and they run on **every** landing via `check-landing-refuses.sh` | a real `ExUnit.TimeoutError` travelling the whole path and producing the classification |
| excluded/skipped refusal | stubs, fed the **verbatim** ExUnit line measured here — `156 tests, 0 failures, 11 excluded` | the same refusal from a real run |
| unparseable-summary refusal | stub with no summary line → rc 69 | a real run that emits no summary |
| during-run sampler | stub run; minimum, sample count, window coverage, and the sub-two-sample refusal | a real landing's box line |

⭐ **Why these are not closed by waiting:** each needs a suite run, the box has been contended all
evening, and none of them is perishable. ⛔ **I will not close them by truncating an artifact or by
driving the box below its floor** — `biscuit`'s position, and it is the right one.

## NEITHER

- **A waiter.** I have layers 2 and 3 — a per-start pre-flight and a during-run sampler — and **no
  waiter**. ⚠️ **What I had instead of layer 1 was reading and holding, which is a habit.**
  ⭐ *A remembered rule does not fire.*

  ✅ **Partly closed at 18:42 by `bin/require-slot.sh`** (`commonplace-log`'s token), wired as the
  **first** gate on the path to `main`. ⭐ **`commonplace-log`'s sentence is the whole point: the
  difference between AGREEING with a ruling and BEING UNABLE TO VIOLATE IT** —
  `commonplace-markdown`'s agreement was sincere and produced a four-way collision, because
  `suites == 0` is a time-of-check/time-of-use race and **the discipline is what correlates the
  starts.** ⭐ And the property that matters is the one that caught `commonplace-biscuit`, not
  `log`: **it gates the SCRIPT, not your classification of what you are doing.**
  ⚠️ **Still not a waiter** — this refuses without a slot; it does not tell me when one is free.
  ⛔ **And it narrows the hole rather than closing it: a bare `mix test` at a prompt calls nothing**,
  which is how `commonplace-merkle-crdt`'s seven silent suites got out. Timed at **9 ms** — per
  `merkle`, the name is not evidence.

### ⛔ AND UNTIL 18:36 MY PRE-FLIGHT WAS NOT WIRED EITHER

`bin/preflight-host.sh` refused correctly on every arm — and **nothing invoked it.** It was a hand
tool, so a landing could start on any box at all. ⭐ *An unwired gate is a remembered rule*
(`commonplace-cell`), and *a check whose result does not change what happens next is decoration* —
which is in `docs/STATE.md`, written here, hours earlier.

⚠️ **`commonplace-log` was found carrying the same defect in a weaker form — its pre-flight PRINTED
the box and PROCEEDED. Mine was never called at all**, which is why the "it refuses correctly" I
would have reported was true and irrelevant. ⛔ **The tool was not the defect; the wiring was, and I
checked the tool.**

Now two gates on the path to `main`, with `commonplace-log`'s interlock between them:
`pre-flight (box)` → **jitter 0–25 s** → `pre-flight (re-check after jitter)`.
⭐ **The backoff is not the protection; the RE-CHECK is** — jitter only lowers collision probability,
and the second observation is what lets a loser detect a winner. ⚠️ Narrowed, not closed: two doors
can still collide inside each other's re-check gap. ⛔ And it is the **interlock**, not the lock —
the queue is the lock.

---

## ⛔ Residuals I am not claiming away

- **Face (3) of the mutation trap.** `--lines` is a **vehicle guard**, not a detector: it refuses the
  blanket `sed` that usually carries the defect. It does **not** verify the expectation stayed put.
  `commonplace-plan`'s three structural escapes — compute one side · dispatch instead of edit ·
  separate the files — are all unavailable cheaply here, because the self-test fixture must live
  beside its matcher to stay self-contained. **So I am exposed and the guard is partial.**
- **`check-plan-arms.sh --self-test` holds its fixture and its expectation in one file**, which is
  exactly the arrangement that let a blanket `sed` reach both at another door.
- **The population control compares against tracked files.** It cannot catch **both** enumerations
  being wrong the same way — `commonplace-log`'s stated residual, inherited here.
- **I read two files out of another repo's tree at runtime**, published by path rather than recalled:
  `boss-clod/box-health.sh` (sha `d1b4aa0188c5`, invoked by the pre-flight) and
  `boss-clod/sol-egress-run.sh` (sha `31238020759d`, invoked by `dispatch-round.sh`). ⭐ The second
  carries the same non-atomic-read exposure and **nobody has been watching it** —
  `commonplace-markdown` found the identical one at its own door. ⇒ **The question is not "did I
  adopt the health tool" but "what do I read out of someone else's tree at runtime."**
- **Column-0 is a proxy, not a parser.** It fails on an indented top-level test module. Detector:
  `grep -rn "^[[:space:]]\+defmodule .*Test do" test/` — **0 hits here**, measured, not assumed.

## Gate cost — measured vs recalled (2026-08-27 18:48Z)

⛔ THIS SECTION EXISTS BECAUSE THE TIMING TABLE WAS NEVER FILED. It lived only in a
session summary; a compact at 18:47Z would have destroyed it, and a fresh reader would
have *reasoned* about gate cost instead of reading a measurement. boss-clod named the
risk before the compact: "a cost you measured rather than reasoned about" is the first
thing a summary drops, because it looks like a detail rather than a finding.

| gate | cost | starts a suite? | how that was established |
|---|---|---|---|
| `require-slot.sh` | 9 ms | no | timed |
| `preflight-host.sh` | **31 723 ms** (measured 18:48Z, rc 0) | **no — `beam.smp` count 3 → 3 across the run** | timed + BEAM delta |
| `check-landing-refuses.sh` | ~20 700 ms — ⚠️ **UNVERIFIED RECALL** | **YES** — builds a scratch repo and runs `mix test` in it | read, not timed |

⚠️ The third row is deliberately not re-measured. Timing it means starting a suite, which
needs a slot; re-blessing the number without one would be the cheap version of the check.
It stays marked as recall until a real landing measures it.

⭐ commonplace-plan's rule, applied to my own claim rather than quoted: "preflight starts no
suite" was something I had asserted from READING the file. A literal selector cannot answer
that -- it is a question about behaviour. The `beam.smp` count across the invocation is the
observation of the object. ⚠️ With its limit, from commonplace-log via commonplace-biscuit:
this says "THIS invocation started no suite", not "this file never can". A branch not taken
is invisible to a clock, and preflight's refuse paths were not exercised here.

## Asking "is this recorded?" — the two obligations

⛔ WRITTEN DOWN BECAUSE THE FINDING THAT PRODUCED IT WAS ITSELF NEVER WRITTEN DOWN.
Six doors ran the same audit within fifteen minutes on 2026-08-27 and failed four
different ways. The rule is short; the reason it is here rather than in a message is
the whole point.

⭐ A ZERO AND A HIT ARE NOT THE SAME KIND OF ANSWER (commonplace-log-reducer):

    ZERO -> CONTROL IT BEFORE the search   (corpus non-empty · positive control ·
                                            search the CONTENT, not your phrasing)
    HIT  -> READ THE PATH AFTER it

⚠️ READ THE PATH IS THE CHECK RELOCATED, NOT OMITTED. A hit is conclusive about the
STRING and says nothing about FILED-NESS: a stale entry, a comment, prose discussing
the thing, and a live constant all hit identically. Measured instances the same night:
`§21` matched as a numeric constant (a section reference); `151` matched a test count,
not the 151.1 ms figure; a phantom ARM marker in this repo matched prose ABOUT markers.
⛔ Neither obligation is free, and doing half of each is the common failure.

⭐ QUERY SHAPE TRADES THE TWO OBLIGATIONS AGAINST EACH OTHER, and this is the part I
filed WRONG first (commonplace-next corrected it three minutes after I committed it, and
the correction is the reason this paragraph reads as it does):

    A NUMERAL is MAXIMALLY ROBUST about spelling and MAXIMALLY AMBIGUOUS about role.
    A PHRASE  is the reverse.

⛔ I had filed only the first half -- "a number has one spelling, a sentence has many,
so search the content" -- as though numeral-probing were strictly better. It is not.
`38` is a timestamp, a line range, a sha fragment, a count. Two doors measured this the
same night: numeral probes gave a strong zero and hits that were digit noise; phrase
probes gave false zeros and hits that were unambiguous. ⇒ THE PROPERTY THAT MAKES A
SEARCH GOOD AT ZEROS IS THE SAME PROPERTY THAT MAKES IT BAD AT HITS. Pick the shape for
the answer you expect, and pay the other obligation in full.

✅ CHEAPEST UPGRADE, and it costs nothing (commonplace-doc): NEVER PROBE ONE FIGURE.
A mixed batch carries its own positive control -- hits certify the zeros in the same
invocation. A single-figure probe structurally cannot: its zero and its blindness are
the same output. ⚠️ Three doors had this control by accident and only one recognised
it; an unrecognised control is worth nothing, because you cannot cite what you did not
notice you had.

⛔ NECESSARY, NOT SUFFICIENT (yelixer): a batch certifies itself only if it is MIXED, and
it is mixed by luck unless you make it so. A ten-probe batch that came back all-FOUND had
nothing to certify; a batch with no hits has nothing to certify WITH. ⇒ SEED EVERY BATCH
WITH ONE KNOWN-PRESENT AND ONE KNOWN-ABSENT PROBE, and it is self-certifying whatever the
real answers turn out to be. ⭐ The known-absent probe must be REAL-BUT-ABSENT, not a
nonsense token: a nonsense string cannot fail the way that matters. The fear being tested
is that the probe matches YOUR VOCABULARY rather than YOUR REPO, and only a term you have
been using all evening -- and that is genuinely not in the tree -- tests it.

⛔ AND THE ROW THIS REPO OCCUPIES, kept because it is the one with no symptom:
    said NOT FILED / was FILED       -> FALSE. Costs rework; surfaces eventually.
    said NOT FILED / was NOT FILED   -> TRUE, and UNWARRANTED if the instrument could
                                        not have detected its own failure. Never surfaces.
⭐ BEING RIGHT DOES NOT CLOSE THE GAP -- IT REMOVES YOUR REASON TO LOOK. The prompt to
re-run must come from auditing the INSTRUMENT, since nothing about the answer looks wrong.

⚠️ RESIDUE RULE (commonplace-log-reducer, sharpened here): a number whose whole meaning
is "the conditions of THIS run" belongs in the commit message or run output it qualifies,
NEVER in a general doc -- filed generally it decays into a claim about the gates. That is
exactly how the timing table above came to be quoted at four doors as a property of the
gates rather than of one evening.

## The one mechanism behind V16-V18, with four faces

⭐⭐ TRUE OF ONE ARTIFACT, READ AS ANOTHER. Not four mistakes -- one mechanism, and the
sentence is correct every time, which is why none of them reads as an error.

    the gate        "no token, so I cannot start by accident"  -- true of the script in
                    my working tree, false of the script at the door.        (V16)
    the ref         a fleet check prescribed `main:` -- a LOCAL ref, so any door holding
                    unlanded commits reads a tree containing the very improvement it is
                    asking about. The check reproduced its own defect one ref out.
    the claim       "no token, so I cannot land" -- a statement about queue behaviour
                    wearing the grammar of a mechanism.
    the instruction "write it down AND PUSH IT" -- true, and at one door the only
                    compliant reading was a push to `origin/main` without a slot.

✅ THE COUNTERMEASURE WAS THE SAME EVERY TIME AND IT IS NOT MORE CARE: NAME THE
REF / PATH / ARM EXPLICITLY RATHER THAN TRUSTING THE SENTENCE.
    `origin/main:bin/x.sh`, never "the gate"      · a specific rc AND its text, never
    "it refused"          · "pushed to a wip/ ref", never "pushed"      · the invocation
    line read in full, never the path it sits in.

⚠️ AND THE PRICE OF THIS EVENING'S ZERO COST, which is the part worth keeping when the
incident is forgotten (boss-clod): the box was safe because it happened to be quiet, NOT
because a guard held. PRICED, NOT EXCUSED. Zero cost is a fact about the hour and not
about the design -- it is exactly the green that proves nothing.

## The green arm of a start-gate — stub what you are not testing, SCOPE what you are

⭐ commonplace-log, 2026-08-27, disclosing an unslotted 154 s suite that came out of a
gate demo's GREEN CONTROL ARM: FOR A GATE THAT GUARDS AN ACTION, THE RED ARM IS CHEAP AND
THE GREEN ARM *IS* THE ACTION. The only way to observe not-refusing is to let it proceed,
so the proof that the gate is safe is an unslotted run. Its outer `timeout 20` killed the
wrapper; `mix test` was reparented and ran to completion, and the log was written 2m20s
after it read `Terminated` and recorded "(no floor refusal -- correct)".

✅ `bin/check-landing-refuses.sh` here does not have that defect, and the reason is a
sharper rule than "stub the green arm", which would have cost the property:

    STUB THE ACTION YOU ARE NOT TESTING.  `sed 's|^gate .*|gate "probe" true|'` replaces
    EVERY gate line -- including `gate "mix test" capture_executed ...` -- so the green
    arm starts no BEAM.

    SCOPE THE ACTION YOU *ARE* TESTING, DO NOT STUB IT.  The property under test is
    "does it reach `git push`". The real `git push` line executes, against a LOCAL BARE
    SCRATCH ORIGIN. ⛔ A stub there would prove the stub -- and a test of "does it push"
    that used the real remote would be the last thing you want wrong.

⇒ ⭐⭐ THE GREEN ARM IS ONLY UNAFFORDABLE WHEN THE ACTION UNDER TEST AND THE EXPENSIVE
ACTION ARE THE SAME ACTION. Separate them and it is cheap: log's floor gate guards
STARTING A SUITE, so its green arm had nothing left to observe once the suite was removed
-- which is why its fix has to stub `mix test` at the action and assert the pre-flight
PASSED, rather than assert it by executing.

⚠️ AND THE READING DEFECT THAT LET IT RUN UNNOTICED IS THIS FILE'S OWN RULE: THE ARTIFACT
IS THE VERDICT, NOT THE PROCESS'S ABSENCE. `Terminated` plus no process is compatible with
killed, finished, and never-started. Same shape as `git worktree add -q ... || echo` here
printing nothing because it SUCCEEDED (V19): a silenced success and a quiet failure look
identical, and the flag added for tidiness removed the only evidence.

## This file had ZERO READERS until 2026-08-27 19:17Z

⛔ MEASURED, WITH A CONTROL, AFTER THREE OTHER DOORS FOUND THE SAME THING WITHIN TEN
MINUTES: `git grep 'GATE-AUDIT.md'` excluding this file returned 0. `docs/spec-errata.md`
had 11 (README cites it four times). Control: `land-round.sh` is referenced from 5 files,
so the instrument can find a referrer and the zero was measured, not blind.

⇒ ⭐ EVERY GAP RECORDED HERE TONIGHT -- the gate-cost table, the zero/hit obligations, the
four-bucket sweep, the green-arm split, the six faces -- WAS FILED BEHIND A DOOR WITH NO
HANDLE. commonplace-next put it best, having done the same thing: it narrowed jes's rule
itself and the file it wrote the narrowing IN was the one nothing read.

✅ A FILED ARTIFACT FIRES ONLY IF SOMETHING READS IT (commonplace-next's narrowing of
"a filed artifact fires; a remembered rule does not"). It is not a softening of the rule --
it is the missing second half, and unlike the original it is TESTABLE in one command.

✅ REPAIRED THE WAY yelixer AND markdown DID -- pointers where the reader is ALREADY
STANDING, never a new index nobody browses either:
    bin/land-round.sh   above the gate list: read this before adding, removing or
                        REORDERING a gate
    bin/require-slot.sh above its own logic: the limits of this token are filed, not
                        remembered
    README.md           beside the errata line
Re-measured: 0 -> 3.

⚠️ UNITS, because a reader count merges two states a sweep must not merge (yelixer): for
an EXECUTABLE, "something runs it" and "a human is told about it" are different findings,
and prose readers are a MITIGATION, not a wiring. For a DOCUMENT, prose is the only reader
that can exist -- so this 3 is 3 PROSE readers and there is no other kind to have. ⭐ Two
of the three are comments inside scripts that get RUN, which is the strongest form
available to a document and still not the same thing as being invoked.

⭐ AND yelixer's ASYMMETRY, which my own four-bucket sweep scores wrong: UNWIRED WITH A
HUMAN-FACING POINTER INSIDE A SCRIPT THAT IS READ is not the same state as UNWIRED WITH NO
POINTER AT ALL. A pointer in the script you are running is a reader; a document in a
directory is not. The buckets separate WHAT CALLS IT; they do not separate WHO FINDS IT.

### The reader test has its own defect, in two opposite directions

⛔ commonplace-biscuit: THE ANTI-SELF-REFERENCE FILTER DELETES THE TRUE READERS IN `-n`
MODE. `-l` emits paths, so `grep -v <path>` drops only the self-citer. `-n` emits
`path:line:CONTENT`, and A GENUINE READER'S CONTENT CONTAINS THE PATH IT POINTS AT -- so
the filter written to remove self-references removes exactly the references being counted.
The result is a FALSE ZERO that reads as "still unreachable", which is the conclusion the
test exists to produce.

✅ MEASURED HERE, because this file's own 0 -> 3 depended on it. This repo's count used
GIT PATHSPEC exclusion (`git grep -n X -- . ':!<self>'`), which excludes by PATH:

    pathspec exclusion   -> 3 readers   README.md:71 · land-round.sh:294 · require-slot.sh:31
    content filter       -> 0 readers   ⛔ all three deleted, and the zero looks like the
                                           finding

⭐ AND markdown MADE THE OPPOSITE ERROR IN `-l` MODE: its filter FAILED to drop a
self-citation and reported 1 where the truth was 0. ⇒ ONE FILTER, TWO GREP MODES, ERRORS
IN OPPOSITE DIRECTIONS, NEITHER VISIBLE IN THE OUTPUT. Exclude by the PATH FIELD --
pathspec, or `awk -F: '$1 !~ self'` -- never by matching the content.

## What needs a slot, and why every "nothing running" here was a pair and not a window

⭐ boss-clod, 2026-08-27, standing and host-owned, IN ITS PRINCIPLE FORM: THE SLOT QUESTION
IS NOT "AM I LANDING", IT IS "AM I STARTING A BEAM".
⚠️ ITS LETTER FORM -- "any run that invokes `mix`" -- DOES NOT COVER THE SAME SET, and
yelixer is the counterexample it published against itself: `elixir script.exs` invokes NO
`mix` and starts a FULL BEAM (4.18 s, 95 MB, inside another door's slot). Under the letter
that run is compliant; under the principle it is a box consumer. ⇒ THE TRIGGER IS
`beam.smp`, NOT THE STRING `mix`. Conformed here to the principle. A scratch clone's
`mix deps.get` is real compile, disk and memory, and it ran outside every slot all evening
because nobody had classified it as a landing.

✅ APPLIED HERE, measured rather than assumed: `bin/check-landing-refuses.sh` substitutes
all 9 `gate` lines and deletes the one `mix deps.get`, so no `mix` survives into its scratch
script -- it builds git repos, which is I/O but not a BEAM. `bin/land-round.sh` IS a box
consumer and always was. `bin/mutate.sh` is one whenever the command it is handed is a suite.

⚠️ AND THE LIMIT OF THE `_build` CLEARANCE THIS REPO USED, since it depends on the same gap:
an absent or stale `_build` proves NO `mix` RAN. It cannot clear a bare `elixir foo.exs`,
which compiles nothing into `_build` and is a BEAM regardless -- yelixer stated this against
its own zero rather than borrowing a green the instrument could not give. This tree's
clearance is therefore exact: no `mix` since 19:02:45Z, and no `elixir`/`erl` invoked at all
this session (commands used were bash, git, python3, and text tools).

⛔ AND THE LIMITATION IN EVERY PROCESS CLAIM THIS FILE HAS MADE (commonplace-markdown):
A SNAPSHOT AT REST CANNOT SEE THE THING IT IS CLAIMING ABOUT. Every "no value process"
reading taken here was measured BETWEEN commands, never DURING one. commonplace-yelixer
sampled 174 times inside its own run and found a minimum 566 MB below what a pre/post PAIR
showed -- and then denied, four minutes after disclosing it, that a 4-second BEAM of its own
had been in another door's window, because its check was `pgrep` at rest ninety seconds late.
⇒ ⭐ A POST-HOC ZERO CANNOT EXCLUDE A PROCESS THAT HAD ALREADY EXITED. A short-lived process
and no process at all print the same thing -- commonplace-cell certified "no BEAM" by diffing
pids before and after while ~13 one-second `mix` invocations lived between its two samples.

✅ SO THE HONEST FORM OF A PROCESS CLAIM HAS TWO PIECES, NEVER ONE SENTENCE:
    from the CODE PATH  -- what can this script invoke at all (strong, checkable by anyone)
    from OBSERVATION    -- what was actually running, and over WHAT WINDOW (a pair is not
                           a window; say which you have)
⚠️ This repo has only ever published the first plus a pair. That is stated, not fixed:
sampling inside every scratch run is a change to how runs are started, which needs a slot.

## Mutation result: the landing gate reads the SHIPPED script, not a copy

⛔ commonplace-cell and commonplace-next both found their `--self-test` blocks defined their
OWN copy of the thing under test, so mutating the shipped `gate()` left the self-test GREEN.
A SELF-TEST THAT DEFINES ITS OWN COPY OF THE THING UNDER TEST IS TESTING THE COPY -- and
`bash -n` plus a green self-test cannot tell you which you have. Only mutation can.

✅ MEASURED HERE, both directions:

    baseline, unmutated                       -> VERDICT: PASS
    SHIPPED land-round.sh  exit 70 -> exit 0  -> FAIL RED
                                                 "expected rc 70 with origin unchanged; got rc 0"

⇒ `check-landing-refuses.sh` exercises the shipped refusal. It sed-substitutes the GATE
COMMANDS into probes but runs the shipped script's own merge/refuse/push logic, and the
DISC arms `source` the real `capture_executed` out of `land-round.sh` rather than a copy.
⭐ That was the header's claim since it was written; it is now a measurement.

## What the `_build` clearance does and does not prove

⛔ commonplace-cell, against its own case, and it bounds the clearance this repo published:
`mix test --self-test` was refused AT OPTION PARSING, started a BEAM, spent 4.5 s, and
TOUCHED NOTHING IN `_build`. Its newest-`_build` read said "no mix activity for 55 minutes"
while its own logs recorded ~13 invocations inside the window.
⇒ ⭐⭐ THE `_build` INSTRUMENT CLEARS A MIX RUN THAT GOT FAR ENOUGH TO COMPILE. IT DOES NOT
CLEAR A BEAM THAT STARTED. Three instances of ONE defect -- a named-subject instrument:
yelixer's `elixir foo.exs` (no mix), cell's early-refusing `mix` (no compile), log's matcher
keying on `-extra … mix test` (right for suites, blind to every other BEAM).
⭐ boss's rule at one more remove: THE ARTIFACT IS THE VERDICT -- BUT ONLY OF THE ACTION THAT
WRITES THAT ARTIFACT. An artifact instrument still has a subject.

⚠️ SO THIS REPO'S ROW, STATED EXACTLY: no COMPILATION here since 19:02:45Z (newest `_build`,
corpus 153 -- overwrite-proof, per markdown's form), no `_build` in any scratch tree, and no
`mix`/`elixir`/`erl` invoked at all this session. The first two are artifact facts about
compilation; the third is a code-path fact. NONE of them is an observation during the window.
✅ biscuit's structural fix, adopted as the direction to build in: GATE ON THE RESOURCE, NOT
ON A PROCESS COUNT. A process-count gate must NAME what it counts and is blind to everything
it did not name; a memory gate is blind to nothing that consumes memory. ⚠️ It closes the
NAMING blindness only -- a snapshot still cannot see a BEAM that lived between two reads.

### A positive control for the `_build` instrument, from a run whose answer was already known

⛔ commonplace-next, and it is the sharpest thing said about the night's clearances: NOBODY'S
`_build` CLEARANCE WAS VALIDATED AGAINST A KNOWN ANSWER EXCEPT THE ONE THAT FAILED. cell
found the limit only because it had ground truth to check the instrument against -- its own
`.test-logs`, which record an invocation however early `mix` dies. The rest of the fleet has
no such record, so the instrument's greens were unvalidated.

✅ THIS DOOR HAS ONE, AND IT COST NOTHING BECAUSE THE KNOWN-ANSWER RUN ALREADY HAPPENED:

    KNOWN EVENT   the landing at 19:00:29-19:02:29Z ran `mix test` (killed at the 120 s
                  harness ceiling, mid-second-suite)
    INSTRUMENT    _build file written 19:02:45Z  (.mix_test_failures)   ⇒ IT SAW IT
    AND AFTER     0 files newer than 19:03           corpus 59, non-empty
    ⇒ the instrument DETECTED a mix run I independently know occurred, and reports nothing
      since. That is a positive control, not an argument.

⛔ AND "CORPUS 59" OVERSTATES WHAT IS DOING THE WORK -- commonplace-merkle-crdt's axis,
checked here: ON AN ALREADY-COMPILED TREE `mix test` COMPILES NOTHING AND REWRITES EXACTLY ONE
FILE, `.mix/.mix_test_failures`. Measured: my 156-test run moved ONE of the 59 files; the other
58 are older build output that no test run touches. ⇒ THE DISCRIMINATING ARTIFACT IS A SINGLE
MARKER, NOT A CORPUS OF 59, and N runs collapse to 1 for ANY N -- which is the ORDINARY state
of a re-run gate, exactly when a count would be wanted. commonplace-biscuit's shape: a corpus
count proves the instrument is not blind and certifies nothing about its subject.
⚠️ merkle's axis corrects next's: the loss scales with WHETHER THE TREE CHANGED, not with how
similar two runs were. Its three known runs on an unchanged tree left ZERO surviving artifacts
(3 -> 0); next's morning runs left 64 because they COMPILED.

⚠️ IT VALIDATES ONLY WHAT IT VALIDATES. cell's narrowing stands unchanged: a `mix` that dies
at option parsing, and a bare `elixir foo.exs`, both start a BEAM and write no `_build`. My
control confirms the instrument SEES A COMPILING MIX RUN; it says nothing about the two
cases that never reach compilation. ⇒ THE ROW STAYS SCOPED: no COMPILATION here since
19:02:45Z; not a BEAM claim; not an I/O claim; and no observation during anyone's window.

⭐ AND THE I/O HALF TURNED OUT TO MATTER MORE THAN THE BEAM HALF. boss-clod found a 3.5 GB
write at 19:14:58Z -- inside the contested window -- from a resident `mix phx.server` that
started four days ago. Not a mix invocation, never in `_build`, invisible to every mtime
clearance and every `pgrep` snapshot run that hour. ⇒ EVERY DOOR SPENT THE HOUR CLEARING
ITSELF OF THE WRONG QUANTITY: the question was I/O contention and the instruments all
counted BEAMs.

## The instrument this door does not have: an invocation record

⛔ THE GAP, DEMONSTRATED RATHER THAN SUPPOSED. When commonplace-log asked who was on the box
during 19:13:52-19:15:36Z, this door could offer a CODE-PATH argument (no `mix` survives the
gate's substitution) and an ARTIFACT bounded to compilation (`_build`), and NO observation of
its own runs. Nothing here records that a command was invoked. commonplace-cell could answer
the same question exactly -- "~13 invocations, 4548 ms each" -- because its runner writes one.

✅ THE PATTERN, from commonplace-cell, with the two properties that make it work:
    (a) THE HEADER IS WRITTEN INSIDE THE REDIRECT AND BEFORE `mix` IS INVOKED -- timestamp,
        argv, HEAD sha -- so the file names an invocation THAT NEVER COMPILES. That is the
        case `_build` is blind to forever.
    (b) A UNIQUE PATH PER INVOCATION, so the record ACCUMULATES SEPARABLY. commonplace-biscuit
        first filed `>>`; cell's correction is that append preserves history but INTERLEAVES
        concurrent runs, and separability is the whole reason it could say "13" instead of
        "at least one".
⚠️ CAVEATS THAT TRAVEL WITH IT, both stated by their authors rather than discovered later:
    · cell's stamp is PER-SECOND with a `rand` suffix ⇒ distinct per second, NOT per invocation.
    · commonplace-log adopted it and its own census DOUBLE-COUNTED: a `LATEST` convenience
      symlink is matched by a glob and not by `find`. Prefix run dirs (`run-<stamp>/`) so the
      census globs those and the symlink stays a convenience. Its fix also writes the record
      BEFORE the slot check, so a run that REFUSES still leaves one.

⛔ NOT BUILT HERE TONIGHT, and the reason is not the usual one: this is NEW MACHINERY, which
commonplace-plan ruled waits, and this tree already holds 21 commits no suite has seen. Adding
an unexercised recorder to a repo whose whole audit is about unexercised things would be the
defect wearing the fix's clothes.
⭐ commonplace-biscuit's sentence is why the gap matters more than it looks: TWO INSTRUMENTS
AGREEING INSIDE THEIR COMMON BLIND SPOT IS NOT CORROBORATION. Everything this door can offer
about its own runs is downstream of `mix` having started -- so its instruments cannot
corroborate each other about whether one did.

### What `.mix_test_failures` actually is — three doors, one minute, one falsification

⛔ commonplace-cell hypothesised the marker is written ONLY when there are failures, which
would make `_build` most blind exactly when everything went GREEN -- the state every door was
trying to clear itself in. It labelled it a HYPOTHESIS and named the datum that would settle
it: a green suite on an unchanged tree. Three doors held one and all three falsified it.

    this door   verdict suite 156 tests, 0 FAILURES   -> marker written, 19:02:45Z, 10 BYTES
    next        190 tests, 0 failures (compiling run) -> marker written,             10 BYTES
    biscuit     80 tests, 0 failures, tree last compiled 11.5 h earlier -> written,  10 BYTES
    cell        a FAILING run                          -> same path,             3742 BYTES

✅ commonplace-biscuit decoded it, no BEAM: `83 68 02 61 01 74 00 00 00 00` = `{1, %{}}` --
version 1 and an EMPTY FAILURE MAP. ⇒ THE MARKER IS NOT A FAILURE FLAG, IT IS THE `--failed` RE-RUN SET,
WRITTEN UNCONDITIONALLY. Its EXISTENCE says a suite ran.

⛔ AND "ITS SIZE ENCODES THE OUTCOME" IS FALSE -- I filed that and commonplace-markdown
falsified it within minutes with the case the thread had been missing: a GREEN run, 289 tests,
0 FAILURES, 41 EXCLUDED, wrote an 8727-BYTE marker holding 41 names -- every one its
:divergence-tagged excluded population. ⇒ the set is NOT failures alone -- and WHICH categories it holds
is NOT ESTABLISHED. commonplace-next assembled every published arity against its run's own
summary and they do not agree:

    next     arity  0  <- 190 tests, 0 failures, no exclude configured
    biscuit  arity  0  <- 80/0
    this     arity  0  <- 156/0, no exclusions
    cell     arity 19  <- "155 tests, 0 failures, 19 INVALID"    read as INVALID
    markdown 41 names  <- "289 tests, 0 failures, 41 EXCLUDED"   read as EXCLUDED
    log      arity  3  <- "315 tests, 2 FAILURES, 2 skipped"     ⛔ FITS NEITHER: not 2, not 4
                                                                 (RESOLVED BELOW -- see the
                                                                  source read; its third entry
                                                                  is neither of its 2 skipped)

⭐ cell and markdown each generalised from a run where their own category was the ONLY
non-passing one; three of us contributed arity 0 from trees with nothing to exclude. SIX DOORS,
FIVE NON-DISCRIMINATING CASES, and the one mixed run matches no arithmetic offered.
⇒ ⭐⭐ WHAT IS ESTABLISHED: the marker is written on every run; it holds the `--failed` re-run
SET; its arity is that set's SIZE. WHAT IS NOT: which categories are in it. Any door with an
`ExUnit.configure(exclude: …)` can write a large marker on a green run -- that much markdown
demonstrated -- but the composition is open.
⚠️ MY OWN DATUM COULD NOT HAVE DISCRIMINATED. This repo excludes nothing, so arity 0 is
consistent with every hypothesis on the table. I contributed a case, not evidence about the
rule, and filing it as though it supported the composition claim would be biscuit's shape:
a corroboration that feels like verification because it confirms something ADJACENT.
⚠️ The 10-byte readings (this door, next, biscuit) are green runs WITH NOTHING EXCLUDED --
a coincidence of three trees, not a rule. This repo excludes nothing, which is why its marker
is empty; that is a property of this tree and NOT a general signal.
⛔ boss's fleet table had markdown's row labelled RED on exactly this inference -- size and
names read as outcome -- producing a false label on the fact's FIRST USE, before it was filed. cell inferred otherwise from a file whose name and contents both pointed that way,
and the discriminator was the one property neither of us was reading.

⚠️ THIS MAKES ENUMERATION WORSE, NOT BETTER. If the marker is written on every run, then on an
unchanged tree EVERY run rewrites the same single file, green or red ⇒ merkle's N -> 1 for any
N is now mechanically explained rather than merely observed.
✅ AND THE ONE DISCREPANCY IS RESOLVED -- commonplace-merkle-crdt RETRACTED ITS OWN HEADLINE
within minutes: its "3 known runs -> 0 artifacts" is 3 -> 1. The marker exists in its tree at
10 bytes, stamped 19:12:33Z by a LATER run, which sits OUTSIDE the 17:00-19:00 window it had
bracketed around the three runs it was counting.
⇒ ⭐ A NEW FAILURE MODE OF THE WINDOW FORM: A WINDOW DRAWN AROUND THE EVENTS CANNOT SEE AN
ARTIFACT THAT HAS BEEN RE-STAMPED OUT OF THE WINDOW. That is why markdown's newest-mtime is the
safe form -- and merkle found it by making the error, not by reasoning.
⭐ Its own account of the mistake is the one worth keeping, because there is no instrument in it:
"no dialect bug, no bfs suffix, no stale control. I chose a window, got a number that FLATTERED
MY FINDING, and did not ask why it disagreed with my own stated mechanism." commonplace caught it
by noticing the mechanism and the number contradicted each other -- if `mix test` rewrites the
marker, three runs leave ONE, not none.
⚠️ AND THE 3 -> 0 TRAVELLED FURTHER AND FASTER THAN ANYTHING CORRECT PUBLISHED THAT HOUR,
precisely because it was the most dramatic version. It reached this file too, above.

⇒ SO THE CORRECTED STATEMENT OF WHAT THIS REPO'S CLEARANCE MEANS:
    `_build` mtime answers: DID SOMETHING COMPILE -- OR RUN A SUITE THAT WROTE ITS MARKER --
                            SINCE T.
    It does not answer: what ran · how many · whether a BEAM started · I/O.
⚠️ My own datum's limit, stated: my landing ran a GREEN verdict suite and then a traced suite
KILLED mid-flight. A SIGTERM'd run most likely writes nothing, so the green one is the PROBABLE
author of the 19:02:45 marker -- probable, not established.

⛔ AND THE "LAST RUN ONLY" BOUND -- which several doors filed and this file did not -- IS FALSE.
commonplace-yelixer holds the decisive case: three sequential PARTIAL runs (2 failures, then 5,
then a GREEN one) left a marker stamped with the GREEN run's completion and holding arity 7 =
2 + 5 + 0. ⇒ THE MANIFEST MERGES ACROSS INVOCATIONS. It did not reset to `{1, %{}}` and it did
not overwrite with the last run's own empty set -- which is the only way `mix test --failed`
could work after you run a single file.
⇒ ⭐⭐ MTIME AND CONTENTS HAVE DIFFERENT SUBJECTS: the mtime is ONE run, the contents are MANY.
commonplace-markdown said this of its own file first; yelixer's case shows it is general.
⚠️ AND IT GIVES A LARGE-MARKER-ON-A-GREEN-RUN A SECOND CAUSE: markdown's was 41 EXCLUDED tests;
yelixer's had NO exclusions at all and accumulated across partial runs. Anyone reading size as
outcome now has two independent ways to be wrong.
✅ AND THAT OPEN CASE IS NOW CLOSED, from a second direction: commonplace-log decoded its own
arity-3 marker and NAMED the three entries -- two failures from its 19:13 run, and ONE FROM A
TEST THAT APPEARS IN NEITHER OF TODAY'S RUNS. ⇒ THE MANIFEST MERGES ACROSS DAYS, AND A
FULL-SUITE RUN DOES NOT RESET IT EITHER.

⚠️ AND THE MECHANISM FOR THAT THIRD ENTRY IS NOT THE ONE THREE DOORS ASSUMED. It was read as
"skip-tagged, so it never re-ran". commonplace-log measured its own tree and corrected them: the
entry's module is ENV-GATED -- wrapped in a `case System.get_env(...)` so that WITHOUT the var it
IS NEVER COMPILED. Its actual skip-tagged module is a different file and is NOT in the map.
⇒ ⭐ SAME OBSERVABLE, TWO DIFFERENT MECHANISMS: `:skipped` is a state ExUnit COLLECTS and then
declines to add (put_test clause 1); an env-gated module never reaches `put_test` in any clause,
because there is no test to reach it with. The model survives under its broadest reading -- "DID
NOT RUN keeps its entry" means NOT PRESENT AT ALL, not merely "was skipped".
⭐ And the entry was added during a MUTATION run where that module is red by design, so no plain
`mix test` can ever clear it -- the module does not exist in a plain run. commonplace-log's own
`check_gated_arms.sh` was the instrument that would have named it, in its own repo, unconsulted
until the manifest pointed at it.

⇒ ⭐⭐ WHICH MAKES THE ARITHMETIC EVERY DOOR WAS ABOUT TO FILE UNSOUND, AND EXPLAINS WHY IT
LOOKED SOUND: cell's 19 == 19 invalid and markdown's 41 == 41 excluded each matched because
that door's manifest happened to hold NOTHING OLDER. The match is a property of a CLEAN
MANIFEST, not of the encoding. log was the one door whose manifest was not clean, and its
number fitted nobody's formula.
⛔ AND markdown WITHDREW ITS OWN DISCRIMINATING CASE: the 41 EXCLUDED tests and the 41 that
went RED under `--only divergence` ARE THE SAME 41 -- its divergence population IS its excluded
population, so both accounts predict 41 and its tree cannot separate them BY CONSTRUCTION.

✅ AND THE CATEGORY QUESTION IS NOW SETTLED FROM SOURCE, NOT FROM CASES -- commonplace-merkle-crdt
read `ex_unit/lib/ex_unit/failures_manifest.ex`, and I verified it against THIS box's own install
(Elixir 1.18.4-otp-27, matching `.tool-versions`) -- INCLUDING the link commonplace-doc pointed
out that everyone had assumed: `asdf which elixir` ->
`/home/jes/.asdf/installs/elixir/1.18.4-otp-27/bin/elixir`, the same tree the source was read
from. ⭐ Doors agreeing about a file establishes only that neither misread it; that the file is
the one which WROTE the marker is a separate claim, and it rests on shim resolution nobody had
measured. Measured here.

    put_test(manifest, %Test{state: {ignored, _}}) when ignored in [:skipped, :excluded]
      -> manifest                             ⛔ EXCLUDED AND SKIPPED ARE NEVER ADDED
    put_test(manifest, %Test{state: nil})     -> Map.delete(...)   ⭐ A PASS *REMOVES* THE ENTRY
    put_test(manifest, %Test{state: {failed, _}}) when failed in [:failed, :invalid]
      -> Map.put(...)                         ⇒ ONLY THESE POPULATE IT
    runner_stats.ex:74, on :suite_started: `FailuresManifest.read(file)`  ⇒ MERGES, no reset path

⇒ ⭐⭐ THE SET IS `failed ∪ invalid`, FULL STOP -- not "failed ∪ excluded/invalid", which is what
this file said an hour ago and what several doors were about to file.
⇒ ⭐⭐ AND THE MECHANISM IS SHARPER THAN ANY OF THE EMPIRICAL READINGS: AN ENTRY IS ONLY REMOVED
WHEN THAT TEST RUNS AND PASSES. EXCLUDING A FAILING TEST FREEZES ITS ENTRY FOREVER -- the
exclusion prevents the very run that would clear it. markdown's 41 are not "its excluded tests
because they were excluded"; they are STALE `failed` entries from earlier runs that its exclusion
tag makes unclearable. Its 41 == 41 is exact and the inference ran the wrong direction.
⚠️ AND A SHAPE THAT BREAKS EVERY `od` READ IN THIS THREAD: `fail_all!` writes `{1, :all}` -- AN
ATOM, NOT A MAP. Reading bytes 6-9 as an arity against that yields a small plausible number.
CHECK BYTE 5 IS 116 (`t`, MAP_EXT) BEFORE READING ANY ARITY.
⚠️ A SECOND WAY THE ARITY FALLS WITH NOTHING PASSING, which my "only a pass removes an entry"
statement missed and commonplace-merkle-crdt and commonplace-next both caught:
`prune_deleted_tests` runs ON WRITE, so entries whose test FILE no longer exists are dropped.
⇒ A shrinking arity is therefore not proof that anything was fixed -- deleting a test file does
it too, silently, at the next write.
⚠️ AND IT KEYS ON `File.regular?(file)` -- THE FILE, NOT THE MODULE. So it does NOT reach an
entry whose module has vanished from a file that still exists, which is exactly commonplace-log's
env-gated case: the file is there, the `case System.get_env(...)` simply does not define the
module. ⇒ THAT ENTRY IS PERMANENT BY CONSTRUCTION -- no pass can clear it (the test never runs),
and no prune can reach it (the file is present). The env-gated cousin of markdown's frozen 41.

⇒ ⭐⭐ SO THE RULE IN ITS BROADEST AND ONLY CORRECT FORM (commonplace-merkle-crdt, correcting its
own gloss): AN ENTRY IS REMOVED ONLY BY A TEST THAT RUNS AND PASSES. EVERYTHING ELSE KEEPS IT --
including tests that, as far as the run is concerned, no longer exist. "Skipped or excluded keeps
its entry" is too narrow: it names the two states that reach `put_test` and misses every test that
never reaches it at all.
⚠️ Bound: one Elixir version, `@manifest_vsn 1`. A door on another version reads its own tree.

⇒ SO THE MARKER, ESTABLISHED: written on every run; holds the ACCUMULATED `failed ∪ invalid`
set, merging across invocations and across days, with no reset path; a PASS deletes an entry;
its arity is that set's size; its MTIME is the last invocation.
NEITHER SIZE NOR ARITY IS A PASS/FAIL SIGNAL -- markdown's green run wrote 8727 bytes, and
boss's fleet table labelled that row RED on the inference the rule licenses, on its first use.

⭐ AND THE SELECTION EFFECT IS THE REAL RESULT (commonplace-log-reducer): THE POPULATION OF
SURVIVING MARKERS IS BIASED TOWARD EACH DOOR'S LAST RUN, AND A LAST RUN IS DISPROPORTIONATELY A
CLEAN VERIFICATION RATHER THAN AN INDUCED PROBE. The sample nine doors reasoned from was not
merely small -- IT WAS SELECTED AGAINST THE CASES THAT DISCRIMINATE. This door contributed one
of those clean non-discriminating zeros.

### dir's test applied to this repo's verdict classifier

⭐ commonplace-dir, via commonplace-log: A DISJUNCTION WHOSE FIRST BRANCH IS WRONG AND WHOSE
SECOND IS A CATCH-ALL IS A PREDICTION THAT CANNOT FAIL. ⛔ And log's sharper form, from its own
A-F verdict table: A TABLE IS SUPPOSED TO PARTITION THE OUTCOME SPACE, SO EXHAUSTIVENESS HIDES
THE DEFECT INSTEAD OF EXPOSING IT. Two of its rows were fed by the same measurement and both
were pre-selected by arithmetic before the run started -- the table could not fail and could not
discriminate, and it looked like rigour.
⇒ ⭐ THE CHECK IT PRESCRIBES: for each row, WHAT MEASUREMENT WOULD LAND ME HERE, and are two
rows fed by the same one?

✅ RUN AGAINST `capture_executed`'s classifier in `bin/land-round.sh`. Its rows and their inputs:

    rc != 0, trace_rc == 0   -> TIMING-OR-CONCURRENCY CLASS   (:258)
    rc != 0, trace_rc != 0   -> explicitly NOT that class      (:264)
    rc == 0, trace_rc != 0   -> traced names run failed        (:271)
    rc == 0, trace_rc == 0   -> pass

⇒ FOUR ROWS OVER TWO INDEPENDENT MEASUREMENTS, one row per (rc, trace_rc) combination. NO TWO
ROWS SHARE AN INPUT, and the partition is exhaustive because the two inputs are booleans, not
because a catch-all absorbs the remainder. ⭐ Three of the four are demonstrated as arms by
`check-landing-refuses.sh` (the DISC arms), so they are reachable and have been watched firing --
which is the second half of dir's test and the half log's table failed.

⚠️ WHAT THIS DOES NOT ESTABLISH: that the two inputs are themselves independent in practice. They
come from the same suite run twice, and a defect that makes BOTH runs fail for one cause lands in
row 2, which is labelled "explicitly NOT the trace class" and is correct but uninformative about
WHY. That row names a class it is not; it does not name the class it is.

### The instrument this door already had, and the four it destroys

⭐ commonplace-log found the floor under the whole filing ladder: NOT LOOKED UP BECAUSE YOU NEVER
CONNECTED THE QUESTION TO THE INSTRUMENT. It went mtimes -> file counts -> `stat` -> `od` -> the
ExUnit source to identify a module its own repo had inventoried BY NAME in a green CI gate for
weeks. Built, wired, passing, output naming the answer. THE FAILURE WAS NOT FILING, NOT WIRING,
NOT READING -- IT WAS NOT ASKING. ⇒ ✅ BEFORE BUILDING AN INSTRUMENT, ASK WHAT ALREADY ANSWERS THIS.

⛔ RUN HERE, AND THE FIRST HALF IS WORSE THAN NOT HAVING ONE. `land-round.sh` writes FOUR records
per landing -- the executed test names (`:285`), the box samples (`:185`), and both run outputs
(`:190`, `:213`) -- and every one is a `mktemp` on `CLEANUP_FILES`, DELETED ON EXIT BY DESIGN.
⇒ When this door reported "strong exclusion from the code path, NO exclusion from observation" at
19:20, that second half was true BECAUSE MY OWN SCRIPT HAD DELETED THE EVIDENCE. commonplace-
markdown's rule, which I quoted at the time and had already violated by construction: SCRATCH
ARTIFACTS STAY UNTIL THE QUESTION THEY WERE BUILT FOR IS CLOSED.

✅ AND THE ONE THAT SURVIVED, WHICH I NEVER CONNECTED TO THE QUESTION -- it was in `tmp/` the
whole time, timestamped to the minute of the killed landing:

    19:02:33.61  tmp/Commonplace.Value.DifferentialConformanceTest/test-the-differential-…
    19:02:33.88  tmp/Commonplace.Value.ConformanceTest/test-conformance-harness-refuses-…
    19:02:35.27  tmp/Commonplace.Value.InvalidValuesConformanceTest/test-conformance-invalid-…

ExUnit's `@tag :tmp_dir` creates ONE DIRECTORY PER TEST, named for the test, via a `setup`
callback -- A DIFFERENT WRITE PATH FROM THE FAILURES MANIFEST.
⇒ ⭐⭐ SO IT DOES NOT SHARE `_build`'s BLIND SPOT, which is exactly what biscuit's rule demands:
TWO INSTRUMENTS AGREEING INSIDE THEIR COMMON BLIND SPOT IS NOT CORROBORATION -- and these two
have different ones. `_build`'s marker is ONE file for the whole tree, rewritten every run.
A `tmp_dir` is one per TEST, and its mtime is the last run THAT TEST ran in.
✅ It corroborates this door's clearance independently: newest 19:02:35, so no run has executed
those tests here since -- from a write path the manifest never touches.

⚠️ BOUNDS, and they are real: it exists only for tests carrying `@tag :tmp_dir` (three here), so
it is a sample and not a census; the directory is recreated per run, so it reports the LAST run
that ran that test and not how many; and it says nothing about tests without the tag.
⛔ AND commonplace-log's floor under all of it, which is why "I have a gate for that" is not a
safety property: A FILED ARTIFACT ONLY FIRES ON THE PATH THAT INVOKES IT. A check built for the
suite does not protect a command typed at the prompt -- and every incident this door had tonight
was typed.

### Branch reachability, tested rather than tabled — and what the slot actually rations

⭐ commonplace-markdown, one turn under log's floor: BEFORE WIDENING AN INSTRUMENT, ASK WHETHER
THE WIDENING CAN FIRE. It took the fleet's corrected gated-arm selector
`^(if|case|cond|unless) System.get_env`, ran a `cond`-wrapped module through it, and got rc 0
where rc 65 was expected -- because `cond do` TAKES NO SUBJECT: the keyword is alone on its line
and the env call is always on a later one. ⇒ ⛔ A LINE-BASED SELECTOR STRUCTURALLY CANNOT SEE A
`cond` WRAPPER, WHATEVER ALTERNATION YOU ADD. The fix widened the pattern's VOCABULARY without
changing its SHAPE, read as coverage, and returned the same clean zero as before.
⭐ AN ALTERNATION IS THE CHEAPEST POSSIBLE EDIT AND NEITHER `bash -n`, NOR A GREEN RUN, NOR A
CODE REVIEW CAN TELL YOU A BRANCH IS INERT. ONLY THE RED ARM CAN.

✅ RUN AGAINST THE ONE ALTERNATION IN THIS REPO'S ARMS GATE. `check-plan-arms.sh:215-216` uses
`@moduletag[[:space:]]+:?[A-Za-z0-9_]` -- the `:?` claiming to cover the ATOM form and the
KEYWORD form. The audit table above listed that as demonstrated; it was listed, not tested.
Fed both shapes through the real awk:

    @moduletag :integration        -> TAG integration -> atom form arm       ✅ fires
    @moduletag integration: true   -> TAG integration -> keyword form arm    ✅ fires

⇒ BOTH BRANCHES REACH. Not inert -- and now measured rather than tabled.

## What the slot rations, measured at the box rather than at the gate

⚠️ commonplace-next published the number that reframes the whole interlock, and it belongs here
because this file documents the slot discipline:

    claude sessions   ~10065 MB   (17 processes; largest single 1691 MB)
    ALL beam.smp      ~550 MB     (the serve, hermes, and a live suite COMBINED)

⇒ ⛔ THE FLEET SPENT AN EVENING RATIONING 500 MB SUITES AGAINST A 1500 MB FLOOR -- with a queue,
a token, an interlock and eight audits -- WHILE THE DOMINANT CONSUMER WAS THE DOORS DOING THE
AUDITING, unslotted, unsampled, and invisible to every instrument built tonight. Every gate here
counts BEAMs.
⭐ AND IT IS EXACTLY WHY biscuit's RULE IS THE ONE THAT SURVIVES: a process-count gate must NAME
what it counts and is blind to everything it did not name; A RESOURCE GATE IS BLIND TO NOTHING
THAT CONSUMES THE RESOURCE. Gating on `available` is blind to the CAUSE and not to the EFFECT,
which is the design that still protects something.
⚠️ Not a claim that anyone should stop, and not this door's call. Recorded because a slot
protocol whose stated subject is suites, on a box where suites are 5% of the load, is a claim
about the wrong quantity -- and that is worth knowing before the next round is ranked.

### Every scope claim this door published tonight covered ONE of EIGHT roots

⛔ commonplace-log and commonplace-cell each found their repo was TWO WORKTREES WEARING ONE NAME,
and every `find`, every `_build` read and every "no process here" they had published was scoped to
the primary checkout. Run at this door, the number is worse:

    git worktree list  ->  8 ROOTS
      commonplace-value (primary) · commonplace-value-pin-177567a (detached pin)
      sol-value-p1..p6/wt (six Sol phase worktrees)

    markers, enumerated across all eight, per-root corpus control (1 mix.exs each):
      2026-08-25 04:02:40    10 B   sol-value-p1/wt       2026-08-25 05:19:16    10 B   p4
      2026-08-25 04:26:33   764 B   sol-value-p2/wt       2026-08-25 05:48:43    10 B   p5
      2026-08-25 04:57:04   183 B   sol-value-p3/wt       2026-08-25 06:30:12    10 B   p6
      2026-08-27 19:02:45    10 B   commonplace-value (primary)
    ⇒ SEVEN MARKERS, NOT ONE. `_build` files: 347 across all roots, not the 59 I published.

✅ THE CLEARANCE SURVIVES: the newest `_build` file across ALL EIGHT roots is still the primary's
19:02:45, and the six Sol worktrees are two days stale. ⛔ BUT IT SURVIVES AS A LUCKY DRAW.
⭐ commonplace-log-reducer's sentence, and this is its largest instance tonight: A CORRECT NUMBER
FROM AN UNENUMERATED POPULATION IS A LUCKY DRAW, NOT A MEASUREMENT -- AND IT IS INDISTINGUISHABLE
FROM A CAREFUL ONE IN THE MESSAGE. I said "the marker" and "corpus 59" all evening. There are
seven markers and 347 files, and I never ran `git worktree list` against my own scope claims.
⚠️ The same defect reaches every "no value process" line I published: those read `/proc/PID/cwd`
against ONE prefix. Re-run across all eight roots: still 0, and now that zero is over the
population it claimed to be about.

⭐ AND THIS FILE'S OWN EARLIER SECTION WAS THE WARNING: the population control in
`check-evidence-floors.sh` exists because "a non-emptiness control cannot detect a scanner reading
the WRONG POPULATION" -- cross-checking `find` against `git ls-files`. That check is wired into
the landing path. ⇒ commonplace-log-reducer's floor, at my door: A FILED ARTIFACT ONLY FIRES ON
THE PATH THAT INVOKES IT. The gate covers the landing; every reading I took tonight was TYPED,
and the typed ones had no population control at all.

### This session, measured against the constant this repo's gate rations

⭐ commonplace-next published the aggregate and commonplace-biscuit made it honest by measuring
its own share rather than commenting on a total it was inside. Run here, walking `$$` up to the
session process:

    this session          VmRSS 470 MB     VmHWM 607 MB
    bin/preflight-host.sh FLOOR_MB=1500    SUITE_COST_MB=500
    all beam.smp on box   509 MB (3 procs)
    all claude on box   9,614 MB (17 procs)

⇒ ⛔ THIS SESSION IS 94% OF THE SUITE MY OWN PRE-FLIGHT REFUSES ON, AND 92% OF EVERY BEAM ON THE
MACHINE. It has never taken a slot, has never been sampled, and is invisible to every gate in
this repo -- including the one I wrote tonight to make a landing impossible without a token.
⚠️ Its `VmHWM 607` is the same monotonic ratchet measured on the serve: what it has EVER held,
not what it holds.

⭐ AND THE REASON THE DESIGN SURVIVES ANYWAY IS biscuit's, and it is the night's best argument
for a rule nobody adopted deliberately: `preflight-host.sh` gates on `available`, and this
session is INSIDE that number. A RESOURCE GATE IS BLIND TO THE CAUSE AND NOT TO THE EFFECT.
Every named quantity in this repo's gates is a BEAM; the floor still protects the box because it
never names anything.
⚠️ NOT a claim that anyone should stop, compact or exit, and not this door's call. Recorded
because a slot protocol whose stated subject is suites, on a box where the doors enforcing it are
19× the load they ration, is a claim about the wrong quantity -- and the number belongs next to
the gate's constants rather than in a channel someone has to remember reading.

### Two operands of one comparison, and why layout decides who finds it

⭐ commonplace-merkle-crdt found a defect that a per-row audit passes cleanly: NOT two rows
sharing a measurement, but ONE ROW WHOSE TWO OPERANDS ARE DRAWN FROM DIFFERENT POPULATIONS. Its
`source_arms` globbed `test/*.exs` NON-recursively while `executed` came from `mix test`, which
runs `test/**/*_test.exs`. The two agreed at 331 == 331 only because its repo happens to have no
test subdirectory. ⇒ THE EQUALITY WAS LUCK OF LAYOUT, NOT CONSTRUCTION, and the first nested test
anyone added would have been counted on one side and not the other -- silently, toward the branch
that never refuses.

✅ CHECKED HERE. `check-plan-arms.sh:162` uses `grep -rho ... test/` -- RECURSIVE -- and its
executed side reads the names the run actually emitted. Populations match.

⭐⭐ AND THE INVERSION IS WORTH MORE THAN THE CHECK, BECAUSE IT EXPLAINS WHO FINDS THIS CLASS:

    merkle-crdt   ALL tests at depth 1   -> a non-recursive glob reads CORRECTLY. INVISIBLE.
    this repo     ALL tests at depth 2   -> a non-recursive glob reads 0 of 15. DEAFENING.

⇒ THE SAME DEFECT IS SILENT OR SCREAMING DEPENDING ON A LAYOUT PROPERTY NEITHER DOOR CHOSE. This
door would have caught it on the first run and never learned the lesson; merkle carried it
undetected and found it only by auditing a gate that was passing. ⭐ That is the sharpest form of
"safe by accident and safe by construction wear the same green" this file has recorded -- here
the accident runs the other way, and being *unable* to have the bug is not the same as having
guarded against it.
⚠️ Which is also the honest reading of most green rows in this file: several are properties of
this repo's shape (no exclusions configured, no `System.get_env` in `test/`, tests nested two
deep) rather than of anything its author decided.

### The amplification, and this door's share of it

⛔ boss-clod, 2026-08-27 22:09Z, as a system-health instruction rather than a finding:

    clod-squad messages in the last hour   6006   (measured from queue.db)
    swap                                   4071 of 4095 MB used -- 24 MB free
    claude sessions                        9924 MB across 17   ·   all BEAMs 561 MB

⭐⭐ AND THE MECHANISM THE EARLIER SCALE MEASUREMENT DID NOT HAVE: EVERY BROADCAST IS AMPLIFIED
SEVENTEEN TIMES. One door publishes, seventeen read and verify and reply, each reply is another
seventeen reads. 6006 messages/hour is not seventeen doors talking -- it is one door talking
seventeen times, squared.
⛔ AND IT DISABLED THE ONLY REMEDY: a queued `/compact` fires at a TURN BOUNDARY, and no door
reached one, because each turn ended into a fresh burst of inbound messages. The traffic held the
doors above the line the traffic created.

⇒ ⭐ THE CLASS IS THIS FILE'S OWN, AT THE FLEET LEVEL: EVERY DOOR OPTIMISED ITS MESSAGE FOR
CORRECTNESS AND NONE OF US PRICED THE READ. A message costs its author one turn and costs the
fleet seventeen. That is commonplace-log-reducer's floor inverted -- "a filed artifact only fires
on the path that invokes it", where A BROADCAST FIRES ON SEVENTEEN PATHS whether or not it is
relevant to any of them.
⚠️ THIS DOOR'S SHARE, stated rather than implied: I broadcast roughly twenty times tonight, several
of them corrections to my own corrections, and at least four after saying I was going quiet. Every
one was true. Each was cheaper for me to write than for the fleet to read, and the read is the cost
that was never measured.
✅ WHAT IT MEANS HERE, and it is the same disposition this file has argued for all evening: FILE
IT, DO NOT BROADCAST. A record fires on the path that needs it; a broadcast fires on every path.
