# `commonplace-value` specification

Status: proposed 0.1  
Language: Elixir  
Repository: `commonplace-systems/commonplace-value`  
Package: `commonplace_value`  
Date: 2026-08-24

## 1. Purpose

`commonplace-value` defines the values that Commonplace permits to cross authority, persistence, process, language, and network boundaries.

Its central guarantee is:

> A successfully constructed `Commonplace.Value` is inert, JSON-equivalent data with one deterministic RFC 8785 canonical byte representation.

The package prevents each Commonplace subsystem from inventing a slightly different meaning of “JSON-safe.” It is a value and canonicalization primitive, not a message protocol, schema system, or authorization library.

## 2. Architectural position

```text
                 commonplace-value
                    /    |    \
                   /     |     \
          cell messages  |   doc-sync values
                         |
                 durable configuration
```

Expected consumers include:

- inter-Cell and cross-Realm message envelopes;
- Document commands and events;
- `commonplace-doc-sync` offers, receipts, and relationship values;
- Directory entry payloads;
- capability arguments and verified claims;
- durable configuration;
- MCP-facing values.

The package SHOULD sit below those consumers and MUST NOT depend on them.

`commonplace-log` already has frozen, load-bearing JCS behavior. Version 0.1 of `commonplace-value` MUST NOT require `commonplace-log` to adopt this package. Compatibility is proved first; dependency changes are separate decisions.

## 3. Normative vocabulary

The words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are normative.

### 3.1 Portable value

An immutable value composed solely of the types defined in §5.

### 3.2 Canonical bytes

The unique UTF-8 JSON encoding of a portable value under RFC 8785, also called JCS.

### 3.3 Normalized term

The ordinary Elixir representation obtained by decoding canonical bytes under this specification’s numeric rules.

### 3.4 Construction

Validation and normalization of an Elixir term into an opaque `Commonplace.Value`.

### 3.5 Canonical decoding

Parsing bytes that are required to already be the one canonical encoding of their value. This operation validates; it does not tidy arbitrary JSON.

## 4. Goals

Version 0.1 provides:

1. One precise portable-value domain.
2. Strict recursive validation without implicit conversions.
3. An opaque proof-carrying Elixir value.
4. RFC 8785 canonical JSON bytes.
5. Canonical decoding that rejects alternate encodings.
6. Byte-defined equality across runtimes.
7. Explicit resource limits.
8. Structured errors with locations.
9. Language-neutral positive and negative conformance vectors.
10. Byte compatibility with `Commonplace.Log.Jcs` over their shared accepted domain.

## 5. Value domain

A portable value is exactly one of:

```text
null
boolean
number
UTF-8 string
ordered list of portable values
map from UTF-8 string keys to portable values
```

The normalized Elixir representation is:

```elixir
@type normalized_term ::
        nil
        | boolean()
        | integer()
        | float()
        | String.t()
        | [normalized_term()]
        | %{String.t() => normalized_term()}
```

Only the atoms `nil`, `true`, and `false` are portable.

### 5.1 Explicitly rejected terms

The following are not portable values:

- other atoms;
- tuples;
- structs;
- PIDs;
- references;
- ports;
- functions;
- improper lists;
- maps with non-string keys;
- non-UTF-8 binaries;
- bitstrings that are not binaries;
- NaN or positive/negative infinity;
- integers outside the accepted numeric domain;
- cyclic or runtime-owned objects represented through protocols.

No protocol implementation may make a rejected Elixir term portable. In particular, implementing `Jason.Encoder` does not affect this package’s domain.

### 5.2 No implicit conversions

The package MUST NOT silently convert:

- atoms to strings;
- keyword lists to objects;
- tuples to arrays;
- structs to maps;
- `DateTime`, URI, Decimal, UUID, or similar types to strings;
- arbitrary binary data to Base64;
- map keys to strings.

Schemas may represent those concepts using explicit portable strings or tagged maps before calling `Commonplace.Value.new/2`.

### 5.3 Binary data

Valid UTF-8 binaries are strings. Other binaries are rejected.

A higher-level protocol that needs bytes must define an explicit representation such as:

```json
{"encoding":"base64url","data":"AAEC"}
```

`commonplace-value` does not interpret or privilege that shape.

## 6. Numeric model

JSON has one number category while Elixir distinguishes arbitrary-precision integers and binary64 floats. JavaScript and RFC 8785 use IEEE 754 binary64 semantics. Version 0.1 therefore defines the following boundary.

### 6.1 Elixir integer inputs

`Commonplace.Value.new/2` accepts integer terms only in the safe interoperable range:

```text
-(2^53 - 1) through +(2^53 - 1)
```

Larger integer terms are rejected with `:integer_out_of_range`. Callers that need arbitrary integers must encode them explicitly as strings under their own schema.

### 6.2 Elixir float inputs

Finite IEEE 754 binary64 floats are accepted. NaN and infinities are rejected.

Negative zero normalizes to positive zero and canonically encodes as `0`.

### 6.3 Canonical numeric decoding

Canonical JSON decoding interprets numeric tokens according to IEEE 754 binary64/JCS semantics.

- A mathematically integral value within the safe integer range normalizes to an Elixir integer.
- Other finite binary64 values normalize to Elixir floats.
- A token whose value cannot be represented under binary64 semantics without changing its canonical spelling is rejected as `:number_not_interoperable`.

Canonical decoding may therefore accept an integral-looking token outside the safe integer range when that token is the canonical spelling of a finite binary64 value; `to_term/1` returns a float in that case. The restriction in §6.1 applies specifically to Elixir integer inputs, where silently rounding an arbitrary-precision integer would lose caller-supplied information.

Thus alternate spellings such as `1.0`, `1e0`, and `-0` are not accepted by canonical decoding; their canonical encoding is `1`, `1`, and `0` respectively.

### 6.4 Numeric equality

Numeric equality is canonical-byte equality. Construction normalizes distinctions that JSON/JCS does not retain:

```text
new(1)    == new(1.0)
new(0)    == new(-0.0)
```

No public guarantee is made about preserving the caller’s original Elixir numeric type.

## 7. Strings and Unicode

Every string and object key MUST be well-formed UTF-8.

The package:

- preserves Unicode scalar values;
- performs no NFC, NFD, case, locale, or compatibility normalization;
- treats canonically equivalent Unicode sequences as distinct strings;
- accepts control characters representable by JSON and escapes them canonically;
- emits non-ASCII Unicode characters literally as UTF-8 where RFC 8785 requires;
- rejects malformed UTF-8 before encoding.

Object keys are sorted by UTF-16 code units as required by RFC 8785—not by Unicode code point, locale order, or UTF-8 byte order.

## 8. Arrays and objects

Array order is significant and preserved.

Object member order in an input Elixir map is insignificant. Canonical encoding sorts keys by UTF-16 code units recursively at every object depth.

Object keys must be strings. Empty strings are valid keys.

An Elixir map cannot contain duplicate equal keys. Canonical JSON input containing duplicate textual keys is rejected under §10 because it cannot equal the re-encoded canonical value.

## 9. Opaque representation

The package exposes an opaque type:

```elixir
@opaque t :: %Commonplace.Value{}
```

Its fields are private implementation details. A conforming implementation SHOULD retain canonical bytes as the identity-bearing representation and MAY cache the normalized term.

Callers MUST NOT construct or pattern-match internal fields. The normal struct update syntax is not a supported API.

`Inspect` SHOULD display bounded metadata rather than the entire value by default, for example:

```text
#Commonplace.Value<bytes: 184>
```

It MUST NOT accidentally print secrets merely because they are portable data.

## 10. Canonical encoding

`Commonplace.Value.encode/1` returns RFC 8785 canonical JSON bytes.

The encoding rules include:

1. UTF-8 output with no BOM.
2. No insignificant whitespace.
3. Object keys sorted by UTF-16 code units.
4. Recursive object sorting.
5. Array order preservation.
6. ECMAScript/JCS number serialization.
7. Negative zero emitted as `0`.
8. Required short escapes for `\b`, `\t`, `\n`, `\f`, `\r`, `\"`, and `\\`.
9. Remaining U+0000–U+001F controls emitted as lowercase `\u00xx`.
10. `/` and non-control Unicode emitted unescaped where RFC 8785 requires.

Canonical bytes are the authoritative identity of a `Commonplace.Value`.

## 11. Canonical decoding

`Commonplace.Value.from_canonical_json/2` accepts bytes only when all of the following hold:

1. The input is a single complete JSON value.
2. It contains no BOM, leading/trailing whitespace, or trailing data.
3. It is valid UTF-8.
4. It parses into the portable domain.
5. Numeric values satisfy §6.
6. Re-encoding the parsed value produces byte-for-byte identical input.

The final equality check causes canonical decoding to reject:

- unsorted object keys;
- insignificant whitespace;
- duplicate object keys;
- alternate escapes;
- escaped `/`;
- noncanonical number spellings;
- uppercase hexadecimal escapes where lowercase is canonical;
- a trailing newline;
- any alternate byte string representing the same parsed JSON value.

The package intentionally does not expose a permissive `from_json/1` in version 0.1. Importing arbitrary JSON requires a caller-owned parsing and normalization policy followed by `new/2`.

## 12. Equality

Two values are equal exactly when their canonical bytes are equal.

```elixir
Commonplace.Value.equal?(left, right)
```

MUST return the result of byte equality. It MUST NOT recursively compare cached Elixir terms.

Ordinary `==` or struct equality is not part of the public contract.

The package does not define a universal content ID. Consumers that hash values MUST domain-separate according to their own protocol and hash the canonical bytes returned by `encode/1`.

## 13. Resource limits

Validation and decoding occur at trust boundaries and MUST be bounded.

Version 0.1 defines:

```elixir
%Commonplace.Value.Limits{
  max_bytes: 1_048_576,
  max_depth: 64,
  max_nodes: 100_000,
  max_string_bytes: 1_048_576,
  max_object_members: 100_000,
  max_array_elements: 100_000
}
```

The defaults apply unless the caller supplies a stricter or explicitly larger finite limit set.

Rules:

1. `max_bytes` is measured on canonical bytes for construction and directly on input bytes for canonical decoding.
2. The top-level value has depth 0. Entering an array or object increases depth by one.
3. `max_nodes` counts every scalar, array, object, and member value visited.
4. String limits are measured in UTF-8 bytes, not graphemes or code points.
5. Limit values must be positive finite integers.
6. No option may disable limits with `:infinity`.
7. Implementations MUST check depth and input byte limits before performing work likely to exhaust the VM.

Higher-level protocols SHOULD use chunking rather than raising these limits without bound.

## 14. Public API

Version 0.1 exposes this conceptual surface:

```elixir
defmodule Commonplace.Value do
  @opaque t :: %__MODULE__{}

  @spec new(term(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new(term, opts \\ [])

  @spec from_canonical_json(binary(), keyword()) ::
          {:ok, t()} | {:error, Error.t()}
  def from_canonical_json(bytes, opts \\ [])

  @spec encode(t()) :: binary()
  def encode(value)

  @spec to_term(t()) :: normalized_term()
  def to_term(value)

  @spec equal?(t(), t()) :: boolean()
  def equal?(left, right)
end
```

Bang variants MAY be supplied for trusted initialization code, but the non-bang functions are normative.

There is deliberately no API for:

- mutating a value;
- permissive JSON parsing;
- schema validation;
- atomizing keys;
- automatic binary tagging;
- constructing messages;
- authorization;
- routing;
- hashing without a consumer-selected domain.

## 15. Errors

Failures return a structured error:

```elixir
%Commonplace.Value.Error{
  operation: :construct | :decode,
  reason: reason,
  path: json_pointer,
  limit: integer | nil,
  actual: integer | nil
}
```

`path` is an RFC 6901 JSON Pointer locating the rejected value where possible. Array indices use decimal segments. Object keys escape `~` and `/` according to RFC 6901.

At minimum, reasons include:

```elixir
:unsupported_term
:atom_not_allowed
:tuple_not_allowed
:struct_not_allowed
:runtime_reference_not_allowed
:improper_list
:non_string_key
:invalid_utf8
:non_finite_number
:integer_out_of_range
:number_not_interoperable
:invalid_json
:trailing_data
:non_canonical_json
:max_bytes_exceeded
:max_depth_exceeded
:max_nodes_exceeded
:max_string_bytes_exceeded
:max_object_members_exceeded
:max_array_elements_exceeded
:invalid_limits
```

Errors MUST NOT inspect or reproduce the complete rejected value. A path and classification are sufficient and avoid leaking secrets into logs.

## 16. Security properties and limits

A successfully constructed value proves only:

- its representation is inert portable data;
- it has one canonical encoding;
- it satisfies the selected resource limits.

It does not prove:

- authorization;
- schema validity;
- semantic correctness;
- safe use in SQL, HTML, shell commands, file paths, or URLs;
- absence of secrets;
- trustworthiness of the sender.

`Commonplace.Value` is safe to serialize; it is not safe to execute.

Consumers MUST still validate schemas and authorize actions after decoding.

## 17. Use at a Cell boundary

A Cell router may require `%Commonplace.Value{}` for every cross-Cell payload:

```elixir
with {:ok, payload} <- Commonplace.Value.new(term),
     :ok <- authorize(capability, target, verb),
     {:ok, result} <- route(target, verb, payload) do
  {:ok, result}
end
```

The local fast path MAY pass the opaque value without physically serializing it. Its meaning remains exactly the value that `encode/1` would transmit.

The receiving boundary SHOULD operate on `to_term/1` or a schema-decoded value and MUST NOT receive caller PIDs, functions, references, or open handles through the payload.

This package does not prevent arbitrary Elixir code sharing a BEAM VM from bypassing a router with `send/2`. Hard isolation of hostile code belongs to a Realm, Container, OS process, separate BEAM node, or sandbox.

## 18. Compatibility with `commonplace-log`

`Commonplace.Log.Jcs` and `Commonplace.Value` share RFC 8785 encoding rules but have different responsibilities:

- the log canonicalizer is part of a frozen entry wire protocol;
- `Commonplace.Value` defines an application-level accepted domain, normalization, limits, and opaque proof type;
- the log may accept terms or inputs that `Commonplace.Value` rejects;
- neither package may infer complete substitutability from matching bytes on ordinary examples.

For every value accepted by both packages, their canonical bytes MUST match.

Version 0.1 SHOULD copy the language-neutral positive JCS vectors from `commonplace-log` and add its own negative and boundary vectors. It MUST NOT import `Commonplace.Log.Jcs` as its implementation or compare an implementation against itself.

Migrating `commonplace-log` to depend on this package is explicitly outside version 0.1.

## 19. Conformance corpus

The repository owns language-neutral fixtures with at least:

```text
conformance/
├── canonical/
├── valid-values/
└── invalid-values/
```

Every case contains raw input bytes or a language-neutral term description plus expected canonical bytes or an expected reason slug.

### 19.1 Required positive cases

The corpus covers:

- every scalar kind;
- nested arrays and objects;
- empty arrays, objects, and keys;
- object key ordering including astral-plane versus BMP keys;
- every required string escape;
- literal non-ASCII output;
- number boundaries at `1e-6`, `1e-7`, `1e20`, and `1e21`;
- negative zero;
- maximum safe positive and negative integers;
- construction equivalence for `1`/`1.0` and `0`/`-0.0`;
- recursive normalization and canonical round-trip.

### 19.2 Required negative cases

The corpus covers:

- every rejected Elixir term category through Elixir tests;
- malformed and non-UTF-8 JSON;
- BOM;
- leading, trailing, and internal insignificant whitespace;
- trailing newline and trailing JSON value;
- duplicate keys, including duplicate keys with equal values;
- unsorted keys;
- alternate string escapes;
- noncanonical numeric spellings;
- unsafe Elixir integer inputs and non-interoperable numeric tokens;
- NaN and infinities where the runtime can construct them;
- every resource limit at one-below, exact, and one-above boundaries;
- deep nesting;
- improper lists;
- non-string map keys.

### 19.3 Anti-vacuity

The conformance harness MUST include at least one deliberately incorrect expected output and demonstrate that it is detected before the valid corpus may report green.

A cross-runtime implementation must compare independently emitted byte files, not merely two in-memory values produced through shared code.

## 20. Acceptance tests

A conforming Elixir implementation MUST demonstrate:

1. Every accepted domain type constructs successfully.
2. Every rejected category returns its specific reason and path.
3. Construction followed by encoding is deterministic across fresh OS processes.
4. Canonical decode followed by encode returns identical bytes.
5. Noncanonical representations of valid JSON are rejected rather than repaired.
6. Duplicate object keys are rejected.
7. Astral-plane keys sort by UTF-16 code units.
8. Numbers match RFC 8785/ECMAScript spelling at all pinned boundaries.
9. `1` and `1.0` construct equal values.
10. Negative zero and positive zero construct equal values and emit `0`.
11. Unsafe Elixir integers are rejected.
12. Malformed UTF-8 strings and keys are rejected.
13. Structs remain rejected even when they implement a JSON encoder.
14. A nested PID, function, reference, tuple, or atom fails at its exact path.
15. Every resource limit rejects before unbounded work.
16. `equal?/2` is canonical-byte equality.
17. Values accepted by both this package and `Commonplace.Log.Jcs` emit identical bytes over the shared corpus.
18. The package has no runtime dependency on `commonplace-log` or higher Commonplace layers.
19. Inspect output is bounded and does not reveal the complete value.
20. The anti-vacuity fixture is observed failing.

Property tests SHOULD generate bounded portable terms and assert:

```text
new(term)
→ encode
→ from_canonical_json
→ encode
```

produces identical canonical bytes.

## 21. Package boundaries

The package may depend on:

- Elixir/OTP standard libraries;
- a JSON parser used strictly as an implementation component;
- test-only property and conformance tooling.

It MUST NOT depend on:

- `commonplace-log`;
- reducers;
- `commonplace-doc`;
- `commonplace-dir`;
- `commonplace-doc-sync`;
- Cell, Realm, or capability implementations.

If a third-party JCS implementation is adopted, the conformance corpus remains normative. Library behavior is never accepted merely because the dependency claims RFC 8785 support.

## 22. Versioning

The value domain and canonical byte rules are protocol surfaces.

The following are breaking changes:

- accepting a previously rejected term category when it changes cross-runtime meaning;
- rejecting a previously accepted canonical value;
- changing numeric normalization;
- changing canonical bytes;
- changing default limits in a way that rejects previously valid boundary traffic;
- changing equality semantics.

Higher-level protocols SHOULD declare the value format they use, for example:

```text
commonplace.value/jcs-v1
```

The format identifier belongs in the enclosing protocol or negotiation, not inside every encoded value.

## 23. Initial implementation plan

### Phase 1: domain and opaque value

- strict recursive validator;
- numeric normalization;
- UTF-8 enforcement;
- opaque type and bounded inspection;
- structured paths and errors;
- limit accounting;
- property generators.

### Phase 2: canonical bytes

- RFC 8785 encoder;
- imported positive conformance vectors;
- number and UTF-16 ordering tripwires;
- cross-process determinism test;
- differential byte check against `Commonplace.Log.Jcs` over fixtures only.

### Phase 3: canonical decoding

- strict JSON parser boundary;
- byte-for-byte re-encoding gate;
- duplicate-key and alternate-encoding rejection;
- raw byte and resource-limit fixtures;
- complete round-trip property tests.

### Phase 4: boundary proof

- a small fixture router accepting only `Commonplace.Value`;
- local pass-through and encoded round-trip equivalence;
- proof that rejected BEAM terms cannot enter the receiver through the value API;
- documentation of the same-VM security limit.

## 24. Completion criteria

Version 0.1 is complete when two independent implementations can receive the same accepted value, emit byte-identical canonical JSON, and agree on every pinned rejection—while Elixir callers can treat `%Commonplace.Value{}` as proof that no PID, function, reference, struct, tuple, atom, malformed string, or unbounded container crossed the boundary.

The package should remain small enough that its complete public contract can be audited directly. New conveniences belong elsewhere unless they strengthen the portable-value invariant itself.
