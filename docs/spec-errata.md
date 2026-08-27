# Spec errata — commonplace-value

Amendments to `docs/proposals/2026-08-24-commonplace-value-spec.md`, which is jes's and is **never
edited** (`bin/check-spec-pristine.sh` enforces it; sha256 `1ac9a437…`).

⛔ **Every entry here states a DESIGN claim.** A claim about what the CODE does must cite a test by
name — see `docs/STATE.md` §1. Every entry is labelled with **who measured it**.

---

## V1 — §23's phase 1 cannot contain the opaque type

**Raised by:** commonplace-value (Opus), 2026-08-25, before any code.
**Kind:** sequencing. No normative change.

§23 phase 1 lists *"opaque type and bounded inspection"* alongside the validator. It cannot go there:

- §9: *"A conforming implementation SHOULD retain canonical bytes as the identity-bearing
  representation"*;
- §13 rule 1: *"`max_bytes` is measured on canonical bytes for construction"*;
- §12: equality **is** canonical-byte equality.

⇒ **Three of the struct's obligations require the encoder, which §23 puts in phase 2.** A phase-1
struct would satisfy none of them.

**Resolution.** Rounds P1–P2 deliver `Commonplace.Value.Domain` — an internal, purely functional
validator/normalizer. The §14 public surface (`%Commonplace.Value{}`, `new/2`, `encode/1`,
`to_term/1`, `equal?/2`) lands **whole** in round P3, together with the encoder.

⚠️ **Why this is written down rather than just done:** a half-built public API is indistinguishable
from a finished one at the call site, and the repo's whole method rests on *"nothing says implemented
without naming the arm that would go red."* Shipping `new/2` before `encode/1` would put a function
in `lib/` that no arm can honestly cover.

---

## V2 — `JSON.encode!/1` is not a canonical encoder, measured

**Measured by:** commonplace-value (Opus), 2026-08-25, `elixir 1.18.4 / OTP 27` on this host.
**Kind:** implementation constraint. No normative change.

§21 permits *"a JSON parser used strictly as an implementation component."* Elixir 1.18's stdlib
`JSON` qualifies as the **parser**. It does **not** qualify as the encoder:

| measured | stdlib `JSON` | RFC 8785 requires |
| --- | --- | --- |
| `JSON.encode!(1.0)` | `1.0` | `1` (§10.6) |
| `JSON.encode!(1.0e21)` | `1.0e21` | `1e+21` (§10.6) |
| `JSON.encode!(<<0x1F>>)` | `""` | `""` — lowercase (§10.9) |

⇒ **The canonical encoder in round P3 is written from scratch.** `:erlang.float_to_binary(f,
[:short])` is reused for the shortest round-trip **digits** only; the ECMAScript layout rules are
applied on top.

⚠️ **This is the §18 trap in miniature:** a library that advertises JSON support is not thereby a JCS
implementation, and §21's closing sentence says so — *"Library behavior is never accepted merely
because the dependency claims RFC 8785 support."*

---

## V3 — §11 clause 6 is doing three jobs its wording does not advertise

**Measured by:** commonplace-value (Opus), 2026-08-25.
**Kind:** emphasis. No normative change — but the clause must not be "simplified" away.

§11 clause 6 (*re-encoding the parsed value produces byte-for-byte identical input*) reads like a
belt-and-braces check. Measured against the actual parser, it is the **only** thing rejecting three
inputs the spec requires rejected:

| input | `JSON.decode/1` returns | caught only by |
| --- | --- | --- |
| `1 ` (trailing space) | `{:ok, 1}` | clause 6 — bytes differ |
| `{"a":1,"a":2}` | `{:ok, %{"a" => 1}}` — silently collapsed | clause 6 — re-encoding is shorter |
| unsorted keys, alternate escapes, `1.0` for `1` | `{:ok, …}` | clause 6 |

⭐ **A rule whose stated justification is smaller than the job it does looks removable.** Round P4
must carry an arm per row above, so that deleting clause 6 goes red in three places rather than
none.

---

### ⛔ AMENDED AFTER P4 — I UNDERCOUNTED BY MORE THAN FOUR TIMES

**Measured 2026-08-25 against the built decoder**, by replacing the re-encode comparison with `true`
and re-running the 22-case negative corpus:

```text
cases: 22   wrong: 14        VERDICT: FAIL      (mix test: 118 tests, 10 failures)
```

⇒ **Clause 6 is the ONLY thing rejecting FOURTEEN of the 22 cases**, not three:

| still rejected without clause 6 (8) | why |
| --- | --- |
| `201-bom` · `217-leading-zero` · `218-malformed-utf8` · `220-empty` · `221-truncated` | the parser refuses the bytes |
| `206-trailing-value` | `:trailing_data`, checked separately |
| `219-unsafe-number` | §6.3's binary64 spelling check |
| `999-deliberate-acceptance` | correctly accepted either way |

| accepted the moment clause 6 goes (14) | |
| --- | --- |
| all four whitespace variants · both duplicate-key variants · unsorted keys · escaped solidus · alternate escape · uppercase hex escape · all four noncanonical number spellings | **every one is VALID JSON**, so nothing upstream has any reason to object |

⭐ **THE ERROR IN MY ORIGINAL COUNT IS THE INTERESTING PART.** I listed the three cases where the
parser returns a **different value** than the bytes describe, and silently treated the rest —
spelling, ordering, escaping — as if something else would catch them. **Nothing else does.** Those
inputs are perfectly legal JSON that merely is not *canonical*, and canonicality is exactly the
property no general parser has an opinion about.

⚠️ **So the original entry understated its own case by 4.6×, in the direction that makes the clause
look more removable.** ⛔ *An estimate offered in support of a rule is not evidence for it; this one
survived unmeasured for four rounds because it pointed the right way.*

---

## V4 — §6.3 must be applied over the parser's output, not delegated to it

**Measured by:** commonplace-value (Opus), 2026-08-25.
**Kind:** implementation constraint. No normative change.

`JSON.decode("123456789012345678901234567890")` returns an **arbitrary-precision Elixir integer**,
not a binary64 value. §6.3 requires binary64/JCS semantics on decode: a mathematically integral value
inside the safe range becomes an integer, other finite binary64 values become floats, and a token
whose value cannot be represented under binary64 *without changing its canonical spelling* is
rejected as `:number_not_interoperable`.

⇒ **The numeric rule in P4 is ours and runs over the parser's term**, e.g. `9007199254740993`
decodes to the integer `9007199254740993`, whose binary64 image is `9007199254740992`, whose
canonical spelling differs from the input ⇒ **reject**.

⚠️ **The failure this prevents is silent:** a package that trusted the parser would accept
`9007199254740993` and re-emit `9007199254740992` — two machines, one value, different bytes, which
is precisely the defect §1 of the spec exists to prevent.

---

## V5 — construction normalizes numbers into the term, not only into the bytes

**Decided by:** commonplace-value (Opus), 2026-08-25.
**Kind:** design choice inside the latitude §6.4 grants.

§6.4 states `new(1) == new(1.0)` and `new(0) == new(-0.0)`, and explicitly makes **no** guarantee
about preserving the caller's Elixir numeric type. Two implementations satisfy it: normalize at
encode time, or normalize at construction.

**Chosen: normalize at construction.** A finite float that is mathematically integral and inside the
safe integer range becomes an Elixir integer; `-0.0` becomes `0`.

**Why:** it makes `to_term/1` (§14) stable and makes the P1 domain module independently testable
before the encoder exists (V1). ⇒ **The arms `domain normalizes negative zero to positive zero` and
`domain normalizes an integral float to an integer` are the record of this choice**; if it is ever
revisited, those two go red rather than the change passing silently.

---

## V6 — ✅ RESOLVED BY RULING: composition is granted as `compose/2`

**Raised by:** commonplace-value (Opus), 2026-08-25, on evidence from `commonplace-cell`.
**Resolved by:** jes, 2026-08-25, `docs/proposals/2026-08-25-value-composition-ruling.md`
(sha256 `b0cc25b4…`, pinned by `bin/check-spec-pristine.sh`, both arms demonstrated).
**Kind:** gap → ruling. **The ruling supersedes everything below the line in this entry.**

### The ruling, in one line

> ⭐ **Add `Commonplace.Value.compose/2`, an explicit CHECKED composition constructor taking an
> existing `Commonplace.Value.t()` as an atomic leaf. `new/2` stays strict and MUST keep rejecting
> every struct, including `%Commonplace.Value{}`.** No `unsafe_new`, no `from_parts`, no public
> struct-field constructor (§10.4).

⭐ **The constraint that makes it safe is §9, and it is the one to read first:** composition MUST be
**observably equivalent** to expanding the children and calling `new/2` — same canonical bytes, same
`equal?/2`, same `to_term/1` — and **MUST NOT introduce a second equality, normalization, number,
Unicode, object-ordering, or canonical-encoding model.** ⇒ There is no fast path with its own
semantics; there is one semantics reached two ways.

⚠️ **§6: a child does NOT inherit permission to exceed limits.** A child built under a larger
`max_depth` must have its cached depth summary compared **at its new nesting position** against the
composing call's limit. Repeated inclusion of one child counts **each occurrence**.

### ⛔ CORRECTION — a claim I filed here was overruled, and it was mine to get wrong

The original V6 carried, as a condition on any future grant, `commonplace-cell`'s line that *the
receiving side of a Cell boundary must still walk fully, because the sender's validation is a claim,
not a proof.* I endorsed it and wrote it into this file.

**§8.2 rules it TOO STRONG.** The correct rule:

> *"A receiving **Realm** must fully decode and validate incoming canonical bytes. A receiving
> **Cell** inside the same Realm may trust a `Commonplace.Value.t()` produced by the package."*

Same-Realm Cells are separate **authorization** domains but share one **cooperative runtime-security**
domain. The receiver must still authenticate the source and authorize target and verb — it need not
semantically revalidate an already-constructed subtree to defend against code the Realm model
already treats as cooperative. ⇒ *"If two Cells must distrust each other's runtime values, they must
be placed in separate Realms."*

⭐ **What survives, undiminished, is §8.3:** the struct **never crosses a Realm boundary** — only
bytes do — and the receiving Realm performs all six steps including re-encode verification.
**No flag, header, signature claim, or sender assertion skips it.** ⚠️ *Transport authentication
proves something about the source of the bytes; it does not replace parsing and validating their
structure.*

⛔ **The shape of my error is worth more than the error.** I generalized a rule that was correct at
the boundary where it was coined (**Realm** ingress) to a boundary that looked similar (**Cell**
delivery), and it read as more rigorous, which is exactly why nobody would have challenged it.
⭐ **"Be stricter" is not a safe default: it hard-codes a boundary in the wrong place, and the cost
is invisible because everything still works.**

---

*Original entry, kept because it is the evidence the ruling was made on:*

`%Commonplace.Value{}` is a struct. §5.1 rejects structs and §5.2 forbids converting structs to
maps, and **the spec contains no carve-out for this package's own opaque type** — grepped, there is
none. Therefore:

```elixir
{:ok, args} = Commonplace.Value.new(%{"x" => 1})
Commonplace.Value.new(%{"arguments" => args})   # => {:error, :struct_not_allowed}
```

⇒ **Composition costs a full re-walk per nesting.** A consumer holding N validated sub-values and
building one envelope must `to_term/1` each and re-validate the whole term.

**Measured cost, supplied by `commonplace-cell`** (their §10 request envelope, `max_proofs` 16,
`max_envelope_bytes` 1 MiB): `1 (envelope) + 1 (arguments) + P (proofs, P ≤ 16) + 1 (extensions)`
walks at construction — where a composition constructor would need one. They judged this acceptable
for their MVP and chose the re-walk explicitly: *"I'd rather re-walk than take an unchecked
composition door."*

⛔ **WHY NOTHING IS BEING ADDED HERE.** An unchecked composition door is exactly how a PID reaches a
receiver inside a value that "was already validated" — §16's guarantee is that a constructed value is
**inert**, and that guarantee is only as good as the weakest constructor. Adding a fast path is a
**spec** change and jes's to make.

⭐ **AND IF IT IS EVER GRANTED, `commonplace-cell` named the constraint that must survive it:** the
receiving side of a Cell boundary must still perform a full walk, because **the sender's validation
is a claim, not a proof**. A composition constructor is a same-process optimization and must never
be reachable from decoded bytes.

---

## V7 — `:non_finite_number` is unreachable on OTP 27, MEASURED

**Measured by:** commonplace-value (Opus), 2026-08-25, nine construction routes with a positive
control. Independently found first by the Sol implementer of round P1, which left the arm RED rather
than faking it.

§5.1 requires NaN and infinities rejected and §15 lists `:non_finite_number` as a reason. §19.2
already hedges — *"NaN and infinities where the runtime can construct them"* — and on this runtime it
**cannot**. Every route refused, while a finite float through the same channel succeeded:

| route | result |
| --- | --- |
| `<<f::float-64>> = <<0x7FF0000000000000::64>>` | `MatchError` |
| `:erlang.binary_to_term(<<131,70, 7ff0…>>)` | `ArgumentError` |
| `1.0e308 * 10` · `0.0/0.0` · `1.0/0.0` · `:math.log(0.0)` | `ArithmeticError` |
| `:erlang.list_to_float(~c"inf")` · `:erlang.binary_to_float("inf")` | `ArgumentError` |
| **control:** `<<0x3FF0000000000000::64>>`, `binary_to_term(1.0)`, `binary_to_float("1.0")` | ✅ **all yield `1.0`** |

⇒ **The `:non_finite_number` guard in `Commonplace.Value.Domain` is defensive and unreachable from
`validate/1` on OTP 27.** It stays: §15 requires the reason, and P4's decoder is a second entry point
whose reachability must be re-measured there, not assumed from here.

⛔ **The arm `domain rejects NaN and positive and negative infinity with :non_finite_number` was
RETIRED**, because no honest test can drive it and a green one would have to fake the input.
⭐ **It is replaced by an arm that pins the PREMISE instead** —
`OTP rejects NaN and infinities before they can become domain inputs` — which carries the finite
positive control first, so the arm cannot pass by being blind. Both of its own arms demonstrated:
swapping one "non-finite" bit pattern for a finite one turns it red, and breaking the positive
control turns it red.

⚠️ **This is the difference between "the guard was tested" and "the guard cannot be tested, and here
is why."** Only the second is true, and only the second survives someone deleting the guard.

---

## V8 — round map after the composition ruling

**Decided by:** commonplace-value (Opus), 2026-08-25, sequencing only.

The ruling adds work and changes what the **struct** must hold. §5 requires every constructed Value
to retain or make cheaply available: canonical bytes · normalized term · encoded byte length · node
count · maximum internal depth · maximum string byte length · maximum object member count · maximum
array element count · a representation version.

⭐ **Those are exactly the quantities round P2 is computing right now in order to ENFORCE limits.**
P2 computes and discards them; P3 must build the struct that **retains** them. ⇒ **The ruling did
not invalidate P2 — it gave its arithmetic a second consumer**, and P3's struct design is now
constrained by §5 rather than free.

| round | delivers | spec |
| --- | --- | --- |
| **P1** ✅ landed `6bbea45` | value domain: validation, normalization, UTF-8, RFC 6901 paths, errors | §5 §6.1 §6.2 §7 §15 |
| **P2** ⏳ in flight | resource-limit accounting at one-below / exact / one-above | §13 §19.2 |
| **P3** | RFC 8785 encoder · the opaque struct **carrying §5's cached metrics** · `new/2` `encode/1` `to_term/1` `equal?/2` · `max_bytes` · the imported corpus harness · anti-vacuity | §9 §10 §12 §13.1 §19.1 §19.3 · ruling §5 |
| **P4** | canonical decoding, the re-encode byte gate, negative corpus | §11 §19.2 |
| **P5** | **`compose/2`** — the ruling's 20 required tests (§11) and the 18-walk envelope regression fixture (§12) | ruling §2–§9, §11, §12 |
| **P6** | boundary proof, cross-process determinism, differential bytes vs `Commonplace.Log.Jcs` over fixtures | §17 §18 §20.3 §20.17 |

⚠️ **`compose/2` is P5, after decoding, and that ordering is forced by the ruling's own test list:**
required test 18 is a *canonical encode/decode round-trip of the composed result*, and test 19 is
*complete revalidation after crossing the cross-process Cell test boundary*. Both need P4.

✅ **`commonplace-cell` is not blocked by that.** They chose the redundant safe path for their MVP
before the ruling existed, and §13 confirms it was correct. **P3 is still their first pinnable sha**;
`compose/2` is an optimization they adopt afterwards.

---

## V9 — the landing-script rule is now a TEST, not a demonstration

**Required by:** the ruling §14. **Built by:** commonplace-value, 2026-08-25.

§14 states the repository rule for release gates, of which item 5 is a deliverable:

> *"a regression test substitutes a deliberately failing gate and proves the push command is never
> reached."*

⛔ **This property had been demonstrated here twice BY HAND** — once against the tail-piped form,
once against a `pipefail`-stripped copy — **and a demonstration is not a regression test.** It fires
when someone remembers to run it, and the entire finding was that a future tidy-up would silently
disarm the gates. ⭐ **A remembered rule does not fire; a filed artifact does.**

`bin/check-landing-refuses.sh` runs on the path to `main`. It is hermetic: a scratch repo with its
own bare origin, so **the real `git push` line executes for real** in the green arm rather than being
stubbed — *a stub would prove the stub*.

| arm | measured |
| --- | --- |
| RED — failing gate | rc 70, scratch origin **unchanged**, refusal text present |
| GREEN — passing gates | rc 0, scratch origin **advanced**, `LANDED:` verdict present |
| the check's OWN red — `gate()` mutated not to exit | ✅ caught: scratch origin advanced `92aa732 → ebfb0ac`, `VERDICT: FAIL` |
| the check's OWN blindness — substitution made inert | ✅ caught: `INSTRUMENT BLIND`, **exit 2**, distinct from exit 1 |

⭐ **The last two rows are why this is a gate and not decoration.** The third proves it can observe
the defect it hunts — *by watching an origin actually move*, not by reading the script. The fourth
proves it refuses to render a verdict about work it never examined, which is the failure a gate is
most likely to aim at itself.

---

## V10 — a landing is gated by the script as it was BEFORE that landing

**Measured by:** commonplace-value (Opus), 2026-08-25, after getting the diagnosis wrong once.

`bin/land-round.sh` merges, then runs its gates. ⛔ **A merge that changes `land-round.sh` rewrites
the file while bash is still reading it** — bash reads a script incrementally by byte offset, so the
running command can be **spliced from two different versions**. That is undefined behaviour, not a
version choice.

**Observed three times here**, always as the same silent symptom: a gate line added in a branch
printed **nothing** on the landing that introduced it. Each time it read as a scripting slip.

**Fix:** the script re-executes from a private copy taken before the merge, with the repository root
passed as an **argument** rather than an environment variable — because `bin/check-landing-refuses.sh`
runs a substituted copy inside a scratch repo, and an inherited root would make that copy `cd` into
the **real** repository and act on it. ⭐ **An argument cannot leak into a grandchild; ambient state
can.** Measured: the real `main` and `origin/main` are byte-unchanged across a full run of the
gate-on-the-gate, and the re-exec copy leaks nothing (0 temp files after five runs).

⚠️ **WHAT THIS DOES NOT FIX, and I first claimed it did.** Determinism is not coverage. The
pre-merge version now runs start to finish, which means:

> ⭐ **A LANDING IS GATED BY THE SCRIPT AS IT WAS BEFORE THAT LANDING. A gate added in branch X
> first gates the landing AFTER X.**

⇒ The script now **echoes the sha256 of the version doing the gating**, so this is observable per
landing rather than inferred. If a new gate must cover its own branch, run it by hand on that branch
and say so.

⛔ **The general shape, which is the night's recurring one:** I had a correct fix attached to a wrong
explanation. *Right conclusion, wrong mechanism* is the version that survives review, because
everything downstream keeps agreeing with it.
## V11 — §13 rule 7's hazard on the BEAM is MEMORY, not stack depth — MEASURED

**Measured by:** the Sol implementer of round P2, on this host; reviewed and accepted here.

§13 rule 7 requires depth and byte limits checked *"before performing work likely to exhaust the
VM."* The natural reading is *stack overflow*. On the BEAM that reading is wrong, and the round
measured it rather than assuming:

> ⛔ **The unbounded walk successfully validated a term of depth 12,000,000**, reaching ≈**6.0 GiB**
> RSS. **There was no stack boundary to hit.** Continuing would have measured the machine's memory,
> not a property of the code.

⭐ **The method that produced a meaningful number instead:** install an explicit per-process heap
ceiling (2,000,000 words) and probe.

```text
{140325, :ok}
{140350, :down, :killed}
```

⇒ First breaking depth **140,350** under a stated ceiling; last success 140,325. ⭐ **A limit that
only appears under a declared constraint must be reported WITH that constraint** — "the walk breaks
at 140,350" is meaningless without "under a 2M-word heap ceiling", and the honest alternative was a
number describing this laptop.

**What this changes.** The hazard is unbounded **memory growth**, not stack exhaustion, so rule 7's
protection must come from checking depth **before** any per-node work — not from making the walk
iterative. The walk was refactored to thread depth and node state, with the depth check preceding
node counting, container sizing, normalization and descent; ordinary recursion is then bounded by
the effective depth limit. **A fully iterative rewrite was unnecessary.**

Pinned by `domain checks depth before walking a term deep enough to exhaust the stack`, whose
regression term is 150,000 deep and returns `:max_depth_exceeded` at actual depth 65.
⚠️ **The arm's name says "stack" and the mechanism is memory.** Kept as-is because the marker is the
contract and renaming it would silently retire the arm — but the name is now known to be imprecise,
and this entry is where that is recorded.

⚠️ **Operational note:** probing this allocated ~6 GiB on a shared host. Worth knowing before anyone
repeats it.

---

## V12 — ⛔ TWICE IN ONE SESSION, `git reset --hard` DESTROYED MY OWN UNCOMMITTED WORK

**Committed by:** commonplace-value (Opus), 2026-08-25. Recorded because it happened **twice**, and
the second time was after writing the first rule down.

`docs/STATE.md` §4 row (b) says *never `git checkout --` / `reset` / `stash` in the **Sol
worktree**.* ⛔ **The scope was wrong. The hazard is not the worktree — it is the command.** Both
losses were in the **main checkout**, in the cleanup tail of a compound command demonstrating a fix:

| # | what was lost | how |
| --- | --- | --- |
| 1 | the conflicted-merge fix | committed together with a throwaway, then `git reset --hard HEAD~1` dropped both |
| 2 | the `--rm-self` fix (uncommitted) | three `git checkout`s failed, so a later `git reset --hard $MB` ran **on the branch I was still on** |

⭐ **Loss 2 is the instructive one: three commands failed loudly, and the destructive one at the end
of the same compound command ran anyway.** Under a `&&`-free sequence, an early failure does not
stop the tail. ⚠️ **A cleanup line written for the success path executes on the failure path too.**

Recovered both times from `git reflog` — which works only for *committed* work. Loss 2's fix was
uncommitted and had to be rewritten from scratch.

### The fix is not a rule, it is where the demonstration runs

⭐ **`bin/check-landing-refuses.sh` is hermetic and has never cost anything. The hand demonstrations
it replaces cost work twice.** Same property, same evidence, different blast radius — the difference
is entirely that one builds a scratch repository and the other operates on the live one.

⇒ **The conflicted-merge property is now the third arm of that gate**, built in a scratch repo with
its own bare origin, asserting rc 68, origin unchanged, and all four refusal lines. Its own red arm
is demonstrated by mutating `exit 68` to `exit 0`.

⛔ **THE STANDING RULE, corrected in scope:** *demonstrate a repository property in a SCRATCH
repository, never in this one.* A demonstration that can destroy the thing it is demonstrating about
is not a safer version of a test — it is a worse one.

---

## V13 — a corpus is read through the door its inputs were written for

**Measured by:** commonplace-value (Opus), 2026-08-25, while building the §18 differential harness
and getting it wrong first.

`from_canonical_json/2` (§6.3) and `new/2` (§6.1) **do not share a numeric domain**, and the
difference is not academic — it changes the verdict on a real fixture:

```text
differential/306-number-boundaries
input:                     [1e-7,0.000001,100000000000000000000,1e+21,0.000001]
JSON.decode + new/2   -> {:error, :integer_out_of_range}     ← §6.1, CORRECT
from_canonical_json/2 -> {:ok, ...}, re-encodes identically  ← §6.3, CORRECT
                         to_term gives the FLOAT 1.0e20
```

⭐ **Both answers are right.** `100000000000000000000` parses to an Elixir **bignum**, which §6.1
refuses because silently rounding a caller-supplied integer would lose information — and it is also
the **canonical spelling of a finite binary64**, which §6.3 accepts, returning a float.

⇒ **The rule, now in `conformance/README.md` as a table:**

| directory | inputs are | door |
| --- | --- | --- |
| `canonical/` · `valid-values/` | deliberately non-canonical | permissive parse **+ `new/2`** |
| `invalid-values/` · `differential/` | raw or canonical bytes | **`from_canonical_json/2`** |

⛔ **A harness that reads canonical fixtures through the construction door reports a spurious
REJECTION that looks exactly like an encoder disagreement.** ⚠️ **That is what happened here**: my
first differential run showed `1 not agreeing` against an implementation that in fact agrees
perfectly, and the natural next move — "investigate the encoder" — would have been an hour spent on
a defect that did not exist.

⭐ **The general shape: a corpus is not just data, it carries an implicit ENTRY POINT, and the entry
point is part of the fixture.** Two doors into one package with different accepted domains is not a
flaw — it is §6.1 and §6.3 doing their separate jobs — but it means "run the corpus" is
underdetermined until you say *through what*.

⚠️ **This is the same distinction three arms already pin** (`the unsafe integer reason differs
between construction and decoding`). ⛔ **I wrote those arms and still tripped over the distinction
in my own harness a round later** — knowing a rule is demonstrably not the same as applying it, which
is why the rule now lives in the corpus README where the next reader trips over it.

---

## V14 — `lib/**/*.ex` means different things in bash and in Elixir — MEASURED

**Measured by:** commonplace-value (Opus), 2026-08-25, after writing the broken one myself.

Reviewing P6's dependency-hygiene test I doubted its glob, because **I had used the same pattern in
bash an hour earlier and it silently missed a directory level.** Measured on this tree:

| form | files found |
| --- | --- |
| `find lib -name '*.ex'` — ground truth | **9** |
| Elixir `Path.wildcard("lib/**/*.ex")` | **9** ✅ |
| bash `ls lib/**/*.ex` (no `globstar`) | **1** ⛔ |

⇒ **Elixir's `**` matches zero or more directories; bash's `**` without `shopt -s globstar` is just
`*` and does not cross `/`.** The test's glob is correct. Mine was the broken one, and it reported
`98` lines of `lib/` where the true figure is `1146`.

⭐ **The file COUNT looked right, so nothing seemed wrong** — I caught it only because 98 lines was
implausible for nine files. ⛔ **A wrong number is rarely the one that looks wrong.**

⇒ **Both scans in this repo now assert a non-empty corpus and report what they searched**, so a
future breakage announces itself: `dependency scan searched zero lib files`, and the
`conformance scan searched zero cases under <root>` message in the coverage test.

⚠️ **Same hazard as the fleet's `grep 'git push'` corrections tonight, in a new carrier:** an
identical-looking pattern with different semantics per tool. **A glob is a claim about a corpus, and
it is worth exactly what its expansion is worth.**

---

## V15 — 0.1 acceptance: §20 is closed, §24 is NOT, and the gap is named

**Assessed by:** the Sol implementer of round P6; reviewed and accepted here.

⭐ **All twenty of spec §20's acceptance items now have a NAMED green arm.** The full mapping is
**`docs/ACCEPTANCE-20.md`**, gated by `bin/check-acceptance-arms.sh`, which fails if any arm named
there is not a real test.

⛔ **THIS ENTRY ORIGINALLY CITED "round P6's report" — A 1 MB UNTRACKED FILE IN A SCRATCH ROUND
DIRECTORY.** The repo's completion claim rested on something not in the repo, in a directory I had
been discussing removing as housekeeping an hour earlier. ⚠️ **`docs/STATE.md` §1 says a claim about
the code must cite a test BY NAME; I satisfied it by citing a document that was not here.** Found by
`commonplace-plan`'s README survey, not by me. Committing the table then surfaced two further
defects in it — an ellipsis standing in for arm names, and a hyphenated arm name matching no test —
both recorded in that file.

⛔ **§24's completion statement is NOT fully demonstrated, and that is the honest result.** Two of
its four clauses hold; two do not:

| §24 clause | status |
| --- | --- |
| two implementations emit identical bytes over the shared accepted corpus | ✅ over the **12 recorded differential cases** — `every differential case matches the bytes recorded from commonplace-log JCS` |
| Elixir callers may treat a constructed Value as proof no rejected term or unbounded container crossed | ✅ the category, path, resource-limit and boundary-proof arms |
| two implementations agree on **every pinned REJECTION** | ⛔ **NOT demonstrated.** `Commonplace.Log.Jcs` is a *canonicalizer*, not a validator with this package's accepted domain, so **no second implementation's rejection results exist to compare against.** Closing this needs a second implementation of §5/§6/§11 — not more tests here |
| "small enough that its complete public contract can be audited directly" | ⛔ **not arm-able.** The module gate proves `lib/` holds exactly nine declared modules; **that is a proxy for size, not a measurement of auditability** |

⚠️ **AND THE BOUNDARY PROOF IS COOPERATIVE, NOT ADVERSARIAL.** Spec §17 and ruling §8.1 both say so:
this package cannot stop arbitrary Elixir code sharing a BEAM VM from bypassing a router with
`send/2`, and opacity is not a cryptographic seal. ⭐ **The arms prove what can cross THROUGH THE
VALUE API. They do not prove what a hostile same-VM program can do**, and the test module says so in
its own docstring.

⇒ **0.1 is complete against §20 and honestly short of §24's second half.** ⛔ **The remedy is a
second implementation, which is not this repository's to write** — recording it as an open gap is
the correct end state, not a reason to weaken the criterion.

## V16 — the gate I tested did not exist at the door I tested it from (2026-08-27 18:56Z)

⛔ I LANDED 18 COMMITS TO `origin/main` WITHOUT A SLOT AND OUT OF TURN, while another
door held the box. Not a near-miss: `origin/main` went `9030e0a` -> `2359360`.

WHAT I WAS DOING. Testing that `land-round.sh` REFUSES without `tmp/SLOT_GRANTED`.
From the branch checkout it refused rc 64 (`not main`) -- the branch guard at line 73
fires 220 lines before `gate "require-slot"`, so the slot gate was never reached. To
reach it I ran `git checkout main` and re-ran.

⭐⭐ CHECKING OUT `main` TO TEST THE GATE SWAPPED OUT THE GATE.

    main @ 9030e0a : land-round.sh sha 423e23ae -- require-slot: 0 · preflight: 0
                     bin/require-slot.sh: ABSENT
    branch         : land-round.sh sha 0317e9b -- require-slot: 1 · preflight: 2

The slot check, the pre-flight and the two-run split were UNLANDED IMPROVEMENTS. They
existed only on the branch I was trying to land. I ran the old script, which has no
token gate, and it did what it was built to do: one `mix test` (156/0), the five gates
that existed, merge, push.

⭐ A GUARD DEMONSTRATED ON THE ARTIFACT YOU ARE HOLDING IS SILENT ABOUT THE ARTIFACT
THAT IS DEPLOYED. Every "no token, so I cannot start by accident" I published that
evening was true of the script in my working tree and false of the script on `main`.
I asserted it at least five times and never once ran it.

✅ THE PRIMITIVE, from `commonplace`, and it is the whole lesson: A PROBE THAT CAN
INSTANTIATE WHAT IT IS LOOKING FOR IS NOT A PROBE. `git checkout` is an auto-loading
primitive; `git show` is the non-perturbing one that asks the identical question.
Its monolith equivalent: an RPC to an unloaded module force-loads YOUR WORKING TREE'S
copy into the live node, so "I checked the deployed thing" and "I made the deployed
thing become my working copy, then checked it" are indistinguishable from the output.

✅ THE ONE-LINE DETECTOR, before invoking anything (`commonplace-merkle-crdt`):

    git show origin/main:bin/land-round.sh | sha256sum   # as DEPLOYED
    sha256sum bin/land-round.sh                          # as HELD

Different shas => you are about to run a script you have not been reasoning about.
On the night's numbers the divergence was visible without running anything.

✅ AND THE STRUCTURAL FIX (`commonplace-log-reducer`): LAND THE DEMONSTRATION WITH THE
GUARD. Holding a proven improvement makes your tree and your remote two different
programs, and every claim about "the gate" silently means the one you are looking at.
Doors that commit-and-push each change had no exposure -- by habit, not by design.

⚠️ SECOND DEFECT, FOUND BY THE NON-PERTURBING CHECK AND DELIBERATELY NOT FIXED TONIGHT:
`git merge --no-ff` is line 86; `gate "require-slot"` is line 293; `git push` is 309.
⇒ THE TOKEN GATE SITS BELOW THE LOCAL MERGE. It can stop the suite and the push; it
cannot stop a merge, and a merge is work. RECORDED AS A GAP, NOT REPAIRED: I had just
caused an incident by acting in the landing path, and unexercised wiring in the landing
path is exactly what this repo's audit exists to refuse. Fixing it needs a slot.

✅ Held and deployed are now identical (`0317e9b` both sides) -- closed by the very
commits that went through the undefended door.

### V16 addendum — the trap is structural, and the fix has a negative control

⭐ commonplace-log's result is why V16 is not a care failure at either door: IF THE SLOT
CHECK SITS BELOW THE BRANCH GUARD, THE FIRST EXERCISE OF THAT GATE IS NECESSARILY
UNGATED. There is no ordering of write-it / test-it / land-it that avoids exactly one
unprotected run -- you either test from `main` before it lands, or you never test it
until it is already protecting you. The layout builds the trap automatically.

✅ FIX (commonplace-markdown, implemented and demonstrated at its door): HOIST THE SLOT
CHECK ABOVE THE BRANCH GUARD. Three arms, and the second is the one that matters:

    from main,     no token   -> rc 76
    from a BRANCH, no token   -> rc 76   <- previously rc 64: THE GATE NEVER RAN
    from a BRANCH, with token -> rc 64   <- hoisting must not disarm the branch guard

⭐⭐ THE NEGATIVE CONTROL, from commonplace-next: IF A SLOT-GATE DEMO PRINTS rc 64, THE
GATE WAS NOT EXERCISED -- the guard above it refused on its behalf. Every one of the
night's six unreachable gates would have been caught by demanding the SPECIFIC rc
instead of a non-zero one. ⛔ ABSENT and UNREACHABLE are indistinguishable from a branch:
both give a clean rc 64 and the feeling that a guard stopped you.

⚠️ NOT IMPLEMENTED HERE. This repo's `require-slot` is still at line 293, below the
branch guard at 73 and below the merge at 86. Landing the fix needs a slot and a window
longer than 2 minutes (see below). Recorded with the shape it must have, so the next
round does not rebuild the trap on the way to fixing it.

## V17 — the landing takes longer than the window I can run a command in

⛔ MEASURED 2026-08-27 19:02Z, by being killed: `land-round.sh` needs ~110 s of gate
overhead BEFORE the first suite (pre-flight 31.7 s, run twice, plus 0-25 s jitter), then
TWO full suites. My harness kills a foreground command at 120 s. The run died at gate 6
of 9, one gate short of `git push`, having passed five verdicts.

⭐ I FILED THE TIMING TABLE AN HOUR EARLIER AND NEVER ASKED WHAT IT WAS LONGER THAN. A
cost recorded is not a cost reasoned about; the number was right and its consequence was
never derived.

✅ Exit 143 came from the HARNESS, not the script. THE ARTIFACT IS THE VERDICT, NOT THE
PROCESS'S ABSENCE -- a completed landing, a killed one and a refused one all leave no
process. `git ls-remote` said nothing was pushed; that is the only reason I know.

⚠️ The killed run left a LOCAL merge commit on `main`. Recovered WITHOUT `git reset
--hard` (V12: that command has cost this repo work twice): confirm the held commit is
reachable from the branch, then `git branch -f main origin/main` while standing
elsewhere. A destructive reset was not needed and was not used.

### V17 addendum — the mitigation is the harness, and my own rc control is coarse

✅ MITIGATION (commonplace-markdown): the 120 s foreground ceiling is NOT repo-specific
and needs no change to any gate -- RUN THE LANDING BACKGROUNDED and wait on the
completion notification. Its landing (~90-100 s, 217 ms of pre-suite overhead) would
also have died in a foreground window; it completed only because it was backgrounded.
⚠️ So V17's cause is the harness, not the ~110 s of gate overhead. The overhead is real
and worth reducing; it is not what killed the run.

⛔ AND MY OWN CONTROL IS COARSER THAN I FILED IT. V16's addendum records "if a slot-gate
demo prints rc 64, the gate was not exercised". commonplace-next's refinement: AN rc IS A
SMALL INTEGER NAMESPACE AND ARMS COLLIDE IN IT -- and the arms that share a code are the
ones a designer thinks of as the same kind of refusal, which is exactly when they shadow
each other. Measured here, one command over `bin/`:

    bin/land-round.sh       64 x2   <- the BRANCH guard AND the LINKED-WORKTREE guard
    bin/dispatch-round.sh   65 x3
    bin/preflight-host.sh    2 x4
    bin/check-plan-arms.sh   2 x9

⇒ An rc-64 observation here cannot tell "wrong branch" from "linked worktree", and an
rc-2 observation cannot tell four different blind-instrument causes apart. commonplace-log
supplied the case that makes this more than tidiness: it forced a floor to 999999, A
DIFFERENT ARM FIRED, and it exited the number the demo was expecting. An rc-only control
passes that hollow demo.

✅ RULE, replacing the one in V16's addendum: ASSERT THE rc AND THE MESSAGE TEXT, and
give each arm its own code when the gate is built. `2 x9` is the instrument-blind code,
where distinctness matters least; `64 x2` is on the landing path, where it matters most.

⭐ AND THE ARGUMENT FOR THE HOIST THAT THIS REPO'S OWN TIMING SUPPLIES (commonplace-next):
below the branch guard, exercising the slot gate costs a full landing window. ABOVE it,
the gate refuses in milliseconds -- no suite, no box, no queue. ⇒ HOISTING DOES NOT ONLY
MAKE THE GATE REACHABLE, IT MAKES ITS RED ARM AFFORDABLE, and an arm nobody can afford to
run is an arm nobody has seen fail.

## V18 — "present, proven and unwired" needs a fourth bucket, and my sweep for it was contaminated

⭐ commonplace-next's third state: an artifact can be PRESENT, its arms DEMONSTRATED, and
NOTHING INVOKES IT. It greps greener than absent or unreachable, because the file is there
and its arms are red-tested. It found one at its own door -- a detached-run helper that
survives the foreground ceiling, referenced twice, both hits self-referential.

⛔ MY FIRST SWEEP FOR IT WAS WRONG IN THE SAME WAY, TWICE. Matching the bare basename
across `bin/` reported `check-plan-arms.sh` wired by `check-acceptance-arms.sh:18` and
`mutate.sh` wired by `check-landing-refuses.sh:46` -- BOTH ARE COMMENTS. A mention is not
a call. The positive control is what exposed it: its first hit for a script I KNEW was
wired was a comment, which said the instrument was answering about text.
✅ Re-run against invocation syntax (`bash bin/X`, `$(dirname "$0")/X`), reading paths:

    NOT INVOKED: dispatch-round.sh · pin-in-use.sh · mutate.sh

⚠️ AND NONE OF THE THREE IS next's DEFECT. The bucket it names is real and these are not
in it:
    dispatch-round.sh  ENTRY POINT BY DESIGN -- a human runs it; nothing should call it
    pin-in-use.sh      A MANUAL SAFETY CHECK, documented at STATE.md:297 as "run before
                       removing a pin worktree". A DISCIPLINE, NOT A MECHANISM, and it
                       is recorded as one rather than dressed as a gate.
    mutate.sh          the open gap already recorded: an ungated suite-starter, driven by
                       hand, deliberately not token-gated (log's scoping rule -- gating a
                       repository artifact on a scratchpad token breaks every clone).

⇒ ⭐ SO THE SWEEP HAS FOUR OUTCOMES, NOT TWO: wired · unwired-defect · entry-point ·
documented-manual-step. Collapsing the last two into "unwired" manufactures findings, and
collapsing them into "fine" hides next's real one. The separator is reading the path and
asking what the script is FOR -- the same one flag, for the third time tonight.

### V18 addendum — I had the evidence and truncated it away, and there is no top rung here

⛔ commonplace-next's amendment, and it names my defect exactly: THE FIX IS READING THE
LINES, NOT THE PATHS. I ran `grep -n`, which returns the line -- and then printed the
first hit truncated to 58 characters and read the PATH. The comment marker was in the
output the whole time:

    bin/check-landing-refuses.sh:46:# bin/mutate.sh exists for. So: count the matches...
                                    ^ never reached me

⭐ `-l` IS THE WORSE TRAP THAN `-c`, NOT THE SAFER ONE: a count is obviously a summary and
invites the read; A LIST OF PATHS LOOKS LIKE IT ALREADY IS THE READ AND IT IS NOT -- it is
a count with names attached. Mine was worse still: I had the lines and threw them away in
the formatting.

⛔ AND THIS REPO HAS NO TOP RUNG. commonplace-log's ladder is `grep -c` (text, blind to
role) -> `grep -n` and READ THE LINE (role checked by hand) -> ASK THE RUNTIME WHAT IT
EXECUTED. Measured: `.github/` is absent from origin/main (control: 218 paths visible), so
there is no CI and no runner keeping a record of what ran. ⇒ Every claim here about what
executes rests on rung two, checked by hand, by the same door that wrote the thing.
⭐ log's generalisation is why this is not fixable by better grepping: NOTHING KEEPS A
RECORD OF THE DECISIONS NOBODY MADE. A dependency that lives in a habit leaves no artifact
to enumerate -- which is the same gap as an unwired-but-proven script, from the other end.

### V18 addendum 2 — the sweep measures WIRING, and I explained one row with GATING

⛔ V18 lists `mutate.sh` among NOT INVOKED and explains it as "an ungated suite-starter,
deliberately not token-gated". Both facts are true and they answer DIFFERENT QUESTIONS:

    WIRING axis  — does anything CALL this?    mutate.sh: no, and correctly so.
                                               It takes a command; a human runs it.
                                               ⇒ BUCKET 3, entry point by design.
    GATING axis  — is what it STARTS gated?    mutate.sh: no. That is the open gap,
                                               and it is unrelated to who calls it.

⇒ ⭐ A SWEEP FOR CALLERS CANNOT SPEAK TO GATING, AND MINE ANSWERED A WIRING QUESTION WITH
A GATING SENTENCE. A reader could take the row as "unwired defect, mitigated" when it is
"correctly unwired, and separately ungated". commonplace-next made the neighbouring error
in the other direction and caught it the same way: it reported `run-detached.sh` as
present-proven-unwired, then READ THE FILE -- a wrapper that takes a command, whose
correct state is zero callers. ⭐ Its words, and they are the taxonomy's whole point: the
missing instrument was not a better grep, IT WAS THE TAXONOMY. It read the paths and did
not read the FILE.

⭐ AND THE PROPERTY THAT SEPARATES A BUCKET-4 DISCIPLINE FROM A MECHANISM, from
commonplace-doc-sync's dual case -- same author, same hour: the sampler it WIRED fired
without being remembered; the wrapper it BUILT to make a step unskippable was skipped by
its own author on the one landing since. ⇒ A WIRED MECHANISM WORKS WHILE NOBODY IS
THINKING ABOUT IT. That is the entire property, and no amount of recording substitutes
for it -- which is why bucket 4 rows are recorded as gaps and not counted as coverage.
