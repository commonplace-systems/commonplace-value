# IMPLEMENTATION PLAN — round P1: the value domain

**Work id: `VALUE-P1`. AND NO OTHER ID.**
**Round name, verbatim, as it appears in the dispatch prompt: `phase 1`.**

Other identifiers you may encounter, labelled by their ROLE so they are not mistaken for this
round's citation:

| shape | example | role — **not** this round's id |
| --- | --- | --- |
| the spec | `docs/proposals/2026-08-24-commonplace-value-spec.md` | **what you are building against**, never edited |
| bootstrap commit | `aac51f9` | the sha the spec landed at — a commit sha, not a ticket |
| future rounds | `VALUE-P2` … `VALUE-P5` | **planned, not this round.** Their arms are `ARM-PLANNED` elsewhere and stay that way |
| sibling repos | `commonplace-log`, `commonplace-doc`, `commonplace-doc-sync` | peers. `commonplace-log` is a **fixture donor in P5**, never a dependency (§21) |
| fleet rulings | `#25` | *Sol implementers run in tmux panes* — about WHERE you run, not about the work |

⭐ **If you need an id and only have those, that is a bug in my prompt: use `VALUE-P1` and say I
under-specified it.**

---

## 1. The ask

Build the **value domain** of `commonplace-value`: strict recursive validation and normalization of
an Elixir term into the portable domain, with RFC 6901 paths and structured errors.

⛔ **NOT in this round: the encoder, the `%Commonplace.Value{}` struct, and the entire §14 public API.**
See `docs/spec-errata.md` **V1** for why they cannot be here — §9 makes canonical bytes the
identity-bearing representation and §13.1 measures `max_bytes` on canonical bytes, so no honest
struct exists before the encoder. This round delivers `Commonplace.Value.Domain`, an **internal**
module.

⛔ **NOT in this round: resource-limit accounting.** That is P2, with boundary cases at one-below,
exact, and one-above (§19.2). This round must **not** implement depth/node/member counting; a term
of any size is accepted here if its *types* are portable.

---

## 2. Scope, as a property — not a denylist

⭐ **An enumeration is satisfiable by anything not on the list.** So the scope statement is:

> **Every module this round creates under `lib/` is declared by a `MODULE:` marker below, and
> `bin/check-plan-arms.sh` FAILS on any module in `lib/` that is not.**

<!-- MODULE: Commonplace.Value.Limits -->
<!-- MODULE: Commonplace.Value.Error -->
<!-- MODULE: Commonplace.Value.Pointer -->
<!-- MODULE: Commonplace.Value.Domain -->

| module | file | responsibility |
| --- | --- | --- |
| `Commonplace.Value.Limits` | `lib/commonplace/value/limits.ex` | **already exists.** §13 defaults. This round adds validation of caller-supplied limits (`:invalid_limits`) and nothing else |
| `Commonplace.Value.Error` | `lib/commonplace/value/error.ex` | the §15 struct: `operation`, `reason`, `path`, `limit`, `actual` |
| `Commonplace.Value.Pointer` | `lib/commonplace/value/pointer.ex` | RFC 6901 JSON Pointer rendering from a reversed path stack |
| `Commonplace.Value.Domain` | `lib/commonplace/value/domain.ex` | `validate/2` — the strict recursive validator and normalizer |

⚠️ **Adding a module is fine. Adding one SILENTLY is not.** If this round genuinely needs a module
not on that list, **add the `MODULE:` marker in this file as part of your diff and say so in your
report.** Two sibling repos found unbriefed machinery within an hour of their first round; that is
what this property exists for.

---

## 3. The interface this round delivers

```elixir
@spec Commonplace.Value.Domain.validate(term(), keyword()) ::
        {:ok, normalized_term()} | {:error, Commonplace.Value.Error.t()}
```

`opts` accepts `:limits` (a `%Commonplace.Value.Limits{}`); this round uses it only to **validate**
the limit set (§13 rule 5, rule 6) and returns `:invalid_limits` when it is bad. **It does not yet
enforce any limit.**

`normalized_term()` is §5's type, verbatim:

```elixir
@type normalized_term ::
        nil | boolean() | integer() | float() | String.t()
        | [normalized_term()] | %{String.t() => normalized_term()}
```

---

## 4. MEASURED — facts I ran on this host, with the command

Not inherited, not remembered. `elixir 1.18.4 / OTP 27`, pinned in `.tool-versions`.

| command | result | why this round cares |
| --- | --- | --- |
| `Code.ensure_loaded?(JSON)` | `true` | stdlib `JSON` exists; **this package has ZERO runtime deps.** You need no parser in P1 at all |
| `:erlang.float_to_binary(f, [:short])` | shortest round-trip digits | ⛔ **not needed in P1.** Listed so you do not reach for it |
| `sha256sum docs/proposals/…-spec.md` | `1ac9a437…` | `bin/check-spec-pristine.sh` is green and **has been demonstrated red** (`docs/STATE.md` §2) |
| `bash bin/check-plan-arms.sh` | see §8 | the gate you will turn red as your first step |

⚠️ **What I did NOT measure, and you must not assume:** whether `is_struct/1`, `is_function/1`,
`is_reference/1` and friends distinguish every §5.1 category cleanly. **A tuple is not a struct; a
struct IS a map; a port is not a reference; an improper list is not a list to `is_list/1` — it is.**
Prove each with a test, not with a guard you believe in.

---

## 5. INHERITED — carried as behaviours, not as types

- `commonplace-log` owns a frozen JCS canonicalizer and a 19-case conformance corpus at
  `~/commonplace-log/conformance/canonical-json/`. ⛔ **P1 does not touch it.** §18/§21 forbid the
  dependency outright; the corpus arrives as **copied fixture bytes** in P3 and the differential
  check is P5.
- `commonplace-doc` and `commonplace-doc-sync` supplied the round machinery in `bin/`. ⛔ **Do not
  edit `bin/`** — those scripts are gates, and `~/boss-clod/sol-egress-run.sh` is boss-clod's.

---

## 6. Required arms

⭐ **YOUR FIRST DONE STEP IS TO PROMOTE EVERY `ARM-PLANNED:` BELOW TO `ARM:`.** That turns
`bin/check-plan-arms.sh` **red with ~28 missing** in your worktree. **The round is finished when it is
green because the tests exist under exactly these names** — the marker is the contract, so name the
test to match the marker, never the other way round.

⚠️ **Per arm, in your report: name the mutation that turned it RED.** Remove the guard in `lib/`,
paste the failure line, restore. ⛔ **Use `bin/mutate.sh` for this — never `git checkout --`,
`reset`, or `stash` in this worktree; your own uncommitted work is the thing they erase.**
⭐ **VACUITY HATCH: if you cannot construct a mutation that makes an arm fail, SAY SO in the report
and leave it red.** An arm that cannot go red is a finding, not a chore — reporting it is the
correct outcome, and silently writing a test that always passes is the failure this round is shaped
to avoid.

### 6.1 Limits validation — spec §13 rules 5 and 6

<!-- ARM: default limits match the specification table -->
<!-- ARM-PLANNED: limits validation accepts the default limit set -->
<!-- ARM-PLANNED: limits validation rejects a zero or negative bound with :invalid_limits -->
<!-- ARM-PLANNED: limits validation rejects a non-integer bound with :invalid_limits -->
<!-- ARM-PLANNED: limits validation rejects :infinity for any bound with :invalid_limits -->

⭐ **The green arm is the one that gets forgotten.** §13's rules mostly *permit*; a validator that
rejects every limit set passes all three negative arms. `limits validation accepts the default limit
set` is why the first arm above is not decoration.

### 6.2 RFC 6901 pointers — spec §15

<!-- ARM-PLANNED: pointer for the top level value is the empty string -->
<!-- ARM-PLANNED: pointer uses decimal segments for array indices -->
<!-- ARM-PLANNED: pointer escapes tilde as ~0 and slash as ~1 in object keys -->

⚠️ RFC 6901 order matters: `~` is escaped **before** `/`. A key `a~/b` renders `a~0~1b`, not
`a~01b`. **Write that exact key as the test input** — the two implementations differ only on it.

### 6.3 The accepted domain — spec §5

<!-- ARM-PLANNED: domain accepts nil and true and false -->
<!-- ARM-PLANNED: domain accepts a UTF-8 string including astral plane characters -->
<!-- ARM-PLANNED: domain accepts an empty list an empty map and an empty string key -->
<!-- ARM-PLANNED: domain accepts nested lists and maps recursively -->

### 6.4 The rejected categories — spec §5.1, each with its reason AND its path

<!-- ARM-PLANNED: domain rejects an atom other than nil true false with :atom_not_allowed -->
<!-- ARM-PLANNED: domain rejects a tuple with :tuple_not_allowed -->
<!-- ARM-PLANNED: domain rejects a struct with :struct_not_allowed -->
<!-- ARM-PLANNED: domain rejects a struct that derives the JSON encoder protocol -->
<!-- ARM-PLANNED: domain rejects a pid a reference and a port with :runtime_reference_not_allowed -->
<!-- ARM-PLANNED: domain rejects a function with :unsupported_term -->
<!-- ARM-PLANNED: domain rejects an improper list with :improper_list -->
<!-- ARM-PLANNED: domain rejects a map with a non-string key with :non_string_key -->
<!-- ARM-PLANNED: domain rejects a non-UTF-8 binary with :invalid_utf8 -->
<!-- ARM-PLANNED: domain rejects a non-UTF-8 object key with :invalid_utf8 -->
<!-- ARM-PLANNED: domain rejects a bitstring that is not a binary -->
<!-- ARM-PLANNED: domain reports the exact path of a deeply nested rejected term -->

⭐ **§20.13 is a named acceptance test and it is the interesting one:** *structs remain rejected even
when they implement a JSON encoder.* §5.1's closing line — *"No protocol implementation may make a
rejected Elixir term portable"* — is a claim about a **negative**, and the only way to hold it is a
struct that actually derives `JSON.Encoder` sitting in the test support tree and still being
rejected. ⚠️ **A struct that merely exists proves nothing here; it must be encodable.**

⭐ **§20.14: a nested PID, function, reference, tuple, or atom must fail at its EXACT path.** The
arm above is `domain reports the exact path of a deeply nested rejected term`; assert the pointer
string, e.g. `/a/0/b~1c/2`, not merely that an error occurred. ⚠️ **An error at the wrong path is a
test that passes for the wrong reason, and every downstream reader will keep agreeing with it.**

### 6.5 Numbers — spec §6.1, §6.2, and errata V5

<!-- ARM-PLANNED: domain accepts the maximum safe positive and negative integers -->
<!-- ARM-PLANNED: domain rejects an integer one above the maximum safe integer with :integer_out_of_range -->
<!-- ARM-PLANNED: domain rejects an integer one below the minimum safe integer with :integer_out_of_range -->
<!-- ARM-PLANNED: domain rejects NaN and positive and negative infinity with :non_finite_number -->
<!-- ARM-PLANNED: domain normalizes negative zero to positive zero -->
<!-- ARM-PLANNED: domain normalizes an integral float to an integer -->
<!-- ARM-PLANNED: domain leaves a non integral float as a float -->
<!-- ARM-PLANNED: domain rejects a float whose integral value is outside the safe range -->

The safe range is `-(2^53 - 1) .. +(2^53 - 1)` = `-9_007_199_254_740_991 .. 9_007_199_254_740_991`.
**Boundaries at exact and one-above/one-below, both signs.** Errata **V5** is the record of the
normalization choice: integral finite floats inside the safe range become integers, `-0.0` becomes
`0`.

⚠️ **`domain rejects a float whose integral value is outside the safe range` is the subtle one.**
`1.0e20` is a finite float, mathematically integral, and **outside** the safe integer range.
§6.1 constrains *integer inputs*; §6.3 says decoding **may** yield a float there. ⇒ **For a float
INPUT, keep it a float** — do not convert, do not reject. **This arm asserts the term stays
`1.0e20` as a float.** If you read the spec as requiring something else, ⭐ **stop and say so in the
report rather than choosing** — this is a normative boundary and I would rather be told than have it
decided inside a fence.

### 6.6 Errors — spec §15

<!-- ARM-PLANNED: error does not reproduce the rejected value -->

§15: *"Errors MUST NOT inspect or reproduce the complete rejected value."* ⭐ **Make the arm real:
construct a term containing a distinctive secret string, reject it, and assert the secret appears
nowhere in the error struct, its `Exception.message/1`, or its `inspect/1` output.** ⚠️ A test that
only checks `error.reason` passes whether or not the secret leaked.

---

## 7. What I do NOT want

- ⛔ any change under `bin/`, `docs/proposals/`, `README.md`, `mix.exs` deps, or `.tool-versions`;
- ⛔ any new runtime dependency — **this package has zero and that is a feature** (§21);
- ⛔ `Commonplace.Value` itself, `new/2`, `encode/1`, `to_term/1`, `equal?/2`, `Inspect`, or the
  struct;
- ⛔ limit **enforcement** (P2), the encoder (P3), decoding (P4);
- ⛔ line-rewrapping, formatting migrations, or refactors of code you did not write.
  ⭐ **The test for an out-of-brief change is not "was it licensed" — it is "is this round's goal
  unachievable without it."**

---

## 8. Acceptance — commands, with their expected output

Run from the worktree root. ⛔ **Never pipe a gate into `tail` from a shell without `pipefail`** —
the pipeline's status becomes `tail`'s and a FAIL reads as 0.

```bash
mix format --check-formatted     # expect: no output, rc 0
mix compile --warnings-as-errors # expect: rc 0
mix test                         # expect: 0 failures
for s in 1 2 3 4 5; do mix test --seed $s; done   # expect: 0 failures, five times
bash bin/check-plan-arms.sh      # expect last line: VERDICT: PASS -- every declared arm exists.
bash bin/check-plan-arms.sh --self-test   # expect: SELF-TEST PASS
bash bin/check-spec-pristine.sh  # expect last line: VERDICT: PRISTINE
```

**Corpus counts before believing any zero** (⛔ *a grep against a path that does not exist returns 0
hits and looks exactly like a confirmed absence*):

```bash
grep -rc 'defmodule' lib/ | sort          # expect 4 files, non-zero each
grep -rho '^\s*test "[^"]*"' test/ | wc -l  # expect >= 34
```

---

## 9. Gate demonstrations owed by ME, not by this round

⭐ *A gate never seen fail is not known to work.* Recorded in `docs/STATE.md` §2.

| gate | green | red |
| --- | --- | --- |
| `check-spec-pristine.sh` | ✅ done | ✅ done via `bin/mutate.sh` |
| `check-plan-arms.sh` | owed at P1 landing | owed — promote one arm with no test |
| `check-plan-arms.sh --self-test` | owed at P1 landing | ✅ built in |
| `land-round.sh` refuses off-main | owed | owed |

---

## 10. Report — what to send back

1. **Per arm: the mutation that turned it red, and the pasted failure line.** Arms with no possible
   mutation: say so explicitly.
2. Every module you created, and whether it is on the `MODULE:` list above.
3. Anything in §6.5's float boundary you had to decide rather than read.
4. The output of every command in §8, verbatim.
5. ⚠️ **If compile or deps fail inside the fence, STOP and report with the headline
   `compile blocked in fence`.** There is no network in there and that is expected, not your bug.
6. ⚠️ **You probably cannot commit** — `.git` is mounted read-only in the fence. **That is normal.**
   Leave the work in the tree; I commit on your behalf. ⛔ **Do not try to work around it, and do not
   run `git checkout --`, `git reset`, or `git stash` to tidy anything.**
