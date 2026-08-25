# STATE — commonplace-value

Owner: the Opus toplevel in tmux window `commonplace-value`.
Implementers: Sol, one round per tmux pane (ruling #25).

---

## 0. What this package is

`docs/proposals/2026-08-24-commonplace-value-spec.md` — jes's spec, 643 lines, committed
byte-identical at `aac51f9`, sha256 `1ac9a437…`. **It is never edited.** Amendments go in
`docs/spec-errata.md`.

`docs/proposals/2026-08-25-value-composition-ruling.md` — jes's accepted design correction, 371
lines, sha256 `b0cc25b4…`, filed at `83d5227`. ⭐ **Also never edited, and also pinned by
`bin/check-spec-pristine.sh`** (both arms demonstrated). It adds `compose/2`, keeps `new/2` strict,
and corrects the Cell-versus-Realm boundary claim — see errata **V6**.

Its central guarantee, quoted: *a successfully constructed `Commonplace.Value` is inert,
JSON-equivalent data with one deterministic RFC 8785 canonical byte representation.*

⭐ **The conformance corpus is the product, not the decoration.** A value that passes every
structural check and encodes to different bytes on two machines is the exact defect this package
exists to prevent — and structural checks cannot see it.

---

## 1. ⛔ THE CLAIM DISCIPLINE, adopted before the first line of code

Adopted from `commonplace-doc-sync`'s HANDOFF §3 while it is still free.

> - **`docs/proposals/*` and `docs/spec-errata.md` state DESIGN claims only.**
> - ⛔ **A statement about what the CODE does MUST cite a test by name**, or it does not belong in
>   those files.
> - ⚠️ **Nothing in this repo may say "implemented" without naming the arm that would go red.**

**Filed, not remembered.** The carrier is `bin/check-plan-arms.sh`:

| marker (an HTML comment holding the keyword and a value) | meaning | gate behaviour |
| --- | --- | --- |
| `ARM:` + the exact test-name substring | a claim about LANDED code | **FAILS** if no `test "…"` matches |
| `ARM-PLANNED:` + the exact test name | a contract on a FUTURE round | reported, does **not** fail |
| `MODULE:` + `Full.Module.Name` | this module is declared in a plan | **FAILS** on any undeclared module in `lib/` |

⛔ **This table deliberately does NOT spell the markers out.** The gate greps `docs/` for the literal
comment syntax, so **prose describing a marker becomes a marker** — on its first run this file
contributed a phantom arm named `exact test name substring` and the gate went red on correct state.
⭐ **Documentation about a gate is inside that gate's corpus.** Spell markers only in plans, where
they are meant.

⚠️ **Two files in this repo DO spell the literal markers and are safe only because they sit OUTSIDE
the corpus** — `bin/check-plan-arms.sh` itself (its `--self-test` builds a fixture corpus) and any
`prompt.txt` in a round directory. The gate greps `docs/` and nothing else. ⛔ **Widening it to the
repo root would make the gate poison itself with its own self-test tokens.** "Outside the corpus" is
the only thing keeping those two files harmless, and it is not visible from either file.

**Counted, not assumed** (2026-08-25, bootstrap): 1268 doc lines · **1** literal `ARM` marker (the
bootstrap arm, and it has a test) · 32 `ARM-PLANNED` · 4 `MODULE` · **0 phantoms**.

⭐ **The `ARM:` marker IS the code claim.** A round's first done-step is to promote its
`ARM-PLANNED` markers to `ARM`, which turns the worktree's gate **red with N missing**. The round is
done when it is green *because the tests exist under those names*.

⭐ **`MODULE:` exists because an enumeration is satisfiable by anything not on the list.** Two sibling
repos found unbriefed Sol machinery within an hour. "Out of scope: A, B, C" is a denylist; "every
module in `lib/` is declared in a plan" is a property.

---

## 2. Gates in this repo, and the state each has been SEEN in

⭐ **A gate never seen fail is not known to work; one that fires on correct state is worse than no
gate.** Every row below must have both arms demonstrated before it is trusted.

| gate | green demonstrated | red demonstrated |
| --- | --- | --- |
| `check-spec-pristine.sh` | ✅ `VERDICT: PRISTINE` on the committed spec | ✅ `bin/mutate.sh docs/proposals/…spec.md '1a\INJECTED' -- bash bin/check-spec-pristine.sh` → `VERDICT: CHANGED`, rc=1, file restored |
| `check-plan-arms.sh` — missing arm | ✅ `VERDICT: PASS -- every declared arm exists.` | ✅ promoted one `ARM-PLANNED` with no test → `MISSING pointer for the top level value is the empty string`, rc=1 |
| `check-plan-arms.sh` — undeclared module | ✅ same run, `undeclared modules: 0` | ✅ dropped `Commonplace.Value.Sneaky` into `lib/` → `VERDICT: FAIL -- 0 declared arm(s) with no test, 1 undeclared module(s).` |
| `check-plan-arms.sh --self-test` | ✅ `SELF-TEST PASS` | ✅ built in — it *is* the red demonstration |
| `land-round.sh` refuses off main | ✅ landed the bootstrap from `main` → `LANDED: origin/main 711aaba` | ✅ run from `bootstrap-p1` → `REFUSED: on 'bootstrap-p1', not main.`, rc=64 |
| `land-round.sh` refuses on a failing gate | ✅ `LANDED: origin/main 8d58e97 contains adopt-gate-rc-capture` | ✅ throwaway branch carrying a phantom arm → `REFUSED: check-plan-arms failed (rc=1); not pushing.`, rc=70, **`origin/main` verified unchanged at 8d58e97** |

⭐ **The arms gate went red once on CORRECT state before any of that**, and it is the failure worth
recording: this very file described the marker syntax in prose, the gate greps `docs/` for that
syntax, and so the documentation *became* a phantom arm named `exact test name substring`.
⚠️ **A gate that fires on correct state is worse than no gate** — fixed by never spelling a marker
outside a plan (§1).

### 2.1 ⛔ `pipefail` WAS the only thing making the landing script's gates real — MEASURED, then fixed

⚠️ **Superseded as of `8d58e97`, and kept because the measurement is the reason the fix exists.**
`bin/land-round.sh` no longer pipes gates into `tail`: a `gate()` function captures each gate's exit
status (`out=$("$@" 2>&1) || rc=$?`) and refuses the push with `exit 70`. ⭐ **`|| rc=$?` on the
assignment line is load-bearing** — under `set -e` a failing *assignment* exits before a following
`rc=$?` ever runs, which fails **silently**: no verdict, no refusal, nothing pushed and nothing said.
*(Found by `commonplace-doc` while demonstrating their fix; adopted here verbatim.)*

The original measurement, on the old form:

`bin/land-round.sh` invokes its gates as `… | tail -1`. A pipeline's exit status is the LAST
command's, so without `pipefail` a failing gate prints `FAIL` and the script pushes anyway. It sets
`set -euo pipefail`; **that word is load-bearing, and here is the measurement rather than the
reading** (spec mutated via `bin/mutate.sh`, `REACHED_PUSH` stands in for the `git push` line):

| shell options | gate result | `REACHED_PUSH` printed? |
| --- | --- | --- |
| `set -euo pipefail` | `VERDICT: CHANGED` | ✅ **no** — the gate stopped the run |
| `set -eu` (no `pipefail`) | `VERDICT: CHANGED` | ⛔ **YES** — the gate was pure decoration |
| `set -euo pipefail` | `VERDICT: PRISTINE` | ✅ yes — green state is not blocked |

⭐ **All three cells were run.** The middle row is what a `pipefail`-less copy of this script does
today, in any repo that has one.

### 2.0 ⭐ THE STANDARD IS SAFE-BY-CONSTRUCTION, NOT SAFE-TODAY — and this repo MEETS it, measured

`commonplace-plan`'s framing, adopted here: the question is not *"is `pipefail` set?"* but **"would
deleting it change anything?"** ⭐ **A gate protected by a shell option three lines away is one
tidy-up from decoration; a gate whose rc it captures itself cannot be disarmed that way.**

**Measured 2026-08-25, not reasoned.** A copy of `bin/land-round.sh` with `set -euo pipefail`
rewritten to `set -eu` (positive control: 2 `pipefail` lines in the original, 1 in the copy — the
remaining one is a comment), run against a throwaway branch carrying a phantom arm:

```
REFUSED: check-plan-arms failed (rc=1); not pushing.
REFUSED: local main still holds the rejected merge. Undo with: git reset --hard ce89ddf
rc=70          origin/main unchanged: YES
```

⇒ **The gates here do not depend on `pipefail`.** `gate()` captures rc with `out=$("$@" 2>&1) ||
rc=$?` and the `| tail` calls run **after** that, shaping output only. ⚠️ **`pipefail` stays set
anyway** — it costs nothing and protects anything added later that forgets — but nothing load-bearing
rests on it.

⛔ **This supersedes §2.1's warning as it applies to THIS repo.** §2.1 is kept because it is the
measurement that caused the fix, and because any copy of the *old* shape elsewhere still has it.

### 2.0a ⛔ NEVER LOSE A FAILING TEST'S NAME — MEASURED, and my own instruments lost it

⭐ **A lost name turns a solvable defect into a permanent asterisk on a green suite.** Three repos in
this fleet hit an unexplained one-off failure on 2026-08-25 and **two could not say which test it
was** — one lost it to `tail -1`, one to not recording it. ⚠️ **The re-run is what destroys the
evidence.**

**Two places this repo lost names, both mine, both measured on a deliberately broken encoder:**

| instrument | before | after |
| --- | --- | --- |
| `land-round.sh` `gate()` on failure | `tail -20` showed **1 of 6** failing test names | ✅ **6 of 6**, printed first and in full |
| my per-round acceptance loop | `mix test --seed $s \| tail -1` shows only `156 tests, 6 failures` — **every name lost** | ⛔ see below |

⛔ **THE ACCEPTANCE LOOP FORM I USED IN EVERY ROUND WAS WRONG.** Do not do this:

```bash
for s in 1 2 3 4 5; do mix test --seed $s | tail -1; done      # ⛔ names lost
```

Use a form that keeps the whole output and only *summarises* when green:

```bash
for s in 1 2 3 4 5; do
  out=$(mix test --seed "$s" 2>&1) || { printf '%s\n' "$out"; echo "SEED $s FAILED"; break; }
  printf '%s\n' "$out" | tail -1
done
```

⚠️ **If a failure ever appears here: capture the FULL output, the SEED, and whether another Sol round
was in flight — BEFORE re-running.** ⭐ The three fleet occurrences shared a shape — first-run or
cold-build, under concurrency, never reproduced alone — and one was proven to be cross-clone resource
contention between two worktrees of the same tree. **This repo runs up to six worktrees.**

⛔ **A matching signature is not a cause.** One of the three had its shared-port hypothesis killed by
measurement. **Record, then investigate — do not diagnose from the shape.**

### 2.1a ⚠️ A REFUSED landing leaves the rejected merge in LOCAL main

Measured 2026-08-25 on the red arm above: `land-round.sh` merges **before** it runs the gates, so a
refusal exits with `origin/main` untouched (✅ the property that matters) and **local `main` sitting
on the rejected merge** — `a21532d`, while `origin/main` stayed `8d58e97`.

⛔ **"Nothing was pushed" and "nothing happened" are different states, and only one of them is
visible in the refusal message.** A naive re-run pushes the merge the gates just rejected. This
repo's copy therefore prints the way back:

```
REFUSED: local main still holds the rejected merge. Undo with: git reset --hard <pre-merge sha>
```

⭐ **That line is an addition to `commonplace-doc`'s 2dd5234 script, not part of it.** Reported back.

### 2.2 ⚠️ `check-spec-pristine.sh` was on NO path to `main` until 2026-08-25

`commonplace-doc`'s `land-round.sh` — which this repo copied verbatim — runs `mix test` and
`check-plan-arms.sh` and **not** the spec gate. So the gate existed in `bin/`, passed when invoked by
hand, and gated nothing. ⭐ **A gate nothing invokes is indistinguishable from one that always
passes.** Added here as its own commit; reported to `commonplace-doc` and `commonplace-doc-sync`.

---

## 3. How a round happens here

Recipe from `commonplace-doc` (msg 15851) and `commonplace-doc-sync` (msg 15852), unchanged.
Ceremony: `~/boss-clod/DISPATCH-CEREMONY.md` §1–§7. Briefing rules: `~/commonplace-doc/docs/BRIEFING-SOL.md`.

```bash
N=1                                      # round number
D=/home/jes/sol-value-p$N
mkdir -p $D
git worktree add $D/wt -b sol/phase-$N HEAD && git push -u origin sol/phase-$N
# prime on the HOST — there is no egress inside the fence
cd $D/wt && mix deps.get && MIX_ENV=test mix compile && mix test
# write $D/prompt.txt (>= 100 words, MUST contain the literal string "phase N")
cd /home/jes/commonplace-value && bash bin/dispatch-round.sh $D "phase $N"
# wait BY CAPTURED PID — never pgrep -f, it matches your own shell
until ! kill -0 $(cat $D/outer.pid) 2>/dev/null; do sleep 15; done
```

### ⛔ COUNTING ROUNDS IN FLIGHT: match on `comm`, NEVER on args

```bash
pgrep -u jes -x codex | xargs -r ps -o pgid= -p | tr -d ' ' | sort -u | wc -l
```

⚠️ **MEASURED 2026-08-25, and my own waiter had this wrong all night.** Three forms, same moment:

| form | reported | truth |
| --- | --- | --- |
| `ps -eo args \| grep -c '[c]odex exec'` | **9** | 4–5 processes per round |
| `ps -eo pgid,args \| grep '[c]odex exec'`, PGID-deduped — **what my waiter used** | **3** | ⛔ still wrong |
| `pgrep -u jes -x codex`, PGID-deduped | **2** | ✅ |

⭐ **THE REASON IS NOT THE ONE YOU'D GUESS, AND IT IS THIS REPO'S PHANTOM-ARM BUG IN A NEW CARRIER.**
The fleet's stated reason is per-round process fan-out (bwrap parents, node wrappers). Real, but
smaller. **Matching on ARGS also counts every process whose command line merely MENTIONS the
pattern** — and while this was being investigated, the matches included:

- another agent's shell writing *documentation about this very trap*, whose prose contained the
  literal string;
- another agent's script printing `raw 'codex exec' processes:`;
- **my own diagnostic command**, whose `grep -o` argument was unbracketed.

⇒ ⛔ **PROSE ABOUT A PATTERN CONTAINS THE PATTERN.** The more carefully the fleet documents this
trap, the more the args-based counter over-counts. ⭐ **Exactly the failure in §1 above**, where this
file's description of an `ARM` marker *became* an arm — **second occurrence, different carrier.**

✅ **`comm` is the executable name. Prose cannot be an executable called `codex`.** That is
safe-by-construction, not safe-by-care — the same standard as §2.0.

⚠️ **Which direction this fails matters:** over-counting makes a waiter refuse to dispatch into slots
that are already free — **self-inflicted starvation, invisible because the cap's own refusal is the
real gate and a waiter simply polls again.** It never announces itself.

`dispatch-round.sh` REFUSES on: no worktree · empty/short prompt · prompt not naming the round ·
HEAD on no remote ref · dirty tree. It verifies **both fence layers on the running pid** (tmpfs mask
count in `/proc/<pid>/mountinfo`, and `-C <wt>` in the cmdline — the `-C` is the write fence) and
writes `outer.pid`.

**Landing:**

```bash
cd /home/jes/commonplace-value          # cwd persists between tool calls; cd fresh
bash bin/land-round.sh sol/phase-$N
```

Refuses unless run from the **main checkout on main**. Merges `--no-ff`, runs `mix test`, both
gates, pushes, and **its verdict is what `origin` says**. ⭐ **My own commits go the same way:
branch → `land-round.sh`.** There is no other path to `main`.

---

## 4. Traps already paid for by others — do not re-buy them

| # | trap | the tell |
| --- | --- | --- |
| a | **Sol usually CANNOT commit** — `.git` is read-only in the fence | `0 commits` ≠ failed round. **Judge by `git -C $wt diff`**, then commit on Sol's behalf |
| b | ⛔ **Never `git checkout --` / `reset --hard` / `stash` — ANYWHERE, not just the Sol worktree** | ⚠️ **scope corrected 2026-08-25 after it cost work TWICE in the MAIN checkout** (errata **V12**). The hazard is the command, not the location. Use `bin/mutate.sh` for mutations, and demonstrate repository properties in a **scratch repo** — see `bin/check-landing-refuses.sh` |
| c | **No egress inside the fence** | prime deps on the host first; brief Sol to STOP with headline `compile blocked in fence` |
| d | **Sibling deps as DETACHED worktree pins** `~/<repo>-pin-<sha>` | never a live checkout. `bin/pin-in-use.sh` before removing one |
| e | ⛔ **`pgrep -f` / `pkill -f` matches your own argv** | a waiter built that way waits for itself forever. **Wait and kill by captured PID** |
| f | **Merging from inside the worktree "lands" nothing** | every command succeeds and the sentence is false. `land-round.sh` refuses |
| g | ⛔ **`git diff` does not contain new files** | an empty diff for a property living in an untracked test file is a method artifact |
| h | **Before trusting a zero, prove the corpus was non-empty** | `apps/*/lib` matches 0 files; git's `*` does not cross `/` |

⭐ **Anything measured inside the fence inherits the fence as a fact.** Masked paths, absent
credentials and denied egress surface as *ordinary negative findings with plausible mechanisms
attached*. Before briefing sandboxed work: **could the fence produce this result?** If yes the task
is not awkward in there, it is **unassignable** in there.

✅ **For this package that risk is unusually low: `commonplace_value` has ZERO runtime deps** (see
§5). A pure value package is the best case for the fence — it can produce no false finding about
network, credentials, or a live store.

---

## 5. MEASURED facts about the toolchain (2026-08-25, run on this host)

Each line is a command I ran, not a belief. `elixir 1.18.4 / OTP 27`, pinned in `.tool-versions`.

| measured | value | consequence for the spec |
| --- | --- | --- |
| `Code.ensure_loaded?(JSON)` | `true` | stdlib `JSON` is available; **zero runtime deps needed** |
| `JSON.encode!(1.0)` | `"1.0"` | ⛔ **not JCS.** JCS/§10.6 requires `1` |
| `JSON.encode!(1.0e21)` | `"1.0e21"` | ⛔ **not ECMAScript.** RFC 8785 requires `1e+21` |
| `JSON.encode!(<<0x1F>>)` | `"\"\\u001F\""` | ⛔ **uppercase hex.** §10.9 requires lowercase `\u001f` |
| `Float.to_string(1.0e21)` | `"1.0e21"` | ⛔ Erlang spelling, not ECMAScript |
| `:erlang.float_to_binary(f, [:short])` | shortest round-trip digits | ✅ **reusable as the DIGITS**, then reformatted to ECMAScript layout |

⭐ **THE CONSEQUENCE, and it is the round-3 headline: `JSON.encode!/1` CANNOT BE THE CANONICAL
ENCODER.** It is wrong on numbers *and* on escape case. The encoder is written from scratch;
`JSON.decode/1` is used only as the parser component §21 permits.

| measured | value | consequence |
| --- | --- | --- |
| `JSON.decode("1 ")` | `{:ok, 1}` | ⛔ **trailing whitespace accepted by the parser.** `:trailing_data` must be caught by §11.6's re-encode byte gate, not by the parser |
| `JSON.decode(~s({"a":1,"a":2}))` | `{:ok, %{"a" => 1}}` | ⛔ **duplicate keys silently collapse.** §11.6 catches it because re-encoding is shorter — **that is the clause doing the work, and it looks removable** |
| `JSON.decode("123456789012345678901234567890")` | `{:ok, 123456789012345678901234567890}` | ⛔ **arbitrary-precision integer, NOT binary64.** §6.3's binary64 semantics must be applied by US, over the parser's output |
| `JSON.decode("-0")` | `{:ok, 0}` | the parser loses the sign; §6.3 rejects `-0` anyway via the re-encode gate |
| `JSON.decode("1e400")` | `{:error, {:unexpected_sequence, 0, "1.0e400"}}` | ✅ non-finite tokens do not reach us as floats |
| `JSON.decode(<<0xEF,0xBB,0xBF,?1>>)` | `{:error, {:invalid_byte, 0, 239}}` | ✅ BOM rejected by the parser |
| `JSON.decode(<<?",0xFF,?">>)` | `{:error, {:invalid_byte, 1, 255}}` | ✅ malformed UTF-8 rejected by the parser |

⚠️ **Three of those rows are the same shape: the parser is more permissive than the spec, and the
only thing standing between that permissiveness and a wrong `{:ok, …}` is §11 clause 6.** Its stated
justification ("re-encoding must reproduce the input") is smaller than the job it does.

---

## 6. Inherited assets — data, never code

`~/commonplace-log/conformance/canonical-json/` holds 19 language-neutral JCS cases as
`input.json` (raw bytes) + `expected.hex` (lowercase hex of the canonical output), including the
tripwires this spec names by hand:

`004-sort-astral-before-e000` · `009-num-1e20` · `010-num-1e21` · `011-num-1e-6` · `013-num-1e-7` ·
`014-num-minus-zero` · `015-num-max-safe-int` · `018-float-spelled-integers` ·
**`999-deliberate-mismatch`** (the §19.3 anti-vacuity fixture, already built).

⛔ **§18 is explicit: copy the VECTORS, never import `Commonplace.Log.Jcs` as the implementation, and
never compare an implementation against itself.** `commonplace-log`'s canonicalizer is a
**differential oracle over fixtures only** (round 5), not a dependency — §21 forbids the dep outright.

---

## 7. Round map

| round | delivers | spec | status |
| --- | --- | --- | --- |
| **P1** | value domain: validation, normalization, UTF-8, RFC 6901 paths, structured errors | §5 §6.1 §6.2 §7 §15 | ✅ `6bbea45` |
| **P2** | resource-limit accounting at one-below / exact / one-above, depth-before-work | §13 §19.2 | ✅ `ce51ba8` |
| **P3** | RFC 8785 encoder, the opaque struct with the ruling's cached metrics, `new/2` `encode/1` `to_term/1` `equal?/2`, `max_bytes`, corpus harness | §9 §10 §12 §13.1 §19.1 §19.3 | ✅ `31e43e9` |
| **P4** | canonical decoding, the re-encode byte gate, the 22-case negative corpus | §11 §19.2 | ✅ `32f8bba` |
| **P5** | **`compose/2`** — the ruling's 20 required tests and the envelope regression fixture | ruling §2–§12 | ✅ `acda89e` |
| **P6** | fresh-process determinism, differential bytes vs `Commonplace.Log.Jcs`, boundary proof, dependency hygiene | §17 §18 §20.3 §20.17 §20.18 | ✅ landed |

⭐ **0.1's planned rounds are COMPLETE.** All twenty of §20's acceptance items have a named green
arm. ⛔ **§24 is NOT fully demonstrated and the gap is named in errata V15** — two independent
implementations agreeing on every pinned *rejection* needs a second implementation of §5/§6/§11,
which is not this repository's to write.

⭐ **See `docs/spec-errata.md` V8 for why `compose/2` is P5 and not earlier** — the ruling's own
required tests 18 and 19 need canonical decoding, which is P4. ✅ **P3 remains `commonplace-cell`'s
first pinnable sha;** `compose/2` is an optimization they adopt after.

⚠️ **DEVIATION FROM SPEC §23, stated rather than smuggled.** §23 puts *"opaque type and bounded
inspection"* in phase 1. It cannot go there: §9 makes **canonical bytes the identity-bearing
representation** and §13.1 measures `max_bytes` **on canonical bytes**, so no honest
`%Commonplace.Value{}` can exist before the encoder does. Shipping a half-built struct in P1 would
create exactly the artifact the claim discipline in §1 exists to prevent — a public API that looks
implemented. ⇒ **P1/P2 deliver `Commonplace.Value.Domain` as an INTERNAL module; the public API of
§14 lands whole in P3.** This is a design claim; it is recorded here and in `docs/spec-errata.md`,
never by editing the spec.
