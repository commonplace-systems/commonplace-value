# IMPLEMENTATION PLAN — round P2: resource limits

**Work id: `VALUE-P2`. AND NO OTHER ID.**
**Round name, verbatim, as it appears in the dispatch prompt: `phase 2`.**

| shape | example | role — **not** this round's id |
| --- | --- | --- |
| the spec | `docs/proposals/2026-08-24-commonplace-value-spec.md` §13 | **what you are building against**, never edited |
| the previous round | `VALUE-P1`, landed at `6bbea45` | **precedent, and the code you extend.** Not this round |
| future rounds | `VALUE-P3` … `VALUE-P5` | planned. Their arms stay `ARM-PLANNED` |
| errata | `V1` … `V7` | amendments explaining WHY. **V7 is about P1's retired arm, not about your work** |
| sibling repos | `commonplace-cell`, `commonplace-doc` | consumers and peers, never dependencies |

⭐ **If you need an id and only have those, that is a bug in my prompt: use `VALUE-P2` and say I
under-specified it.**

---

## 1. The ask

Make `Commonplace.Value.Domain.validate/2` **bounded**. Spec §13: *"Validation and decoding occur at
trust boundaries and MUST be bounded."*

Today `validate/2` accepts a limit set, validates it, and then **enforces nothing**. This round makes
every limit in `%Commonplace.Value.Limits{}` real **except `max_bytes`**.

⛔ **`max_bytes` IS NOT IN THIS ROUND.** §13 rule 1 measures it *on canonical bytes*, and the encoder
does not exist until P3. Its arm is `ARM-PLANNED` in §6.7 below and **must stay that way.**

---

## 2. Scope, as a property

> **Every module this round creates under `lib/` is declared by a `MODULE:` marker below, and
> `bin/check-plan-arms.sh` FAILS on any module in `lib/` that is not.**

<!-- MODULE: Commonplace.Value.Limits -->
<!-- MODULE: Commonplace.Value.Error -->
<!-- MODULE: Commonplace.Value.Pointer -->
<!-- MODULE: Commonplace.Value.Domain -->

⭐ **The expected diff creates NO new module.** Enforcement belongs inside `Domain`'s existing walk
and `Error`'s existing `limit`/`actual` fields. If you believe a new module is required, **add the
`MODULE:` marker here in the same diff and say so in your report** — adding one is fine, adding one
silently is not.

**Test support may live under `test/support/` and needs no marker** (the gate reads `lib/` only).
⚠️ **That exemption is a corpus-scope accident, not a licence** — do not hide production logic there.

---

## 3. MEASURED — facts I ran on this host

| command | result | consequence |
| --- | --- | --- |
| `mix test` at `6bbea45` | `34 tests, 0 failures` | the baseline you extend is green |
| `mix deps.get` | `stream_data 1.4.0` | **already fetched and compiled on the host.** §21 permits test-only tooling |
| `ps -eo pgid,args \| grep '[c]odex exec'` | 2 rounds in flight at brief time | why this round waited for a slot |

⚠️ **What I did NOT measure and you must not assume:** how deep a term Elixir can build before the
walk blows the stack. §13 rule 7 requires depth to be checked **before** work likely to exhaust the
VM, and the current walk in `Domain` is **not** tail-recursive. ⭐ **Measure it, and report the
number you measured.**

---

## 4. The rules, verbatim from §13, with the reading you must implement

1. `max_bytes` — canonical bytes for construction. ⛔ **Not this round.**
2. **The top-level value has depth 0. Entering an array or object increases depth by one.**
3. `max_nodes` counts **every scalar, array, object, and member value visited**.
4. **String limits are measured in UTF-8 bytes**, not graphemes or code points.
5. Limit values must be positive finite integers. ✅ *done in P1.*
6. No option may disable limits with `:infinity`. ✅ *done in P1.*
7. **Depth and input byte limits MUST be checked before performing work likely to exhaust the VM.**

⚠️ **TWO READINGS I AM STATING SO YOU DO NOT HAVE TO GUESS — and where I could be wrong, say so:**

- **Rule 3, what counts as a node.** The wording lists *"every scalar, array, object, and member
  value visited"* — a member value is already a scalar/array/object, so a naive reading
  double-counts. ⇒ **Implement it as: each visited term is one node, counted once.** A map of one
  string key to one integer is 2 nodes (the map, the integer), not 3.
- **Rule 4, whether object KEYS are subject to `max_string_bytes`.** §13.4 says "string limits";
  keys are strings under §5. ⇒ **Implement it as: keys are subject to it too.**
  ⭐ **Both readings are mine, not the spec's.** If either looks wrong from inside the code, ⛔ **stop
  and say so in the report rather than deciding it in the fence.** A wrong reading here is a
  protocol surface (§22 makes a default-limit change that rejects previously valid traffic a
  **breaking** change), so I would rather be told.

---

## 5. Required arms

⭐ **FIRST DONE STEP: promote every `ARM-PLANNED:` in §6.1–§6.6 to `ARM:`.**

⚠️ *This brief originally said 21. §§6.1–6.6 hold `4 + 3 + 4 + 4 + 3 + 4 = 22`; the round's
implementer counted them and said so. **The markers are the contract, not my arithmetic about them**
— corrected here rather than left as a number a future reader would trust.* That turns the gate red
with **22** missing. ⛔ **§6.7 stays `ARM-PLANNED`** — it belongs to P3 and promoting it makes `main`
permanently red, which is how a gate becomes ignored.

⚠️ **Per arm: the mutation that turned it red, via `bin/mutate.sh`.** ⛔ Never `git checkout --`,
`reset`, or `stash` here.
⭐ **VACUITY HATCH: if an arm cannot be made to fail, SAY SO and leave it red.** P1's round did
exactly that and it was the most valuable thing it produced (errata V7). **A round that ends red for
a named reason beats one that ends green.**

### 5.1 Boundaries are tested at ONE-BELOW, EXACT, and ONE-ABOVE

§19.2 requires *"every resource limit at one-below, exact, and one-above boundaries."*
⭐ **The one-below and exact cases are the arms that get forgotten, and they are the ones that catch
an off-by-one that rejects valid traffic** — the failure §22 calls breaking. A limit checker that
rejects everything passes every one-above arm.

### 6.1 Depth — §13 rule 2

<!-- ARM: domain counts the top level scalar as depth zero -->
<!-- ARM: domain accepts nesting at exactly max_depth -->
<!-- ARM: domain rejects nesting one level beyond max_depth with :max_depth_exceeded -->
<!-- ARM: domain checks depth before walking a term deep enough to exhaust the stack -->

⚠️ The last one is §13 rule 7 and is **not** satisfied by rejecting after the walk. Build a term far
deeper than `max_depth` — deeper than the number you measured in §3 — and assert the error comes back
rather than the VM dying. ⭐ **If the current non-tail-recursive walk cannot do this without being
restructured, restructuring it IS in scope: the round's goal is unachievable without it.**

### 6.2 Nodes — §13 rule 3

<!-- ARM: domain accepts a term with exactly max_nodes nodes -->
<!-- ARM: domain rejects a term with one node beyond max_nodes -->
<!-- ARM: domain node count matches an independent recount of the same term -->

⭐ **The third arm is the anti-vacuity one and it must not reuse the counter under test.** Write the
recount in the test as an obviously-correct recursive walk, and compare. ⚠️ *An implementation
compared against itself agrees perfectly and proves nothing* — spec §18 says the same thing about
canonicalizers.

### 6.3 Strings — §13 rule 4

<!-- ARM: domain accepts a string of exactly max_string_bytes -->
<!-- ARM: domain rejects a string one byte beyond max_string_bytes -->
<!-- ARM: domain measures string limits in UTF-8 bytes rather than graphemes -->
<!-- ARM: domain applies max_string_bytes to object keys as well as values -->

⭐ **The graphemes arm needs a string where the three counts genuinely differ.** A family emoji
(`👨‍👩‍👧‍👦`) is 1 grapheme, 7 code points, 25 UTF-8 bytes. ⚠️ A test using ASCII passes under all
three readings and therefore measures nothing.

### 6.4 Containers — §13

<!-- ARM: domain accepts an object with exactly max_object_members -->
<!-- ARM: domain rejects an object with one member beyond max_object_members -->
<!-- ARM: domain accepts an array with exactly max_array_elements -->
<!-- ARM: domain rejects an array with one element beyond max_array_elements -->

### 6.5 The error carries the numbers — §15

<!-- ARM: limit errors report both the limit and the actual value -->
<!-- ARM: limit errors report the JSON Pointer path of the offending container -->
<!-- ARM: limit errors do not reproduce the rejected value -->

⭐ The third repeats P1's secret discipline **at the limit path specifically**, because a limit error
is the one most tempted to say *"string of 1048577 bytes: <the string>"*. Use a distinctive secret
and assert it appears in neither the struct, `Exception.message/1`, nor `inspect/1`.

### 6.6 Caller-supplied limits, and properties — §13, §20

<!-- ARM: domain honours a stricter caller supplied limit set -->
<!-- ARM: domain honours an explicitly larger finite caller supplied limit set -->
<!-- ARM: property every generated portable term within limits is accepted -->
<!-- ARM: property every generated term exceeding a limit is rejected with that limit reason -->

⭐ **The "explicitly larger" arm is the green arm of §13's opening sentence** — *"The defaults apply
unless the caller supplies a stricter **or explicitly larger** finite limit set."* An enforcer that
ignores `opts` and always uses the defaults passes every stricter-limit arm. ⚠️ **For a rule that
PERMITS, the missing arm is the green one.**

Generators go in `test/support/`; bound them so the suite stays fast.

### 6.7 ⛔ NOT THIS ROUND — leave as `ARM-PLANNED`

<!-- ARM: construction rejects a term whose canonical bytes exceed max_bytes -->

§13 rule 1 needs the encoder. **P3.**

---

## 7. What I do NOT want

- ⛔ any change under `bin/`, `docs/proposals/`, `README.md`, `.tool-versions`, or `mix.exs` deps
  (`stream_data` is already there and already fetched — **do not run `mix deps.get`**);
- ⛔ the encoder, the struct, `new/2`, `encode/1`, `to_term/1`, `equal?/2`, `Inspect`, decoding;
- ⛔ `max_bytes` enforcement;
- ⛔ raising a default limit, or adding an option that disables one;
- ⛔ rewrapping or reformatting code you did not write.
  ⭐ **The test for an out-of-brief change is not "was it licensed" — it is "is this round's goal
  unachievable without it."** By that test, restructuring the walk for §13 rule 7 **passes**.

---

## 8. Acceptance

```bash
mix format --check-formatted           # no output, rc 0
mix compile --warnings-as-errors       # rc 0
mix test                               # 0 failures
for s in 1 2 3 4 5; do mix test --seed $s; done
bash bin/check-plan-arms.sh            # last line: VERDICT: PASS
bash bin/check-plan-arms.sh --self-test
bash bin/check-spec-pristine.sh        # last line: VERDICT: PRISTINE
```

**Count the corpus before believing any zero:**

```bash
grep -rho '^defmodule [A-Za-z0-9_.]*' lib/ | sort   # expect exactly the 4 declared modules
grep -rho '^\s*test "[^"]*"' test/ | wc -l          # expect >= 55
```

---

## 9. Report

1. **Per arm: the mutation that turned it red**, the pasted failure line, and confirmation the
   mutation perturbed the axis the arm measures. ⚠️ *An inert mutation is indistinguishable from a
   gate that works* — `bin/mutate.sh` refuses a no-diff mutation, but a mutation that changes a line
   nothing reads is still inert.
2. **The measured stack depth** from §3, and whether the walk needed restructuring.
3. **Either reading in §4 you disagree with** — findings, not quiet fixes.
4. Any module created, and whether it was on the `MODULE:` list.
5. Verbatim output of every command in §8.
6. ⚠️ **`compile blocked in fence` as the headline if compile or deps fail** — no network in there.
7. ⚠️ **You probably cannot commit** (`.git` read-only). Leave the work in the tree and say so.
