# Ruling: composition of constructed `Commonplace.Value` values

Status: accepted design correction  
Applies to: `commonplace-value` specification 0.1  
Date: 2026-08-24

## 1. Question

The current `commonplace-value` specification defines strict construction from ordinary Elixir terms:

```elixir
Commonplace.Value.new(term, options)
```

It rejects structs and forbids implicit struct-to-map conversion. Because `%Commonplace.Value{}` is itself a struct, the specification accidentally provides no efficient way to build a larger Value from Values already constructed and validated by the package.

Consequently, a caller must repeatedly:

1. extract ordinary terms from child Values;
2. assemble a larger term;
3. recursively validate the entire expanded tree again;
4. recalculate its limits and canonical bytes.

`commonplace-cell` encountered this immediately while constructing request envelopes. Its envelope construction currently performs eighteen redundant walks where a composition constructor could perform one outer walk.

The safe fallback—fully rebuilding the Value—is correct, but the cost is unnecessary inside one Realm.

## 2. Ruling

`commonplace-value` SHOULD add an explicit composition constructor:

```elixir
@spec compose(composable_term(), keyword()) ::
        {:ok, Commonplace.Value.t()} |
        {:error, Commonplace.Value.Error.t()}

def compose(term, options \\ [])
```

`compose/2` accepts the ordinary portable-term grammar plus an existing `Commonplace.Value.t()` as an atomic leaf.

It validates every newly introduced raw term and container. It does not recursively revalidate the contents of an embedded Value produced by the package.

This is a checked composition operation, not an unchecked container constructor.

## 3. Keep `new/2` strict

`new/2` retains its existing meaning:

> Validate an untrusted ordinary Elixir term and construct a Value from it.

It MUST continue to reject every struct, including `%Commonplace.Value{}`.

The API distinction is intentional:

| API | Input trust | Existing Values as leaves |
| --- | --- | --- |
| `new/2` | ordinary, untrusted Elixir term | rejected |
| `compose/2` | explicit composition template | accepted |
| `from_canonical_json/2` | untrusted canonical bytes | fully decoded and validated |

This keeps the special treatment of an existing Value visible at the call site. An application parsing arbitrary input should reach for `new/2` or `from_canonical_json/2`, not `compose/2`.

## 4. Composable-term grammar

The conceptual type is:

```elixir
@type portable_scalar ::
        nil
        | boolean()
        | integer()
        | float()
        | String.t()

@type composable_term ::
        portable_scalar()
        | Commonplace.Value.t()
        | [composable_term()]
        | %{String.t() => composable_term()}
```

Rules:

1. Existing Values are permitted only in value positions.
2. Object keys remain ordinary valid UTF-8 strings.
3. Every struct other than `Commonplace.Value.t()` is rejected.
4. All ordinary leaves retain the validation rules of `new/2`.
5. Improper lists, non-string map keys, invalid UTF-8, non-finite numbers, runtime references, and unsupported terms remain rejected.
6. A top-level existing Value MAY be returned unchanged if it satisfies the effective limits.
7. `to_term/1` on the result returns an ordinary normalized term; it MUST NOT expose nested `%Commonplace.Value{}` structs.

Examples:

```elixir
{:ok, target} =
  Commonplace.Value.new(%{
    "cell_id" => cell_id,
    "resource" => %{"kind" => "cell"}
  })

{:ok, arguments} = Commonplace.Value.new(%{"coordinate" => 42})

{:ok, request} =
  Commonplace.Value.compose(%{
    "format" => "commonplace.cell.request/v1",
    "request_id" => request_id,
    "source_cell_id" => source_cell_id,
    "target" => target,
    "verb" => "cell.describe",
    "arguments" => arguments,
    "proofs" => [],
    "extensions" => %{}
  })
```

The composer walks the newly introduced request map and its raw leaves. It treats `target` and `arguments` as already constructed subtrees.

## 5. Required composition behavior

For each existing Value leaf, `compose/2` MUST reuse package-maintained information sufficient to preserve all `Commonplace.Value` invariants without expanding and revalidating the subtree.

At minimum, every constructed Value must retain or make cheaply available:

- canonical bytes;
- normalized term or an equivalent immutable representation;
- encoded byte length;
- node count;
- maximum internal depth;
- maximum string byte length;
- maximum object member count;
- maximum array element count;
- internal representation version or shape information needed to reject obviously malformed instances.

The implementation MAY retain additional summaries required by future finite limits.

The composer MUST:

1. walk every newly introduced container;
2. validate every newly introduced raw leaf;
3. validate all new object keys;
4. sort new object keys according to JCS UTF-16 ordering;
5. aggregate child metrics into metrics for the result;
6. enforce the effective limits against the complete composed value;
7. produce exactly the canonical bytes that full construction would have produced;
8. produce the same normalized term that full construction would have produced;
9. avoid recursively walking the normalized terms of existing Value leaves;
10. reject malformed Value representations detectable through bounded internal checks.

Canonical child bytes may be embedded as already canonical JSON fragments. The composer must still emit new container punctuation and canonically ordered new object keys.

## 6. Resource limits

Composition does not inherit permission to exceed limits merely because a child was constructed earlier.

For example, a child may have been constructed with an explicitly larger `max_depth` than the default. Composing it under default options must compare its cached depth summary at its new nesting position against the new result's limit.

Likewise:

- final byte length includes container syntax and keys introduced by the composition;
- final node count includes every child node exactly once;
- child depth is offset by its position in the new tree;
- maximum string and container sizes include both new and existing portions;
- repeated inclusion of one child Value counts each occurrence in the resulting logical tree.

The package MUST NOT enforce limits merely by trusting the options under which a child was originally created.

## 7. Complexity requirement

Composition should take time proportional to:

```text
newly introduced nodes
+ number of embedded Value leaves
+ bytes required for the newly emitted canonical result
```

It should not take time proportional to the sum of every expanded child subtree merely to validate those children again.

Producing a new flat canonical binary may necessarily copy the final output bytes. The ruling avoids redundant semantic walks; it does not require impossible zero-copy binary construction.

Implementations MAY retain canonical iodata or another immutable internal representation when that improves composition without changing `encode/1` output.

## 8. Safety model

### 8.1 What an existing Value means

A `Commonplace.Value.t()` is an abstract data type maintained by the package. The package contract applies to Values returned by its conforming constructors.

Hand-constructing, pattern-matching, or modifying `%Commonplace.Value{}` internals remains unsupported. Such a term was not “successfully constructed” under the specification merely because it has the struct tag.

Elixir opacity is an API and cooperative-runtime property, not a cryptographic seal. Arbitrary code sharing a BEAM VM can violate module boundaries just as it can bypass a Cell router with `send/2`.

`compose/2` does not promise to defend one mutually hostile same-VM program from another program capable of forging internal structs. That is a Realm-placement problem, not a portable-value constructor problem.

### 8.2 Cell boundary versus Realm boundary

The following statement is too strong:

> Every receiving side of a Cell boundary must fully walk a Value because sender validation is only a claim.

The correct rule is:

> A receiving Realm must fully decode and validate incoming canonical bytes. A receiving Cell inside the same Realm may trust a `Commonplace.Value.t()` produced by the package.

Same-Realm Cells remain separate authorization domains, but they share a cooperative runtime-security domain. The receiving Cell MUST still authenticate the source context as applicable and authorize the target resource and verb. It need not semantically revalidate an already constructed portable subtree merely to protect against code the Realm model already treats as cooperative.

If two Cells must distrust each other's runtime values, they must be placed in separate Realms or behind a stronger sandbox.

### 8.3 Cross-Realm rule

The `%Commonplace.Value{}` struct never crosses a Realm boundary.

Only canonical bytes cross. The receiving Realm MUST:

1. enforce framing and byte limits;
2. parse the complete byte sequence;
3. validate the complete value domain;
4. enforce its own limits;
5. verify canonical re-encoding;
6. construct a new local `Commonplace.Value.t()`.

No flag, header, signature claim, or sender assertion that a value was “already validated” skips this work.

Transport authentication proves something about the source of bytes. It does not replace parsing and validating their value structure.

After cross-Realm decoding has produced a local Value, that Value may participate efficiently in further same-Realm composition.

## 9. Canonical equivalence

For every valid composition template, composition MUST be observably equivalent to fully expanding its child Values and calling `new/2`:

```elixir
{:ok, composed} = Commonplace.Value.compose(template)
{:ok, rebuilt} = Commonplace.Value.new(expand_values(template))

Commonplace.Value.encode(composed) ==
  Commonplace.Value.encode(rebuilt)

Commonplace.Value.equal?(composed, rebuilt)

Commonplace.Value.to_term(composed) ==
  Commonplace.Value.to_term(rebuilt)
```

`expand_values/1` above is test notation, not a required public API.

Composition MUST NOT introduce a second equality, normalization, number, Unicode, object-ordering, or canonical-encoding model.

## 10. Spec amendments

The `commonplace-value` specification should be amended as follows.

### 10.1 Terminology

Add a definition for **composable term**:

> An ordinary portable term in which an existing `Commonplace.Value.t()` may appear as an atomic value leaf for the explicit composition constructor.

### 10.2 Value domain

Keep the portable value domain unchanged.

Clarify that §5.1 rejects structs as ordinary portable terms and that §5.2 still forbids implicit struct-to-map conversion. The composition API adds one constructor-specific leaf form; it does not add structs to the portable value domain.

### 10.3 Opaque representation

Require sufficient cached representation and metrics to compose a child without recursively validating it. Clarify that callers who forge or mutate internal structs are outside the API contract.

### 10.4 Public API

Add:

```elixir
@spec compose(composable_term(), keyword()) ::
        {:ok, t()} | {:error, Error.t()}
def compose(term, opts \\ [])
```

No unchecked `unsafe_new`, `from_parts`, or public struct-field constructor should be introduced.

### 10.5 Security properties

Distinguish abstract-type integrity inside a cooperative Realm from complete reconstruction at a Realm boundary.

### 10.6 Cell-boundary guidance

Clarify that the same-Realm fast path may pass a constructed Value without encoding or revalidation. Cross-Realm ingress always calls `from_canonical_json/2` or an equivalent complete canonical decoder.

### 10.7 Versioning

Adding `compose/2` does not change the portable domain, canonical bytes, or equality. It is a backward-compatible API addition provided its output is byte-identical to full construction.

## 11. Required tests

The implementation MUST add tests covering:

1. a scalar existing Value used as the top-level composition input;
2. Values embedded at multiple list and map depths;
3. repeated inclusion of the same child Value;
4. mixing raw portable leaves and constructed Value leaves;
5. rejection of every non-Value struct;
6. rejection of runtime references outside and beside valid Value leaves;
7. canonical byte equality with fully expanded `new/2` construction;
8. normalized-term equality with fully expanded construction;
9. numeric normalization across a composition boundary;
10. JCS object ordering across newly introduced keys;
11. child objects whose own keys are already canonical;
12. final `max_bytes` enforcement;
13. child depth offset and final `max_depth` enforcement;
14. exact node accounting, including repeated child inclusion;
15. maximum string, object-member, and array-element enforcement;
16. a child constructed under limits larger than the composing call's limits;
17. bounded rejection of an obviously malformed `%Commonplace.Value{}` representation;
18. canonical encode/decode round-trip of the composed result;
19. complete revalidation after crossing the cross-process Cell test boundary;
20. absence of nested `%Commonplace.Value{}` structs in `to_term/1` output.

Property tests SHOULD generate a tree of raw portable terms, randomly replace subtrees with constructed Values, compose the mixed tree, and compare it with full construction of the original tree.

## 12. Performance regression

The implementation SHOULD retain a benchmark or operation-counting test based on the `commonplace-cell` request envelope.

The test should demonstrate that:

- each raw outer node is visited once;
- each existing Value is incorporated through bounded metadata access rather than subtree validation;
- the complete envelope is canonically emitted once;
- the result remains byte-identical to full reconstruction.

The measured eighteen-walk envelope is a useful regression fixture. Exact wall-clock thresholds should not be normative because they are sensitive to runtime and hardware.

## 13. Consequence for `commonplace-cell`

`commonplace-cell` made the correct MVP choice by accepting the redundant safe path rather than creating its own unchecked constructor.

After `compose/2` lands, Cell envelope construction SHOULD use it for already constructed:

- target addresses;
- arguments;
- proof values;
- extensions;
- nested error details;
- successful response values.

`commonplace-cell` must not inspect or manufacture `Commonplace.Value` internals. It depends only on the public composition contract.

Its cross-Realm receiver continues to fully decode canonical bytes. Its same-Realm route may pass constructed Values directly under the cooperative Realm model.

## 14. Landing-script defect

The separately reported landing-script fault is real but does not alter the Value or Cell architecture.

A release gate MUST NOT rely on being the left side of a pipeline whose failure is visible only when a particular shell option happens to be enabled.

The repository rule should be:

1. every required gate is checked explicitly;
2. any failing gate terminates before push or publication;
3. `set -euo pipefail` is defense in depth, not the only thing making the gate effective;
4. output formatting must occur only after the gate's status has been captured safely;
5. a regression test substitutes a deliberately failing gate and proves the push command is never reached.

The remaining `commonplace-doc-sync` copy should receive the same repair. Repositories without the script require no change.

## 15. Final ruling

Add `Commonplace.Value.compose/2` as an explicit, checked composition constructor. Preserve `new/2` as the strict untrusted-term constructor. Reuse existing Value subtrees and cached metrics inside one cooperative Realm, while continuing to reconstruct and fully validate every value entering from another Realm.

This removes the measured repeated walks without weakening the boundary that actually needs to be firm.
