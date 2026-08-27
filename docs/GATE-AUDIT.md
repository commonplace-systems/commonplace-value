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
