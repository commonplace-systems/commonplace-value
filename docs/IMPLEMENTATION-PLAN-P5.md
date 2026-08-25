# IMPLEMENTATION PLAN — round P5: `compose/2`

**Work id: `VALUE-P5`. AND NO OTHER ID.**
**Round name, verbatim, as it appears in the dispatch prompt: `phase 5`.**

| shape | example | role — **not** this round's id |
| --- | --- | --- |
| **the ruling** | `docs/proposals/2026-08-25-value-composition-ruling.md` | ⭐ **THIS ROUND IS THE RULING. Its §11 is your arm list, §5–§9 your contract.** Never edited, gate-pinned |
| the spec | `docs/proposals/2026-08-24-commonplace-value-spec.md` | never edited either. §5, §13, §14 still bind |
| previous rounds | `P1` `6bbea45` · `P2` `ce51ba8` · `P3` `31e43e9` · `P4` `32f8bba` | the code you extend |
| `VALUE-P6` | determinism + differential vs `Commonplace.Log.Jcs` | **not this round** |
| errata | `V6` (the ruling's own entry) · `V8` (why P5 is here) | why |
| the goal doc | `~/boss-clod/GOAL-markdown-workspace-editor-cell.md` §21.10 | ⚠️ **context, not a task.** It asks for exactly this round and adds nothing |
| `commonplace-cell` | pinned at `32f8bba`; their envelope is your §12 fixture | a consumer, not a dependency |

⭐ **If you need an id and only have those, that is a bug in my prompt: use `VALUE-P5` and say I
under-specified it.**

---

## 1. The ask

```elixir
@spec compose(composable_term(), keyword()) :: {:ok, t()} | {:error, Error.t()}
def compose(term, opts \\ [])
```

A **checked** composition constructor accepting the ordinary portable grammar **plus an existing
`Commonplace.Value.t()` as an atomic value leaf**. It validates every newly introduced raw term and
container, and **does not recursively revalidate the contents of an embedded Value**.

⛔ **`new/2` DOES NOT CHANGE.** Ruling §3: it must keep rejecting every struct, **including
`%Commonplace.Value{}`**. P3's arm `new rejects a Commonplace.Value struct as an ordinary term` must
stay green. ⭐ **That arm is the guard against the most natural mistake this round invites.**

⛔ **No `unsafe_new`, no `from_parts`, no public struct-field constructor** (ruling §10.4).

---

## 2. Scope, as a property

<!-- MODULE: Commonplace.Value -->
<!-- MODULE: Commonplace.Value.Composer -->
<!-- MODULE: Commonplace.Value.Encoder -->
<!-- MODULE: Commonplace.Value.Decoder -->
<!-- MODULE: Commonplace.Value.Metrics -->
<!-- MODULE: Commonplace.Value.Domain -->
<!-- MODULE: Commonplace.Value.Error -->
<!-- MODULE: Commonplace.Value.Limits -->

`Commonplace.Value.Composer` is the only new one.

---

## 3. ⭐ THE CONTRACT — ruling §9, and it is the whole safety story

> For every valid composition template, composition MUST be **observably equivalent** to fully
> expanding its child Values and calling `new/2`: same `encode/1` bytes, same `equal?/2`, same
> `to_term/1`. **Composition MUST NOT introduce a second equality, normalization, number, Unicode,
> object-ordering, or canonical-encoding model.**

⇒ **There is not a fast path with its own semantics. There is one semantics reached two ways.**
⭐ **Every arm in §6.3 below is that sentence, made falsifiable.**

### How it is possible at all — ruling §5

Every constructed Value already carries (landed in P3): canonical bytes · normalized term · encoded
byte length · node count · maximum internal depth · maximum string byte length · maximum object
member count · maximum array element count · representation version.

⭐ **Ruling §5, last paragraph, is the implementation key:** *"Canonical child bytes may be embedded
as already canonical JSON fragments. The composer must still emit new container punctuation and
canonically ordered new object keys."* ⇒ **You are splicing verified byte blobs into freshly emitted
punctuation.** Not re-encoding children.

⚠️ **TWO THINGS THAT LOOK FORBIDDEN AND ARE NOT.** Ruling §5's MUST item 9 says *avoid recursively
walking the normalized terms of existing Value leaves* — that is about **validation cost**, not about
whether a merged term may exist:
- **Splicing a child's normalized term into a new map or list is O(1) on the BEAM** — it copies a
  reference, it does not walk. `to_term/1` of the composed value may therefore be built directly.
- **`to_term/1` MUST NOT expose nested `%Commonplace.Value{}` structs** (ruling §4 rule 7). That is an
  arm below.

### Metric aggregation — ruling §6, and a child inherits NOTHING

⛔ *"Composition does not inherit permission to exceed limits merely because a child was constructed
earlier."*

| metric | how it aggregates |
| --- | --- |
| encoded byte length | new punctuation + new keys + **each child's cached byte length** |
| node count | new nodes + **each child's node count, once per OCCURRENCE** |
| maximum internal depth | max over: new containers, and **each child's cached depth OFFSET by its new nesting position** |
| maximum string bytes | max(new strings and keys, each child's cached maximum) |
| max object members / array elements | max(new containers' own sizes, each child's cached maxima) |

⭐ **The depth offset is the arm most likely to be faked and the one the whole ruling turns on.** A
child built with `max_depth: 100` and an internal depth of 40, composed at nesting position 30 under
default limits, is at effective depth 70 and must be **rejected** — even though it was legal when it
was built. ⛔ **The package MUST NOT enforce limits by trusting the options a child was created
under.**

---

## 4. MEASURED — facts I ran on this host

| command | result | consequence |
| --- | --- | --- |
| `mix test` at `32f8bba` | `118 tests, 0 failures` | your baseline |
| corpus | 19 + 10 positive, 22 negative | all green, all exercised |
| P3 metrics probe across 7 shapes | matched an independent recount | ✅ **the cached metrics you will aggregate are trustworthy** |
| ⚠️ empty containers | `[]` and `%{}` cache `maximum_internal_depth: 0`, **not 1** | §13 rule 2 increments on **entering**, and an empty container is never entered. **My own first recount got this wrong.** Your offset arithmetic must use the same convention |

⚠️ **What I did NOT measure:** how to observe that a child's subtree was **not** walked. ⭐ **A
suggestion, not an instruction:** `:erlang.trace/3` with a `trace_pattern` on the domain walk
function, counting `:call` messages, is a real measurement of the property rather than a proxy for
it. ⛔ **If that is unworkable, say so and propose what you used** — but a "regression test" that
measures wall-clock time is explicitly **not** what ruling §12 asks for: *"Exact wall-clock
thresholds should not be normative because they are sensitive to runtime and hardware."*

---

## 5. Required arms

⭐ **FIRST DONE STEP: promote every `ARM-PLANNED:` below to `ARM:`, then COUNT them and report the
number.** *This brief deliberately states no count.*

⚠️ **Per arm: the mutation that turned it red, via `bin/mutate.sh`.** ⛔ Never `git checkout --`,
`git reset --hard`, or `git stash` — **anywhere** (errata **V12**).
⭐ **VACUITY HATCH: if an arm cannot be made to fail, SAY SO and leave it red.**

### 6.1 The grammar — ruling §4, §11 items 1–6

<!-- ARM-PLANNED: compose accepts a scalar existing value as the top level input -->
<!-- ARM-PLANNED: compose embeds existing values at multiple list and map depths -->
<!-- ARM-PLANNED: compose accepts repeated inclusion of the same child value -->
<!-- ARM-PLANNED: compose mixes raw portable leaves and constructed value leaves -->
<!-- ARM-PLANNED: compose rejects every non value struct -->
<!-- ARM-PLANNED: compose rejects runtime references outside and beside valid value leaves -->
<!-- ARM-PLANNED: compose rejects an existing value used as an object key -->

⭐ **The last one is ruling §4 rule 1** — *existing Values are permitted only in value positions* —
and §4 rule 2, keys stay ordinary UTF-8 strings.
⚠️ **"beside a valid Value leaf" in the references arm is deliberate:** a PID in a sibling position
must still fail **at its exact path**, and a composer that short-circuits on seeing any Value could
miss it.

### 6.2 Equivalence with full construction — ruling §9, §11 items 7–11

<!-- ARM-PLANNED: compose produces canonical bytes equal to fully expanded construction -->
<!-- ARM-PLANNED: compose produces a normalized term equal to fully expanded construction -->
<!-- ARM-PLANNED: compose normalizes numbers across a composition boundary -->
<!-- ARM-PLANNED: compose orders newly introduced keys by UTF-16 code units -->
<!-- ARM-PLANNED: compose accepts child objects whose own keys are already canonical -->
<!-- ARM-PLANNED: to term of a composed value contains no nested value structs -->

⭐ **The numbers arm is subtler than it looks.** `compose(%{"n" => 1.0})` and a child built from
`1.0` must both land on the integer `1` and encode as `1` — **the same normalization, not a second
one.** Build it so a mutation that skips normalization on the composition path goes red.

### 6.3 Limits, which a child does not inherit — ruling §6, §11 items 12–16

<!-- ARM-PLANNED: compose enforces max bytes on the complete composed result -->
<!-- ARM-PLANNED: compose offsets child depth by its nesting position and enforces max depth -->
<!-- ARM-PLANNED: compose counts nodes exactly including each repeated child occurrence -->
<!-- ARM-PLANNED: compose enforces maximum string object member and array element limits -->
<!-- ARM-PLANNED: compose rejects a child constructed under limits larger than the composing call -->

⭐ **The fifth is the ruling's own example and the arm that proves nothing is inherited.** Build the
child with an explicitly larger `max_depth`, compose under defaults, assert rejection.
⚠️ **The repeated-child arm must use a child with more than one node**, or "counted once" and
"counted per occurrence" give the same answer and the arm measures nothing.

### 6.4 Integrity and round trip — ruling §5 item 10, §8.1, §11 items 17–19

<!-- ARM-PLANNED: compose rejects an obviously malformed value representation through bounded checks -->
<!-- ARM-PLANNED: a composed value round trips through canonical encode and decode -->
<!-- ARM-PLANNED: a composed value is completely revalidated after crossing a process boundary -->

⚠️ **Ruling §8.1 bounds the third and you must not overclaim it:** opacity is *"an API and
cooperative-runtime property, not a cryptographic seal"*, and `compose/2` *"does not promise to
defend one mutually hostile same-VM program from another program capable of forging internal
structs."* ⇒ **The malformed-representation arm is about BOUNDED internal checks catching an
obviously wrong shape — not about defeating a determined forger.** ⭐ **Say that in the moduledoc, so
a later reader does not mistake the check for a guarantee.**

⭐ **The cross-process arm is ruling §8.3 in miniature:** send **canonical bytes** to a second
process, `from_canonical_json/2` there, and assert the result equals the original. ⛔ **Do not send
the struct and call that a boundary test** — the ruling says the struct never crosses one.

### 6.5 The §12 regression fixture — `commonplace-cell`'s envelope

<!-- ARM-PLANNED: composing the cell request envelope visits each raw outer node once -->
<!-- ARM-PLANNED: composing the cell request envelope incorporates children without walking their subtrees -->
<!-- ARM-PLANNED: the composed cell request envelope is byte identical to full reconstruction -->
<!-- ARM-PLANNED: property composing a mixed tree equals constructing the expanded tree -->

The envelope shape, from `commonplace-cell` (their §10) — build it as a fixture:

```elixir
%{"format" => "commonplace.cell.request/v1", "request_id" => …, "source_cell_id" => …,
  "target" => <Value>, "verb" => "cell.describe", "arguments" => <Value>,
  "proofs" => [<Value>, …],           # up to 16 by their §18 max_proofs
  "correlation_id" => …, "causation_id" => …, "extensions" => <Value>}
```

⭐ **The measured `18` in the ruling is `1 + 1 + P + 1` walks** where a composition constructor needs
one outer walk. ⚠️ **The number is a fixture, not a threshold** — assert the *property* (children
incorporated through bounded metadata access), and let the count be whatever it is.

---

## 7. What I do NOT want

- ⛔ any change to `new/2`'s strictness — ruling §3;
- ⛔ `unsafe_new`, `from_parts`, or a public struct-field constructor — ruling §10.4;
- ⛔ a second normalization, ordering, number or encoding model — ruling §9. **If you find yourself
  writing sorting or escaping code in the Composer, stop: it belongs to `Encoder`**;
- ⛔ enforcing limits by trusting a child's original options — ruling §6;
- ⛔ a wall-clock threshold as a normative test — ruling §12;
- ⛔ editing fixture bytes, `bin/`, `docs/proposals/`, `mix.exs`, `.tool-versions`;
- ⛔ a dependency on `commonplace-log`; `JSON.encode!/1` in `lib/`;
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
grep -rho '^defmodule [A-Za-z0-9_.]*' lib/ | sort   # exactly the 9 declared modules
grep -rho '^\s*test "[^"]*"' test/ | wc -l          # >= 140
git status --porcelain conformance/ | wc -l         # 0
```

---

## 9. Report

1. **Per arm: the mutation that turned it red**, the failure line, and confirmation it perturbed the
   measured axis.
2. **How many markers you promoted, counted.**
3. ⭐ **How you observed that a child's subtree was NOT walked** — the mechanism, not the result.
   If `:erlang.trace/3` was unworkable, what you used instead and why.
4. **Any place ruling §5's metric list, ruling §6's aggregation, and §13's limit accounting
   disagree** — findings, not quiet fixes.
5. Any module created and whether it was on the `MODULE:` list.
6. Verbatim output of every command in §8.
7. ⚠️ `compile blocked in fence` as the headline if compile or deps fail.
8. ⚠️ **You probably cannot commit** (`.git` read-only). Leave the work in the tree and say so.
