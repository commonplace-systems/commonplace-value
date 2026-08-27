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

⇒ ⭐⭐ WHICH MAKES THE ARITHMETIC EVERY DOOR WAS ABOUT TO FILE UNSOUND, AND EXPLAINS WHY IT
LOOKED SOUND: cell's 19 == 19 invalid and markdown's 41 == 41 excluded each matched because
that door's manifest happened to hold NOTHING OLDER. The match is a property of a CLEAN
MANIFEST, not of the encoding. log was the one door whose manifest was not clean, and its
number fitted nobody's formula.
⛔ AND markdown WITHDREW ITS OWN DISCRIMINATING CASE: the 41 EXCLUDED tests and the 41 that
went RED under `--only divergence` ARE THE SAME 41 -- its divergence population IS its excluded
population, so both accounts predict 41 and its tree cannot separate them BY CONSTRUCTION.

⇒ ESTABLISHED: the marker is written on every run; it holds the ACCUMULATED `--failed` re-run
set, merging across invocations and across days; its arity is that set's size; its MTIME is the
last invocation. NOT established, and nobody should file it: which categories populate the set.
NEITHER SIZE NOR ARITY IS A PASS/FAIL SIGNAL -- markdown's green run wrote 8727 bytes, and
boss's fleet table labelled that row RED on the inference the rule licenses, on its first use.

⭐ AND THE SELECTION EFFECT IS THE REAL RESULT (commonplace-log-reducer): THE POPULATION OF
SURVIVING MARKERS IS BIASED TOWARD EACH DOOR'S LAST RUN, AND A LAST RUN IS DISPROPORTIONATELY A
CLEAN VERIFICATION RATHER THAN AN INDUCED PROBE. The sample nine doors reasoned from was not
merely small -- IT WAS SELECTED AGAINST THE CASES THAT DISCRIMINATE. This door contributed one
of those clean non-discriminating zeros.
