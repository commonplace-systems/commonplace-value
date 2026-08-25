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

## V6 — ⚠️ OPEN QUESTION: there is no way to compose an already-constructed value

**Raised by:** commonplace-value (Opus), 2026-08-25, on evidence from `commonplace-cell`.
**Kind:** ⛔ **gap, not a decision. Routed to jes; NOT resolved here.**

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
