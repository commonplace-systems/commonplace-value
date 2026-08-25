# Conformance corpus — `commonplace-value`

Spec §19. ⭐ **This corpus is the product, not the test aid.** A value that passes every structural
check and encodes to different bytes on two machines is the exact defect this package exists to
prevent, and no structural check can see it.

```text
conformance/
├── canonical/        RFC 8785 canonicalization vectors  (imported, §19.1)
├── valid-values/     portable-value acceptance vectors  (this repo's, to come)
└── invalid-values/   rejection vectors with reason slugs (this repo's, to come)
```

⚠️ **`valid-values/` and `invalid-values/` are EMPTY at the time of writing** and are ours to fill —
see `docs/IMPLEMENTATION-PLAN-P3.md` onward. ⛔ **An empty directory and a passing corpus are
indistinguishable to a harness that does not count.** Any harness reading these MUST assert a
non-zero case count before reporting green.

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
