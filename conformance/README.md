# Conformance corpus — `commonplace-value`

Spec §19. ⭐ **This corpus is the product, not the test aid.** A value that passes every structural
check and encodes to different bytes on two machines is the exact defect this package exists to
prevent, and no structural check can see it.

```text
conformance/
├── canonical/        RFC 8785 canonicalization vectors  (imported, §19.1)
├── valid-values/     positive vectors filling §19.1 gaps (ours)
├── invalid-values/   rejection vectors with reason slugs (ours, §19.2)
└── differential/     bytes emitted by commonplace-log's JCS (§18)
```

### ⛔ EACH DIRECTORY HAS ITS OWN DOOR, AND USING THE WRONG ONE COSTS A FALSE FAILURE

| directory | inputs are | read them with |
| --- | --- | --- |
| `canonical/` | **deliberately NON-canonical** | permissive `JSON.decode/1` **+ `new/2`** |
| `valid-values/` | non-canonical (whitespace, spacing) | permissive `JSON.decode/1` **+ `new/2`** |
| `invalid-values/` | raw bytes that must be refused | **`from_canonical_json/2`** |
| `differential/` | **canonical by construction** | **`from_canonical_json/2`** |

⭐ **This is not a stylistic choice — the two doors have DIFFERENT numeric domains** and disagree on
real inputs. §6.1 governs Elixir **integer inputs**; §6.3 governs **canonical tokens**. Measured on
`differential/306-number-boundaries`:

```text
input:                     [1e-7,0.000001,100000000000000000000,1e+21,0.000001]
JSON.decode + new/2   -> {:error, :integer_out_of_range}     ← §6.1, correct
from_canonical_json/2 -> {:ok, ...}  re-encodes identically  ← §6.3, correct
                         to_term gives the FLOAT 1.0e20
```

⚠️ **Both answers are right.** `100000000000000000000` parses to an Elixir bignum, which §6.1
correctly refuses, and is the canonical spelling of a finite binary64, which §6.3 correctly accepts.
⛔ **A harness that reads canonical fixtures through the construction door reports a spurious
rejection that looks exactly like an encoder disagreement.** *(It happened here — errata **V13**.)*

⛔ **An empty directory and a passing corpus are indistinguishable to a harness that does not
count.** Any harness reading these MUST assert a non-zero case count per directory before reporting
green.

---

## `invalid-values/` — ours, 22 cases, the §19.2 rejection vectors

**Format** — deliberately different from the other two directories, because these cases are about
bytes that must be REFUSED, not bytes that must be produced:

- **`input.bytes`** — the raw input, authoritative to the byte. ⛔ **No trailing LF.** The bytes
  *are* the case; a trailing newline would silently turn every case into `204`.
- **`reason`** — one acceptable `Commonplace.Value.Error` reason slug per line. ⭐ **More than one
  line means the spec does not pin which comes first**, and a harness must accept any of them.
- **`why.md`** — one sentence. What this case is for, in prose, so a future reader is not reverse-
  engineering intent from 3 bytes.

### ⭐ Only three cases have an ambiguous slug, and the ambiguity is real

| case | slugs | why both are defensible |
| --- | --- | --- |
| `201-bom` | `invalid_json` · `non_canonical_json` | a strict parser rejects the byte before canonicality is ever assessed |
| `206-trailing-value` | `trailing_data` · `non_canonical_json` | §15 names `trailing_data`; the re-encode gate would also catch it |
| `218-malformed-utf8` | `invalid_utf8` · `invalid_json` | the parser rejects the byte, and the domain would too |

⛔ **Everything else pins exactly one slug.** ⚠️ **Do not "simplify" a two-slug case to one** — that
bakes an implementation's evaluation order into a language-neutral corpus.

### ⚠️ `219-unsafe-number` is the one whose two operations carry DIFFERENT reasons

`9007199254740993` is 2^53+1. Its binary64 image is `9007199254740992`, whose canonical spelling
**differs from the input**, so §6.3 requires rejection as **`:number_not_interoperable`** — that is
the **decode** reason, and it is what this case pins.

⭐ **The same digits reaching `new/2` as an Elixir integer are rejected as `:integer_out_of_range`
instead** (§6.1). ⇒ **Same value, two entry points, two correct reasons.** *(Measured: `JSON.decode`
returns the arbitrary-precision integer without complaint, so this rejection is entirely ours —
errata **V4**.)*

### ⭐ The cases the stdlib parser ACCEPTS, which are the point of §11 clause 6

Measured, errata **V3**. For these, the parser returns `{:ok, …}` and **only the re-encode byte
comparison rejects them**:

| case | `JSON.decode/1` returns |
| --- | --- |
| `203-trailing-whitespace` | `{:ok, 1}` |
| `207-duplicate-keys` | `{:ok, %{"a" => 1}}` — silently collapsed |
| `208-duplicate-keys-equal` | `{:ok, %{"a" => 1}}` — and collapsing loses **no value at all** |

⇒ **Deleting §11 clause 6 must turn these red.** ⚠️ *Its stated justification is smaller than the job
it does, which is exactly what makes it look removable.*

### ⛔ `999-deliberate-acceptance` — anti-vacuity, INVERTED for this directory

`canonical/999` and `valid-values/999` store a wrong *expectation*. This directory needs the opposite
trap: **`999-deliberate-acceptance` contains `1`, which IS canonical and MUST be ACCEPTED.**

⭐ **A rejection harness that rejects everything passes every other case in this directory.** That is
the failure mode here — not a wrong expectation, but an indiscriminate one — so the fixture that
detects it is a case that must **succeed**. A harness reporting `999` as correctly rejected is broken
and must fail the run.

### Verified at authoring time

Every case was run through the landed P3 encoder: parse permissively, construct, encode, compare to
the input bytes. **21 non-canonical, 1 canonical (the `999` case), 0 mislabeled.**
⚠️ **That check uses the encoder to validate the CORPUS, which is legitimate** — the encoder is
independently verified against 29 positive vectors — **but it is not free: if the encoder were wrong
about some construct, a negative case could be mislabeled.** It cannot validate the encoder; that
would be an implementation compared with itself.

---

## `valid-values/` — ours, 10 cases, filling gaps §19.1 requires

**Why these exist.** §19.1 requires *"every scalar kind"* and *"empty arrays, objects, and keys"*.
The imported corpus contains those **only nested inside larger documents** — measured: no
`input.json` in `canonical/` is a top-level `null`, `true`, `false`, `""`, `[]`, or `{}`, and none
contains the **negative** maximum safe integer.

⚠️ **That gap probe first produced a FALSE ZERO** and it is worth recording why: `grep '[]'` is an
**empty bracket expression**, not a literal, so `[]` reported absent from a file that visibly
contains it. ⭐ **Re-run with `grep -F` and a positive control naming a string known to be present.**
*A grep whose pattern means something other than what it looks like returns 0 hits and looks exactly
like a confirmed absence.*

| case | pins |
| --- | --- |
| `101`–`103` | top-level `null` · `true` · `false` |
| `104` | top-level empty string |
| `105` · `106` | top-level empty array · empty object |
| `107` | **negative** maximum safe integer, the boundary `canonical/015` covers only positively |
| `108` | the empty string as an object's **sole** key |
| `109` | empties **nested** — `[[],{},""]` |
| `999-deliberate-mismatch-empty` | §19.3 anti-vacuity **for this directory** |

⭐ **Why a SECOND deliberate mismatch.** `canonical/999` proves the harness detects a wrong
expectation *in `canonical/`*. ⛔ **A harness that read only `canonical/` would report green over an
entirely unscanned `valid-values/`** — and would keep doing so as this directory grows. This case is
how that is detected: it stores `[]` as the expectation for `{}`.

### ⛔ Where the expected bytes came from

**Hand-authored from RFC 8785. Not produced by any implementation.** §18 forbids importing
`Commonplace.Log.Jcs` as the implementation or comparing an implementation against itself, and
`commonplace-log`'s own README states *"implementations are never the source of expected bytes."*
Our encoder does not exist yet either. Every case here is deliberately trivial enough that the
canonical form is readable straight from the RFC: **no case needs key reordering** (0 or 1 keys),
**none needs number reformatting** (an integer inside the safe range), **none contains an escape.**

**Verified mechanically, with a positive control** — for exactly this batch, canonical output must
equal the input with insignificant whitespace removed, and must parse to the same JSON value:

```text
agreeing: 10   unexpected: 0        (999-* must DISAGREE; every other must agree)
positive control: expectation typo'd to "[] " -> agrees: False   (the checker catches it)
```

⚠️ **That property holds for this batch only.** ⛔ **Do not extend this directory with a case needing
reordering, escaping, or number reformatting and reuse the same justification** — such a case needs
its bytes derived some other way, and the check above would quietly stop meaning anything.

---

## `canonical/` — imported from `commonplace-log`, as DATA

**Source:** `~/commonplace-log/conformance/canonical-json/`, copied 2026-08-25.
**Verified:** `diff -r` against the source reported no differences — 19 cases, 38 files, byte-identical.
**Compliance re-checked here:** every `expected.hex` matches `^[0-9a-f]+$`; no `input.json` contains a
CR byte. 0 violations, and the checker was shown to reject an uppercase-hex file (positive control).

⛔ **§18 and §21 are explicit about what this import is and is not.**

> *"Version 0.1 SHOULD copy the language-neutral positive JCS vectors from `commonplace-log` and add
> its own negative and boundary vectors. It MUST NOT import `Commonplace.Log.Jcs` as its
> implementation or compare an implementation against itself."*

⇒ **These are BYTES. `Commonplace.Log.Jcs` is not a dependency, is not vendored, and is not the
oracle.** §21 forbids depending on `commonplace-log` outright. The differential byte check against
their canonicalizer happens over fixtures only, in round P5, and it is a **second opinion, never the
source of expected bytes.**

### File format

Each case is one directory containing exactly two files:

- **`input.json`** — the input, authoritative **as raw bytes**. A harness must read the bytes and
  parse them in its own runtime. ⚠️ **Some inputs are deliberately non-canonical** (whitespace,
  unsorted keys, `1.0` for `1`), which is the point — so a harness must parse them with a
  **permissive** parser, **never** with `Commonplace.Value.from_canonical_json/2`, which is required
  to reject exactly these.
- **`expected.hex`** — lowercase hex of the canonical output bytes. The trailing LF is file
  formatting, not encoded output.

### ⭐ The cases that are tripwires, not examples

| case | pins |
| --- | --- |
| `004-sort-astral-before-e000` | keys sort by **UTF-16 code units** — U+10000 encodes as `D800 DC00` and sorts **before** U+E000..U+FFFF, the opposite of code-point and UTF-8 byte order |
| `009-num-1e20` / `010-num-1e21` | the ECMAScript decimal/exponential switch. `1e20` spells out; `1e21` is `1e+21`, **with the `+`** |
| `011-num-1e-6` / `013-num-1e-7` | the other end of the same switch |
| `014-num-minus-zero` | `-0` emits `0` — 1 byte |
| `015-num-max-safe-int` | the §6.1 boundary |
| `018-float-spelled-integers` | `1.0` and `27.0` emit `1` and `27` — the case our own §6 normalization must agree with |
| `007-escape-u00xx-control` | controls as **lowercase** `\u00xx`. ⚠️ Elixir's stdlib `JSON.encode!/1` emits **uppercase** here (errata V2) |

### ⛔ `999-deliberate-mismatch` — the anti-vacuity fixture (§19.3)

Its `expected.hex` is **deliberately wrong**: it stores `{"b":2,"a":1}` where a correct
canonicalizer emits `{"a":1,"b":2}`.

> §19.3: *"The conformance harness MUST include at least one deliberately incorrect expected output
> and demonstrate that it is detected before the valid corpus may report green."*

⇒ **A harness that reports this case as matching is broken, and must fail the run.** ⭐ **The `9xx`
prefix is the convention: non-`9xx` cases must MATCH, `9xx` cases must MISMATCH.** A run in which
every case "passed" without the mismatch firing has proved nothing about the other 18.

### ⚠️ `017-whitespace-padded-entry` interacts with §13

Its `input.json` is **1,048,977 bytes** — mostly insignificant whitespace — canonicalizing to 327.
That is **larger than the default `max_bytes` of 1,048,576**, and §13 rule 1 measures `max_bytes`
**on canonical bytes for construction** but **directly on input bytes for canonical decoding**.
⇒ **As a construction vector it is 327 bytes and fits. As a decode vector it would be rejected on
size before anything else** — and it is not a decode vector, because it is not canonical.
⭐ **Recorded because the two measurements differ by three orders of magnitude on the same file**, and
a harness that used the wrong one would produce a confident, wrong result.

---

## Cross-repo note

`commonplace-log` states this corpus is *"a published contract rather than an internal test aid"* —
`commonplace-log-reducer` already holds its own canonicalizer to these bytes. ⇒ **We are now a third
consumer.** ⛔ **Byte-rule changes here must be announced, not made.** Additions of our own belong in
`valid-values/` and `invalid-values/`, which are ours.

---

## `differential/` — bytes from `commonplace-log`'s JCS, §18

**12 cases.** ⭐ **Their `expected.hex` was produced by a DIFFERENT implementation** —
`Commonplace.Log.Jcs` at `commonplace-log` `ecd329f` — run once, out of band, as an oracle.

> §18: *"For every value accepted by both packages, their canonical bytes MUST match."*
> §20.17 makes that an acceptance test.

### ⛔ How this stays inside §18 and §21

- **Their code never enters this repository.** The module (self-contained; `Jason` appears only in
  its moduledoc) was copied to a scratch directory *outside* the repo, compiled there, run, and
  discarded. **The artefact that landed is bytes, not code.**
- **Their repository was never touched** — no `mix` ran in it, no dependency of theirs was fetched.
- ⛔ **`commonplace-log` is not a dependency and must never become one** (§21).
- ⭐ **Their canonicalizer is a SECOND OPINION, never the oracle of record.** §18: *"neither package
  may infer complete substitutability from matching bytes on ordinary examples."*

### ⚠️ What a future disagreement MEANS

⛔ **A mismatch here is a FINDING about both packages — not an instruction to change ours.** The
hand-verified expectations in `canonical/` and `valid-values/` stay normative. Investigate which
implementation is wrong against RFC 8785 itself; **do not "fix" our encoder to match theirs, and do
not quietly regenerate these fixtures to make a red run green.**

### The shared domain, and what is deliberately outside it

The terms cover: nesting · astral-versus-BMP key ordering · every required escape · C0 controls ·
literal non-ASCII · the four number boundaries · safe-integer edges · integral floats and negative
zero · empty containers · 12-deep nesting · mixed ASCII key ordering · float precision.

⛔ **Integers outside ±(2^53−1) are deliberately EXCLUDED as inputs.** Their canonicalizer accepts
them; our §6.1 refuses them as Elixir integer inputs. ⭐ **They are outside the shared domain, so
§18's guarantee does not reach them and a fixture there would assert something neither spec
promises.**

### Verified at authoring time, with a positive control

```text
cases: 12   not agreeing: 0        VERDICT: PASS
positive control -- key ordering switched from UTF-16 to UTF-8 in our encoder:
cases: 12   not agreeing: 1        VERDICT: FAIL
```

⭐ **The control matters more than the result:** twelve agreements prove nothing unless the check can
report a disagreement, and this one can.

**Provenance:** oracle source sha256 `34a88979d1a975fa…`, `commonplace-log` at `ecd329f`,
recorded 2026-08-25.
