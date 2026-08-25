# commonplace-value

The values Commonplace permits to cross authority, persistence, process, language, and network
boundaries.

> **A successfully constructed `Commonplace.Value` is inert, JSON-equivalent data with one
> deterministic RFC 8785 canonical byte representation.**

Elixir, **zero runtime dependencies**. Spec: `docs/proposals/2026-08-24-commonplace-value-spec.md`
(jes's, never edited, gate-pinned). Design correction:
`docs/proposals/2026-08-25-value-composition-ruling.md` (likewise).

## Public API — §14, and it is deliberately small

```elixir
Commonplace.Value.new(term, opts \\ [])                 # {:ok, t} | {:error, Error.t}
Commonplace.Value.compose(composable_term, opts \\ [])  # existing Values as atomic leaves
Commonplace.Value.from_canonical_json(bytes, opts \\ [])# canonical bytes only; rejects, never repairs
Commonplace.Value.encode(value)                         # RFC 8785 canonical bytes
Commonplace.Value.to_term(value)                        # the normalized term
Commonplace.Value.equal?(left, right)                   # canonical BYTE equality
```

| door | input | existing Values as leaves |
| --- | --- | --- |
| `new/2` | an ordinary, untrusted Elixir term | ⛔ **rejected** — including `%Commonplace.Value{}` itself |
| `compose/2` | an explicit composition template | ✅ accepted as atomic leaves |
| `from_canonical_json/2` | untrusted **canonical bytes** | fully decoded and validated |

⭐ **The distinction is visible at the call site on purpose.** Reach for `new/2` when you mean
untrusted input and `compose/2` when you mean composition.

⛔ **There is deliberately no API for:** permissive JSON parsing · schema validation · atomizing keys
· automatic binary tagging · mutating a value · constructing messages · authorization · routing ·
hashing without a consumer-selected domain. §22 makes additions to this surface protocol-breaking.

## Status — 0.1 planned rounds complete

| | |
| --- | --- |
| tests / declared arms | **156 / 155**, green on five seeds |
| modules in `lib/` | 9, every one declared in a plan |
| conformance corpus | **63 cases** across 4 directories |
| runtime dependencies | **0** |
| spec §20 acceptance | ⭐ **all twenty items have a NAMED arm** |
| spec §24 completion | ⛔ **NOT fully met — see below** |

### ⛔ What is NOT demonstrated, stated plainly

- **Two implementations agreeing on every pinned *rejection* (§24).** `Commonplace.Log.Jcs` is a
  canonicalizer, not a validator carrying this package's accepted domain, so no second
  implementation's rejection results exist to compare against. **Closing this needs a second
  implementation of §5/§6/§11 — not more tests here.**
- **"Small enough to audit directly" (§24).** The module gate proves nine declared modules; that is
  a proxy for size, **not a measurement of auditability**.
- ⚠️ **The boundary proof is COOPERATIVE, not adversarial.** §17 and ruling §8.1: this package cannot
  stop arbitrary Elixir code sharing a BEAM VM from bypassing a router with `send/2`, and opacity is
  not a cryptographic seal. The arms prove what can cross **through the value API**.

Full assessment: `docs/spec-errata.md` **V15**.

## How this repository works

⭐ **A claim about the spec and a claim about the code are different claims.**

- `docs/proposals/*` and `docs/spec-errata.md` state **design** claims only.
- ⛔ A statement about what the **code** does **must cite a test by name**.
- ⚠️ Nothing here says "implemented" without naming the arm that would go red.

Filed, not remembered — `bin/check-plan-arms.sh` fails on any plan-declared arm with no matching
test, and on any module in `lib/` no plan declares. Four gates sit on the path to `main`; each has
been demonstrated **red and green**, and the landing script's own refusal is itself a test
(`bin/check-landing-refuses.sh`, hermetic, in a scratch repo).

**Read `docs/STATE.md` first.** It carries the method, the round machinery, the traps others paid
for, and the measured toolchain facts — including why `JSON.encode!/1` cannot be the canonical
encoder.

## The conformance corpus is the product

```text
conformance/
├── canonical/        19  RFC 8785 vectors imported from commonplace-log (§18)
├── valid-values/     10  ours — the scalar and empty-container gaps §19.1 requires
├── invalid-values/   22  ours — rejection vectors with reason slugs (§19.2)
└── differential/     12  bytes emitted by commonplace-log's JCS, recorded out of band
```

⛔ **Each directory has its own door, and using the wrong one costs a false failure** — the table is
in `conformance/README.md`, and the reason is errata **V13**.

⭐ **Three deliberate fixtures, and they are not the same shape.** Two expect a **mismatch**;
`invalid-values/999-deliberate-acceptance` expects an **acceptance**, because a rejection harness
that rejects *everything* passes every other case in that directory. **Ask of each directory: what
would a lazy harness do, and which fixture catches it?**

⛔ `commonplace-log` is a **fixture donor and never a dependency** (§18, §21). Its canonicalizer is a
second opinion, never the oracle of record; a differential mismatch is a **finding about both
packages**, not a licence to regenerate a fixture.

## Boundaries

⛔ This package **must not** define Cell request fields, browser payloads, Markdown values, or Yjs
binary framing, and **must not** depend on `commonplace-log`, reducers, `commonplace-doc`,
`commonplace-dir`, `commonplace-doc-sync`, or any Cell, Realm, or capability implementation (§21).

⚠️ §5.3: a non-UTF-8 binary is **rejected**. A protocol needing raw bytes must define an explicit
representation itself — this package does not interpret or privilege any tagging shape.

## Working arrangement (jes, 2026-08-25T03:32Z)

- **Toplevel model: Opus 5.** **Implementers: Sol, in tmux panes** — ruling #25.
- The dispatch recipe is in `docs/STATE.md` §3, from `commonplace-doc` and `commonplace-doc-sync`.
- ⚠️ The fleet cap is **2 concurrent Sol rounds**. A refused dispatch is the cap working.

`boss-clod/REPO-BOUNDARIES.md` holds the standing rulings; hand it to anyone starting here.
