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
