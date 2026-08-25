# IMPLEMENTATION PLAN — round P4: canonical decoding

**Work id: `VALUE-P4`. AND NO OTHER ID.**
**Round name, verbatim, as it appears in the dispatch prompt: `phase 4`.**

| shape | example | role — **not** this round's id |
| --- | --- | --- |
| the spec | `docs/proposals/2026-08-24-commonplace-value-spec.md` §11 §6.3 §13.1 | never edited, gate-pinned |
| the ruling | `docs/proposals/2026-08-25-value-composition-ruling.md` §8.3 | ⭐ **the cross-Realm rule this round implements the door for.** Never edited |
| previous rounds | `P1` `6bbea45` · `P2` `ce51ba8` · `P3` `31e43e9` | the code you extend |
| `VALUE-P5` | `compose/2` | ⛔ **not this round.** Its required tests 18 and 19 wait on YOUR work |
| errata | `V3` `V4` | ⭐ **read these two first — they are this round's measured ground** |
| `commonplace-cell` | pinned at `31e43e9`; their P1b waits on `from_canonical_json/2` | a consumer, not a dependency |

⭐ **If you need an id and only have those, that is a bug in my prompt: use `VALUE-P4` and say I
under-specified it.**

---

## 1. The ask

Implement **`Commonplace.Value.from_canonical_json/2`** (§11) — parsing bytes that are **required to
already be the one canonical encoding of their value**. ⭐ **This operation validates; it does not
tidy arbitrary JSON.**

Ruling §8.3 is why it matters: the struct **never** crosses a Realm boundary, only bytes do, and the
receiving Realm must *enforce byte limits · parse · validate the domain · enforce its own limits ·
**verify canonical re-encoding** · construct a new local value*. ⛔ **No flag, header, or sender
assertion skips any of it.** This round is that door.

⛔ **NOT in this round:** `compose/2` (P5) · a permissive `from_json/1` (§11 says 0.1 deliberately has
none) · the differential check against `Commonplace.Log.Jcs` (P6).

---

## 2. Scope, as a property

<!-- MODULE: Commonplace.Value -->
<!-- MODULE: Commonplace.Value.Encoder -->
<!-- MODULE: Commonplace.Value.Decoder -->
<!-- MODULE: Commonplace.Value.Metrics -->
<!-- MODULE: Commonplace.Value.Domain -->
<!-- MODULE: Commonplace.Value.Error -->
<!-- MODULE: Commonplace.Value.Limits -->

`Commonplace.Value.Decoder` is the only new one. Test support under `test/support/` needs no marker.

---

## 3. ⭐ THE MEASURED GROUND — errata V3 and V4, and why clause 6 is the whole round

§11 accepts bytes only when **all six** hold. Clause 6 — *re-encoding the parsed value produces
byte-for-byte identical input* — **reads like belt-and-braces and is not.** Measured on this host,
the stdlib parser returns `{:ok, …}` for all three of these:

| input | `JSON.decode/1` returns | caught ONLY by |
| --- | --- | --- |
| `1 ` | `{:ok, 1}` | clause 6 — bytes differ |
| `{"a":1,"a":2}` | `{:ok, %{"a" => 1}}` — silently collapsed | clause 6 — re-encoding is **shorter** |
| `{"a":1,"a":1}` | `{:ok, %{"a" => 1}}` — and collapsing loses **no value at all** | clause 6 |

⭐ **A rule whose stated justification is smaller than the job it does looks removable.** ⇒ **Three
arms below must go red if clause 6 is deleted**, so that removing it fails in three places rather
than none.

### §6.3 is OURS, not the parser's — errata V4

`JSON.decode("123456789012345678901234567890")` returns an **arbitrary-precision Elixir integer**,
not a binary64 value. §6.3 requires binary64/JCS semantics on decode:

- an integral value **inside** the safe range → Elixir **integer**;
- other finite binary64 values → Elixir **float**;
- ⛔ a token whose value cannot be represented under binary64 **without changing its canonical
  spelling** → **`:number_not_interoperable`**.

⭐ **Worked example, and it is corpus case `219`:** `9007199254740993` is 2^53+1; its binary64 image
is `9007199254740992`; that spells differently from the input; **reject.**

⚠️ **And the same digits arriving at `new/2` as an Elixir integer are `:integer_out_of_range`
instead** (§6.1). **Same value, two entry points, two different correct reasons.** Do not unify them.

⭐ **§6.3 also means canonical decoding MAY accept an integral-looking token outside the safe integer
range** when it is the canonical spelling of a finite binary64 value — `to_term/1` returns a **float**
there. `1e+21` decodes; `100000000000000000000` decodes to a float. **§6.1's restriction is about
Elixir integer INPUTS only.**

### §13.1 flips for decoding

> *"`max_bytes` is measured on canonical bytes for construction and **directly on input bytes for
> canonical decoding**."*

⇒ **Check the input length BEFORE parsing** (§13 rule 7: *before performing work likely to exhaust
the VM*).

---

## 4. MEASURED — facts I ran on this host

| command | result | consequence |
| --- | --- | --- |
| `mix test` at `0a65e2f` | `88 tests, 0 failures` | your baseline |
| every `invalid-values` case through the P3 encoder | **21 non-canonical, 1 canonical, 0 mislabeled** | ✅ the negative corpus is correctly labelled |
| every `canonical` + `valid-values` case | 29/29 encode to their expected bytes | ✅ the positive corpus is real |

⚠️ **What I did NOT measure:** whether re-encoding for clause 6 can reuse `Encoder` unchanged, or
whether decoding needs its own path for tokens the encoder never emits. **Find out and say which.**

---

## 5. The corpus is the product — `conformance/README.md` is normative

**22 negative cases** in `conformance/invalid-values/`. Format:
`input.bytes` (raw, **no trailing LF**) · `reason` (acceptable slugs, one per line) · `why.md`.

- ⭐ **Three cases carry TWO slugs** because the spec does not pin evaluation order — `201-bom`,
  `206-trailing-value`, `218-malformed-utf8`. **Accept any listed slug.** ⛔ Do not narrow them.
- ⛔ **`999-deliberate-acceptance` INVERTS the trap for this directory: it contains `1`, which IS
  canonical and MUST be ACCEPTED.** ⭐ *A rejection harness that rejects everything passes every
  other case here* — so the fixture that catches it is one that must **succeed**. A harness
  reporting it as correctly rejected is broken and must fail the run.

---

## 6. Required arms

⭐ **FIRST DONE STEP: promote every `ARM-PLANNED:` below to `ARM:`. Count them and report the
number** — ⚠️ *my count has been wrong by one in each of the last two rounds and the round caught it
both times. The markers are the contract, not my arithmetic.*

⚠️ **Per arm: the mutation that turned it red, via `bin/mutate.sh`.** ⛔ Never `git checkout --`,
`git reset --hard`, or `git stash` — **anywhere** (errata **V12**).
⭐ **VACUITY HATCH: if an arm cannot be made to fail, SAY SO and leave it red.**

### 6.1 The six acceptance conditions — §11

<!-- ARM: from canonical json accepts the canonical bytes of every positive corpus case -->
<!-- ARM: from canonical json rejects insignificant whitespace -->
<!-- ARM: from canonical json rejects a trailing newline -->
<!-- ARM: from canonical json rejects a trailing JSON value -->
<!-- ARM: from canonical json rejects a byte order mark -->
<!-- ARM: from canonical json rejects unsorted object keys -->
<!-- ARM: from canonical json rejects duplicate object keys -->
<!-- ARM: from canonical json rejects duplicate object keys whose values are equal -->
<!-- ARM: from canonical json rejects alternate string escapes -->
<!-- ARM: from canonical json rejects an escaped solidus -->
<!-- ARM: from canonical json rejects uppercase hexadecimal escapes -->
<!-- ARM: from canonical json rejects noncanonical number spellings -->
<!-- ARM: from canonical json rejects malformed UTF-8 -->
<!-- ARM: from canonical json rejects empty and truncated input -->

⭐ **Three of those are the clause-6 tripwires** — trailing whitespace, duplicate keys, and duplicate
keys with equal values. ⛔ **Build them so that deleting the re-encode comparison turns all three
red.** ⚠️ *A test that relies on the parser rejecting them measures the parser, not us — and the
parser measurably does not.*

### 6.2 The numeric model on decode — §6.3

<!-- ARM: canonical decoding yields an integer for an integral token in the safe range -->
<!-- ARM: canonical decoding yields a float for an integral token outside the safe range -->
<!-- ARM: canonical decoding rejects a token whose binary64 image spells differently -->
<!-- ARM: the unsafe integer reason differs between construction and decoding -->

⭐ **The last arm pins the distinction directly:** the same digits give `:integer_out_of_range` from
`new/2` and `:number_not_interoperable` from `from_canonical_json/2`. **It goes red if anyone unifies
them.**

### 6.3 Limits and errors — §13.1, §15

<!-- ARM: canonical decoding measures max bytes on the input bytes -->
<!-- ARM: canonical decoding checks the byte limit before parsing -->
<!-- ARM: decode errors carry the decode operation rather than construct -->
<!-- ARM: decode errors do not reproduce the rejected bytes -->

⭐ **`canonical decoding measures max bytes on the input bytes` is the mirror of P3's arm** and the
two together pin §13.1's split. **Use a 1 MiB-plus input whose canonical form is small** — the shape
of `conformance/canonical/017`, which construction ACCEPTS and decoding must REJECT on size.
⚠️ *That is the same file behaving oppositely under the two operations; if both arms agree, one of
them is measuring the wrong quantity.*

### 6.4 Round trips — §11, §12, §20

<!-- ARM: canonical decode followed by encode returns identical bytes -->
<!-- ARM: a decoded value equals the constructed value it came from -->
<!-- ARM: to term of a decoded value equals to term of the constructed value -->
<!-- ARM: property construct encode decode encode is byte identical -->

### 6.5 The negative harness — §19.2

<!-- ARM: conformance every invalid values case is rejected with an accepted reason slug -->
<!-- ARM: conformance the deliberate acceptance case is accepted rather than rejected -->
<!-- ARM: conformance invalid values harness refuses to report green on an empty directory -->
<!-- ARM: conformance invalid values harness checks at least twenty two cases -->

---

## 7. What I do NOT want

- ⛔ a permissive `from_json/1`, or any repair of non-canonical input — §11 is explicit that importing
  arbitrary JSON needs a caller-owned policy followed by `new/2`;
- ⛔ `compose/2`, or loosening `new/2` to accept `%Commonplace.Value{}` (ruling §3);
- ⛔ unifying `:integer_out_of_range` with `:number_not_interoperable`;
- ⛔ narrowing a two-slug corpus case to one slug, or editing any fixture bytes;
- ⛔ `JSON.encode!/1` in `lib/` — still not a canonical encoder (V2);
- ⛔ a dependency on `commonplace-log`;
- ⛔ changes under `bin/`, `docs/proposals/`, `README.md`, `mix.exs`, `.tool-versions`;
- ⛔ reformatting code you did not write.

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

```bash
grep -rho '^defmodule [A-Za-z0-9_.]*' lib/ | sort   # exactly the 8 declared modules
grep -rho '^\s*test "[^"]*"' test/ | wc -l          # >= 115
ls -d conformance/invalid-values/*/ | wc -l         # 22
git status --porcelain conformance/ | wc -l         # 0 -- fixture bytes untouched
```

---

## 9. Report

1. **Per arm: the mutation that turned it red**, the failure line, and confirmation it perturbed the
   measured axis.
2. **How many markers you promoted, counted.**
3. ⭐ **Whether clause 6 could reuse `Encoder` unchanged**, or needed its own path — and if the
   latter, which tokens forced it.
4. **Any negative corpus case whose `reason` slugs you believe are wrong** — findings, not quiet
   fixes, and ⛔ **do not edit the fixture; report it.**
5. Any module created and whether it was on the `MODULE:` list.
6. Verbatim output of every command in §8.
7. ⚠️ `compile blocked in fence` as the headline if compile or deps fail.
8. ⚠️ **You probably cannot commit** (`.git` read-only). Leave the work in the tree and say so.
