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
