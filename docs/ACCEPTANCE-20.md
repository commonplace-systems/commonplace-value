# Acceptance — spec §20 and §24, item by item

**Measured at `9cda6f7`. 156 tests, 155 declared arms.** Re-derive with `bin/check-acceptance-arms.sh`,
which fails if any arm named below is not a real test.

⛔ **WHY THIS FILE EXISTS, AND IT IS A DEFECT OF MINE.** Errata **V15** claimed all twenty §20 items
had a named arm and cited *"round P6's report"* for the mapping. **That report was a 1 MB UNTRACKED
file in a scratch round directory** — and one I had, an hour earlier, been discussing removing as
housekeeping. ⭐ **The repo's completion claim rested on something not in the repo.** Found by
`commonplace-plan`'s README survey, not by me. `docs/STATE.md` §1 says a claim about the code must
cite a test **by name**; I satisfied that by citing a document that was not here.

⚠️ **AND EXTRACTING THE TABLE FOUND TWO MORE DEFECTS**, both of which would have been committed
verbatim had I not verified every citation against the suite:

- item **20.2** cited *"the named `domain rejects …` category arms"* — ⛔ **an ellipsis names no
  arm.** Every category arm is now spelled out.
- item **20.16** cited `equal? is canonical-byte equality`, **hyphenated**; the test is
  `equal? is canonical byte equality`. ⛔ **A citation that does not match is a citation of
  nothing**, and `bin/check-plan-arms.sh` could not see it because this table is prose, not `ARM`
  markers.

⇒ ⭐ **That is why `bin/check-acceptance-arms.sh` exists.** A claim-citing document needs the same
gate the plans have, or it drifts the moment a test is renamed.

---

### Spec §20

| Item | Assessment and named arm(s) |
|---|---|
| 20.1 accepted domain types | Demonstrated by `domain accepts nil and true and false`, `domain accepts a UTF-8 string including astral plane characters`, `domain accepts nested lists and maps recursively`, `domain accepts the maximum safe positive and negative integers`, and `property every generated portable term within limits is accepted`. |
| 20.2 specific rejection reason and path | Demonstrated by every category arm — `domain rejects an atom other than nil true false with :atom_not_allowed` · `domain rejects a tuple with :tuple_not_allowed` · `domain rejects a struct with :struct_not_allowed` · `domain rejects a pid a reference and a port with :runtime_reference_not_allowed` · `domain rejects a function with :unsupported_term` · `domain rejects an improper list with :improper_list` · `domain rejects a map with a non-string key with :non_string_key` · `domain rejects a non-UTF-8 binary with :invalid_utf8` · `domain rejects a non-UTF-8 object key with :invalid_utf8` · `domain rejects a bitstring that is not a binary` —, `domain reports the exact path of a deeply nested rejected term`, and `conformance every invalid values case is rejected with an accepted reason slug`. |
| 20.3 fresh-process determinism | Demonstrated by `canonical bytes are identical when produced by a fresh operating system process` and `the whole positive corpus encodes identically in a fresh operating system process`. |
| 20.4 canonical decode/encode identity | Demonstrated by `canonical decode followed by encode returns identical bytes`. |
| 20.5 reject rather than repair noncanonical JSON | Demonstrated by `from canonical json rejects insignificant whitespace`, `from canonical json rejects unsorted object keys`, `from canonical json rejects alternate string escapes`, and `from canonical json rejects noncanonical number spellings`. |
| 20.6 duplicate keys | Demonstrated by `from canonical json rejects duplicate object keys` and `from canonical json rejects duplicate object keys whose values are equal`. |
| 20.7 UTF-16 key ordering | Demonstrated by `encoder sorts object keys by UTF-16 code units`. |
| 20.8 number spellings | Demonstrated by `encoder spells 1e20 in decimal form and 1e21 with an explicit plus` and `encoder spells 1e-6 in decimal form and 1e-7 in exponential form`. |
| 20.9 `1`/`1.0` equality | Demonstrated by `new of 1 and new of 1.0 construct equal values`. |
| 20.10 signed-zero equality/encoding | Demonstrated by `new of 0 and new of negative zero construct equal values encoding to 0`. |
| 20.11 unsafe integers | Demonstrated by `domain rejects an integer one above the maximum safe integer with :integer_out_of_range` and its below-minimum counterpart. |
| 20.12 malformed UTF-8 strings/keys | Demonstrated by `domain rejects a non-UTF-8 binary with :invalid_utf8` and `domain rejects a non-UTF-8 object key with :invalid_utf8`. |
| 20.13 JSON-encodable structs remain rejected | Demonstrated by `domain rejects a struct that derives the JSON encoder protocol`. |
| 20.14 nested rejected terms and boundary | Demonstrated by `domain rejects an atom other than nil true false with :atom_not_allowed`, `domain rejects a tuple with :tuple_not_allowed`, `domain rejects a pid a reference and a port with :runtime_reference_not_allowed` and `domain rejects a function with :unsupported_term`, `domain reports the exact path of a deeply nested rejected term`, and the four new boundary-proof arms. |
| 20.15 resource limits | Demonstrated by the exact max-depth, max-nodes, max-string, max-object, max-array and max-bytes rejection arms; `domain checks depth before walking a term deep enough to exhaust the stack`; `canonical decoding checks the byte limit before parsing`; and `property every generated term exceeding a limit is rejected with that limit reason`. |
| 20.16 canonical-byte equality | Demonstrated by `equal? is canonical byte equality`. |
| 20.17 Commonplace.Log differential bytes | Demonstrated by `every differential case matches the bytes recorded from commonplace-log JCS`, with the empty-directory and 12-case-count arms. |
| 20.18 dependency hygiene | Demonstrated by `the application declares no runtime dependency outside the standard library` and `no module under lib references a higher Commonplace layer`. |
| 20.19 bounded Inspect | Demonstrated by `inspect shows bounded metadata rather than the entire value` and `inspect does not reveal a secret contained in the value`. |
| 20.20 anti-vacuity | Demonstrated by `each deliberate fixture is observed producing the outcome that fails a broken harness` and `every conformance directory is scanned by some harness`. |

All twenty §20 acceptance items have named green arms.

### Spec §24

- Independent implementations emitting identical bytes over the shared accepted corpus: **demonstrated over the 12 recorded differential cases** by `every differential case matches the bytes recorded from commonplace-log JCS`.
- Elixir callers treating constructed Values as proof rejected terms and bounded containers did not cross through the Value API: **demonstrated** by the category/path, resource-limit, and boundary-proof arms named above.
- Two independent implementations agreeing on **every pinned rejection**: **not demonstrated**. This repository contains no second implementation’s rejection results.
- “Small enough that its complete public contract can be audited directly”: **not demonstrated by an arm**. The module gate proves the library remains exactly nine declared modules, but it does not measure auditability.

Therefore §20 is closed, but the complete §24 statement is not fully demonstrated. The boundary proof remains cooperative/API-level; it does not prevent arbitrary same-VM code from bypassing the router with `send/2`.

