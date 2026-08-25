# IMPLEMENTATION PLAN — round P3: canonical bytes and the public API

**Work id: `VALUE-P3`. AND NO OTHER ID.**
**Round name, verbatim, as it appears in the dispatch prompt: `phase 3`.**

| shape | example | role — **not** this round's id |
| --- | --- | --- |
| the spec | `docs/proposals/2026-08-24-commonplace-value-spec.md` | never edited, gate-pinned |
| **the ruling** | `docs/proposals/2026-08-25-value-composition-ruling.md` | ⭐ **jes's design correction. Its §5 constrains the struct THIS round builds.** Never edited either |
| previous rounds | `VALUE-P1` `6bbea45` · `VALUE-P2` `ce51ba8` | the code you extend. Not this round |
| future rounds | `VALUE-P4` (decoding) `VALUE-P5` (`compose/2`) `VALUE-P6` | ⛔ **`compose/2` IS NOT THIS ROUND.** You build what makes it possible, not it |
| errata | `V1` … `V12` | amendments explaining WHY |
| `commonplace-cell` | a consumer, waiting to pin this round | not a dependency |

⭐ **If you need an id and only have those, that is a bug in my prompt: use `VALUE-P3` and say I
under-specified it.**

---

## 1. The ask

Three things that must land together, because none is honest alone:

1. **The RFC 8785 encoder** (§10) — canonical bytes from a normalized term.
2. **The opaque `%Commonplace.Value{}`** (§9) carrying **the ruling §5 cached metrics**.
3. **The §14 public API**: `new/2`, `encode/1`, `to_term/1`, `equal?/2` — plus `max_bytes` (§13.1),
   which could not exist before the encoder.

⭐ **This is `commonplace-cell`'s first pinnable sha.** They have written their plan so that either
`to_term` + `new/2` or `compose/2` satisfies it — **only the API's existence is load-bearing for
them, not its shape.**

⛔ **NOT in this round:** `from_canonical_json/2` (P4) · `compose/2` (P5) · the negative corpus (P4).

---

## 2. Scope, as a property

> **Every module this round creates under `lib/` is declared by a `MODULE:` marker below, and
> `bin/check-plan-arms.sh` FAILS on any module in `lib/` that is not.**

<!-- MODULE: Commonplace.Value -->
<!-- MODULE: Commonplace.Value.Encoder -->
<!-- MODULE: Commonplace.Value.Metrics -->
<!-- MODULE: Commonplace.Value.Domain -->
<!-- MODULE: Commonplace.Value.Error -->
<!-- MODULE: Commonplace.Value.Limits -->
<!-- MODULE: Commonplace.Value.Pointer -->

| module | state | responsibility |
| --- | --- | --- |
| `Commonplace.Value` | **new** | the opaque struct and the §14 public API |
| `Commonplace.Value.Encoder` | **new** | RFC 8785 bytes from a normalized term. ⛔ nothing else |
| `Commonplace.Value.Metrics` | **new** | the ruling §5 summary carried by every constructed value |
| `Commonplace.Value.Domain` | extend | `validate/2` must now **return** the metrics it currently computes and discards |
| `Error` · `Limits` · `Pointer` | unchanged | |

Test support may live under `test/support/` and needs no marker.

---

## 3. ⛔ THE ENCODER IS WRITTEN FROM SCRATCH — measured, not assumed

Errata **V2**, re-stated because it is the single most expensive thing to get wrong here:

| measured on this host | stdlib `JSON` | RFC 8785 requires |
| --- | --- | --- |
| `JSON.encode!(1.0)` | `1.0` | `1` |
| `JSON.encode!(1.0e21)` | `1.0e21` | `1e+21` |
| `JSON.encode!(<<0x1F>>)` | uppercase `` | **lowercase** `` |
| `Float.to_string(1.0e21)` | `1.0e21` | `1e+21` |

⇒ ⛔ **`JSON.encode!/1` MUST NOT appear in `lib/`.** It is wrong on numbers *and* on escape case.
✅ `:erlang.float_to_binary(f, [:short])` gives the shortest round-trip **digits** and those are
reusable — **the ECMAScript layout is then applied on top.**

⭐ **§21's closing sentence is the rule:** *"Library behavior is never accepted merely because the
dependency claims RFC 8785 support."*

### The two rules that are easy to get subtly wrong

1. **Object keys sort by UTF-16 code units** (§7), not code points and not UTF-8 bytes. U+10000
   encodes as the surrogate pair `D800 DC00` and therefore sorts **before** U+E000..U+FFFF, the
   opposite of both other orderings. ⭐ **`conformance/canonical/004-sort-astral-before-e000` is the
   tripwire and it is already in the repo.**
2. **ECMAScript number spelling** (§10.6): decimal form for `1e-6 <= |x| < 1e21`, exponential
   outside it, with an explicit `+` in the positive exponent. Cases `009` `010` `011` `012` `013`
   pin both ends.

---

## 4. The struct — constrained by the ruling, not free

Ruling §5: *every constructed Value must retain or make cheaply available* —

```text
canonical bytes · normalized term · encoded byte length · node count
maximum internal depth · maximum string byte length
maximum object member count · maximum array element count
a representation version
```

⭐ **THIS IS WHY THE METRICS MATTER NOW, IN A ROUND THAT DOES NOT BUILD `compose/2`.** P5 cannot
compose a child without them, and retrofitting them later means changing the struct after consumers
have pinned it. ⚠️ **§6 of the ruling: a child does NOT inherit permission to exceed limits** — a
child's cached depth is compared **at its new nesting position** — which is only possible if the
depth stored is the child's own **maximum internal depth**, not its depth in some earlier tree.

⛔ **P2's `Domain.validate/2` computes these and throws them away** (`{:ok, normalized, _nodes}`).
Extend it to return a `%Metrics{}`. ⚠️ **It currently tracks running totals for enforcement, which is
not the same as the MAXIMA the ruling wants** — e.g. `max_string_bytes` here means *the largest
string in this value*, not *the limit*. Read that distinction carefully; it is the one I expect to be
got wrong.

§9: fields are private, callers must not pattern-match them, and `Inspect` **SHOULD** show bounded
metadata such as `#Commonplace.Value<bytes: 184>` and **MUST NOT** print secrets merely because they
are portable.

---

## 5. MEASURED — facts I ran on this host

| command | result | consequence |
| --- | --- | --- |
| corpus probe: parse each `input.json` with `JSON.decode/1`, then `Domain.validate/1` | **29/29 parse and validate** | ✅ **the harness can route every corpus case through `new/2`** — no case trips §6.1's integer range |
| `mix test` at `ce51ba8` | `57 tests, 0 failures` | your baseline |
| `conformance/canonical` | 19 cases | imported, byte-verified |
| `conformance/valid-values` | 10 cases | ours, hand-authored from the RFC |

⚠️ **What I did NOT measure:** whether `:erlang.float_to_binary(f, [:short])`'s digits map onto
ECMAScript layout without an edge case at the exponent boundaries. **Measure it against cases 009 to
013 rather than trusting the transformation.**

---

## 6. Required arms

⭐ **FIRST DONE STEP: promote every `ARM-PLANNED:` below to `ARM:`.** ⛔ **Also promote the one
already sitting in `docs/IMPLEMENTATION-PLAN-P2.md` §6.7** — `construction rejects a term whose
canonical bytes exceed max_bytes` — **it was reserved for this round and this round pays it.**
Count them and report the number; ⚠️ *my count of the P2 markers was wrong by one and the round
caught it. The markers are the contract, not my arithmetic.*

⚠️ **Per arm: the mutation that turned it red, via `bin/mutate.sh`.** ⛔ Never `git checkout --`,
`git reset --hard`, or `git stash` — **anywhere**, not just here (errata **V12**: that cost work
twice this session, both times in the main checkout).
⭐ **VACUITY HATCH: if an arm cannot be made to fail, SAY SO and leave it red.** P1 did exactly that
and produced the round's most valuable result.

### 6.1 The encoder — §10

<!-- ARM: encoder emits UTF-8 with no BOM and no insignificant whitespace -->
<!-- ARM: encoder sorts object keys by UTF-16 code units -->
<!-- ARM: encoder sorts object keys recursively at every depth -->
<!-- ARM: encoder preserves array order -->
<!-- ARM: encoder emits the required two character escapes -->
<!-- ARM: encoder emits remaining C0 controls as lowercase u00xx escapes -->
<!-- ARM: encoder leaves solidus and non control Unicode unescaped -->
<!-- ARM: encoder spells 1e20 in decimal form and 1e21 with an explicit plus -->
<!-- ARM: encoder spells 1e-6 in decimal form and 1e-7 in exponential form -->
<!-- ARM: encoder emits negative zero as 0 -->
<!-- ARM: encoder emits safe integers without an exponent -->

⭐ **The astral-key arm must use a key whose three orderings genuinely differ** — U+10000 against a
U+E000..U+FFFF key. A BMP-only test passes under all three and measures nothing.

### 6.2 The struct and its metrics — §9, ruling §5

<!-- ARM: new returns an opaque value whose canonical bytes are its identity -->
<!-- ARM: constructed values carry every cached metric the composition ruling requires -->
<!-- ARM: cached maximum depth is the value own internal depth not its nesting position -->
<!-- ARM: inspect shows bounded metadata rather than the entire value -->
<!-- ARM: inspect does not reveal a secret contained in the value -->

⭐ **The metrics arm must check each field against an independent recount**, not against the
producer. ⚠️ *An implementation compared with itself agrees perfectly and proves nothing.*

### 6.3 The public API — §12, §14

<!-- ARM: encode returns the canonical bytes of a constructed value -->
<!-- ARM: to_term returns the normalized term -->
<!-- ARM: equal? is canonical byte equality -->
<!-- ARM: new of 1 and new of 1.0 construct equal values -->
<!-- ARM: new of 0 and new of negative zero construct equal values encoding to 0 -->
<!-- ARM: new rejects a Commonplace.Value struct as an ordinary term -->

⭐ **The last arm is the ruling §3 promise and it is a NEGATIVE about our own type:** `new/2` MUST
keep rejecting `%Commonplace.Value{}` with `:struct_not_allowed`. ⛔ **It is the arm that goes red if
someone "helpfully" makes `new/2` accept a Value while building P5.**

⚠️ §12: `equal?/2` **MUST NOT** recursively compare cached terms. An arm that only checks equal
values agrees under either implementation — **construct two values whose terms are equal and whose
bytes are equal, and one pair whose bytes differ**, and make the mutation "compare `to_term`
instead of bytes" go red.

### 6.4 `max_bytes` — §13.1, the arm P2 reserved

<!-- ARM: construction accepts a term whose canonical bytes are exactly max_bytes -->
<!-- ARM: construction rejects a term whose canonical bytes exceed max_bytes -->
<!-- ARM: max_bytes is measured on canonical bytes rather than on the input term -->

⭐ **The third arm is the whole point of §13 rule 1 and `conformance/canonical/017` is the fixture
that makes it vivid:** 1,048,977 input bytes canonicalizing to 327. **A term far larger than
`max_bytes` as written must be ACCEPTED when its canonical form fits.**

### 6.5 The conformance harness — §19.1, §19.3

<!-- ARM: conformance every canonical case encodes to its expected bytes -->
<!-- ARM: conformance every valid values case encodes to its expected bytes -->
<!-- ARM: conformance the deliberate mismatch cases are detected as mismatches -->
<!-- ARM: conformance harness refuses to report green on an empty corpus directory -->
<!-- ARM: conformance harness checks at least twenty nine cases -->
<!-- ARM: property canonical bytes are identical across repeated construction -->

⛔ **`conformance/README.md` is normative for the format. Read it.** Key points:
- `input.json` is authoritative **as raw bytes**; parse it with **`JSON.decode/1`** (permissive,
  test-only). ⚠️ **Many inputs are deliberately NON-canonical** — that is the point.
- `expected.hex` is lowercase hex of the canonical output; its trailing LF is file formatting.
- ⭐ **`9xx` cases MUST MISMATCH.** `canonical/999-deliberate-mismatch` and
  `valid-values/999-deliberate-mismatch-empty` store deliberately wrong expectations. **A run in
  which every case "passed" has proved nothing about the other 27.**
- ⭐ **There are TWO mismatch fixtures on purpose**, one per directory: a harness reading only
  `canonical/` would report green over an entirely unscanned `valid-values/`.
- ⛔ **Never route corpus input through a canonical decoder** — it does not exist yet, and it is
  required to reject exactly these bytes.

---

## 7. What I do NOT want

- ⛔ `JSON.encode!/1` anywhere in `lib/` — it is not a canonical encoder (V2);
- ⛔ any dependency on `commonplace-log`, or vendoring `Commonplace.Log.Jcs` (§18, §21). The corpus
  is **data**; their canonicalizer is a differential second opinion in **P6**, never the oracle;
- ⛔ `from_canonical_json/2`, permissive `from_json/1`, `compose/2`, schema validation, atomizing
  keys, hashing, or a content ID (§14 lists these as deliberately absent);
- ⛔ changes under `bin/`, `docs/proposals/`, `conformance/` fixture bytes, `README.md`, `mix.exs`,
  `.tool-versions`;
- ⛔ raising a default limit;
- ⛔ reformatting code you did not write. ⭐ **The test for an out-of-brief change is not "was it
  licensed" but "is this round's goal unachievable without it."** Extending `Domain.validate/2` to
  return metrics **passes** that test; rewrapping it does not.

---

## 8. Acceptance

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
for s in 1 2 3 4 5; do mix test --seed $s; done
bash bin/check-plan-arms.sh            # VERDICT: PASS
bash bin/check-plan-arms.sh --self-test
bash bin/check-spec-pristine.sh        # VERDICT: PRISTINE  (spec AND ruling)
bash bin/check-landing-refuses.sh      # VERDICT: PASS
```

**Count the corpus before believing any zero:**

```bash
grep -rho '^defmodule [A-Za-z0-9_.]*' lib/ | sort   # exactly the 7 declared modules
grep -rho '^\s*test "[^"]*"' test/ | wc -l          # >= 85
ls -d conformance/canonical/*/ | wc -l              # 19
ls -d conformance/valid-values/*/ | wc -l           # 10
grep -rc 'JSON.encode' lib/ || echo "0 -- required"
```

---

## 9. Report

1. **Per arm: the mutation that turned it red**, the failure line, and confirmation it perturbed the
   measured axis.
2. **How many `ARM-PLANNED` markers you promoted, counted** — including the one from the P2 plan.
3. **Whether `:erlang.float_to_binary/2`'s digits needed an exponent-boundary special case**, with
   the cases that showed it.
4. **Any place the ruling §5 metric list and §13's limit accounting disagree** — findings, not quiet
   fixes.
5. Any module created and whether it was on the `MODULE:` list.
6. Verbatim output of every command in §8.
7. ⚠️ `compile blocked in fence` as the headline if compile or deps fail.
8. ⚠️ **You probably cannot commit** (`.git` read-only). Leave the work in the tree and say so.
