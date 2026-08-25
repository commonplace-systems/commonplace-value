# IMPLEMENTATION PLAN — round P6: determinism, differential bytes, boundary proof

**Work id: `VALUE-P6`. AND NO OTHER ID.**
**Round name, verbatim, as it appears in the dispatch prompt: `phase 6`.**

⭐ **This is the LAST planned round of 0.1.** It adds no public API. It hardens what exists and
closes the acceptance list in spec §20.

| shape | example | role — **not** this round's id |
| --- | --- | --- |
| the spec | §17 §18 §20 §21 §24 | never edited, gate-pinned |
| the ruling | composition | landed in P5. **Not this round** |
| previous rounds | `P1`–`P5`, main at `4d45c02` | the code you harden |
| `commonplace-log` | `ecd329f` | ⛔ **a fixture DONOR, and MUST NOT become a dependency** (§21). One arm proves it isn't |
| errata | `V13` | ⭐ **read it — it is about the harness you are writing** |

⭐ **If you need an id and only have those, that is a bug in my prompt: use `VALUE-P6` and say I
under-specified it.**

---

## 1. The ask

Four things, all from spec §20's acceptance list:

1. **§20.3** — construction followed by encoding is deterministic **across fresh OS processes**.
2. **§20.17 / §18** — values accepted by both this package and `Commonplace.Log.Jcs` emit identical
   bytes, checked over the **recorded fixtures** in `conformance/differential/`.
3. **§17 / §20.14** — a **boundary proof**: a small fixture router that accepts only
   `%Commonplace.Value{}`, with local pass-through and encoded round-trip equivalence, and proof
   that rejected BEAM terms cannot reach the receiver through the value API.
4. **§20.18** — **no runtime dependency** on `commonplace-log` or any higher Commonplace layer,
   proved rather than asserted.

⛔ **NO NEW PUBLIC API.** No `compose/2` changes, no new constructors, no `from_json/1`.

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
<!-- MODULE: Commonplace.Value.Pointer -->

⭐ **The expected diff creates NO new module under `lib/`.** The fixture router of §1.3 is **test
support** — §21 forbids this package depending on Cell or router implementations, so a router in
`lib/` would break a rule jes already filed. Put it under `test/support/`.

---

## 3. ⭐ MEASURED — including one trap I hit myself

| command | result | consequence |
| --- | --- | --- |
| `mix test` at `4d45c02` | `143 tests, 0 failures` | your baseline |
| differential vs `Commonplace.Log.Jcs`, 12 cases | **12 agree, 0 disagree** | ✅ the fixtures are already known-good; your harness must reproduce that |
| positive control: our key order switched to UTF-8 | **1 disagreement** | ✅ the check can fail |
| `grep -c 'Jason'` in their `jcs.ex` | 1, **in the moduledoc only** | their module is self-contained |

⛔ **THE TRAP, AND IT COST ME A FALSE ALARM — errata V13.** `conformance/differential/*/input.json`
is **canonical by construction**, so its door is **`from_canonical_json/2`**, NOT a permissive parse
plus `new/2`. Those doors do not share a numeric domain:

```text
input:                     [1e-7,0.000001,100000000000000000000,1e+21,0.000001]
JSON.decode + new/2   -> {:error, :integer_out_of_range}     ← §6.1, CORRECT
from_canonical_json/2 -> {:ok, ...}, re-encodes identically  ← §6.3, CORRECT
```

⭐ **`conformance/README.md` now carries a table of which directory uses which door. Follow it.**

⚠️ **AND A TOOLCHAIN TRAP FOR §1.1.** A fresh OS process must resolve `elixir` through `asdf`, which
reads `.tool-versions` **from the working directory**. I ran a script from a scratch directory and
got `No version is set for command elixir`. ⇒ **Spawn the child with the project root as its cwd**,
and ⛔ **if the spawn fails inside the fence, that is a FENCE FACT, not a defect — say so with the
headline `subprocess blocked in fence` and leave the arm red.** *A negative result from inside a
sandbox inherits the sandbox.*

---

## 4. Required arms

⭐ **FIRST DONE STEP: promote every `ARM-PLANNED:` below to `ARM:`, then COUNT them and report the
number.** *This brief states no count.*

⚠️ Per arm: the mutation that turned it red, via `bin/mutate.sh`. ⛔ Never `git checkout --`,
`git reset --hard`, or `git stash` — **anywhere** (V12).
⭐ **VACUITY HATCH: if an arm cannot be made to fail, SAY SO and leave it red.**

### 4.1 Determinism across fresh OS processes — §20.3

<!-- ARM: canonical bytes are identical when produced by a fresh operating system process -->
<!-- ARM: the whole positive corpus encodes identically in a fresh operating system process -->

⭐ **A second BEAM process in the SAME VM is not what §20.3 asks for.** The point is to defeat
anything a single VM instance could be carrying — a hash seed, a warmed atom table, an accident of
map iteration on one particular heap. **Spawn a real OS process** (`System.cmd/3` with `cd:` set to
the project root, per §3) and compare **emitted bytes**, not in-memory terms.
⚠️ *Comparing two values produced through shared code in one VM is the failure §19.3 names.*

### 4.2 Differential bytes — §18, §20.17

<!-- ARM: every differential case matches the bytes recorded from commonplace-log JCS -->
<!-- ARM: the differential harness refuses to report green on an empty directory -->
<!-- ARM: the differential harness checks at least twelve cases -->

⛔ **Read `conformance/README.md`'s `differential/` section before writing this.** In particular:
**a mismatch is a FINDING about both packages, not an instruction to change ours**, and ⛔ **never
regenerate those fixtures to make a red run green.** If your harness disagrees, **report it**.

### 4.3 The boundary proof — §17, §20.14

<!-- ARM: a router accepting only constructed values refuses an ordinary term -->
<!-- ARM: local pass through and encoded round trip deliver equal values -->
<!-- ARM: a pid cannot reach the receiver through the value API -->
<!-- ARM: a function or reference cannot reach the receiver through the value API -->

⭐ **§17's local fast path is the interesting half:** a router **MAY** pass the opaque value without
physically serializing it, and *"its meaning remains exactly the value that `encode/1` would
transmit."* ⇒ **Prove both routes deliver an `equal?/2` value** — that is what makes the fast path
legitimate rather than a shortcut.

⚠️ **Do not overclaim what the boundary proves.** Spec §17 and ruling §8.1 both say it: this package
**cannot** stop arbitrary Elixir code in the same VM bypassing a router with `send/2`, and opacity
is not a cryptographic seal. ⛔ **The arms are about what can cross THROUGH THE VALUE API**, not
about hostile code. **Say so in the test module's docstring.**

### 4.4 Dependency hygiene — §20.18, §21

<!-- ARM: the application declares no runtime dependency outside the standard library -->
<!-- ARM: no module under lib references a higher Commonplace layer -->

⭐ **Make the second one a real scan of `lib/`, counting what it searched**, not a grep whose zero
could mean "wrong path". ⚠️ *A grep against a path that does not exist returns 0 hits and looks
exactly like a confirmed absence — assert the corpus was non-empty first.*

### 4.5 Anti-vacuity across ALL FOUR directories — §19.3, §20.20

<!-- ARM: every conformance directory is scanned by some harness -->
<!-- ARM: each deliberate fixture is observed producing the outcome that fails a broken harness -->

⭐ **There are now THREE deliberate fixtures and they are not all the same shape:**

| fixture | expects | catches |
| --- | --- | --- |
| `canonical/999-deliberate-mismatch` | **mismatch** | a harness with a broken comparison |
| `valid-values/999-deliberate-mismatch-empty` | **mismatch** | a harness that never scanned this directory |
| `invalid-values/999-deliberate-acceptance` | ⛔ **ACCEPTANCE** | a rejection harness that refuses **everything** |

⚠️ **The third is inverted on purpose.** A harness that rejects every input passes every other case
in `invalid-values/`. ⭐ **Ask of each directory: what would a LAZY harness do, and which fixture
catches that?**

---

## 5. What I do NOT want

- ⛔ any new public API, or a change to `new/2`, `compose/2`, `encode/1`, `to_term/1`, `equal?/2`,
  `from_canonical_json/2`;
- ⛔ a router, Cell, or capability implementation **in `lib/`** — §21 forbids it. Test support only;
- ⛔ a dependency on `commonplace-log`, or vendoring its module;
- ⛔ **regenerating any fixture bytes**;
- ⛔ `JSON.encode!/1` in `lib/`;
- ⛔ changes under `bin/`, `docs/proposals/`, `mix.exs` deps, `.tool-versions`;
- ⛔ reformatting code you did not write.

---

## 6. Acceptance

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test                               # and note: a COLD run must emit ZERO warnings
for s in 1 2 3 4 5; do mix test --seed $s; done
bash bin/check-plan-arms.sh            # VERDICT: PASS
bash bin/check-plan-arms.sh --self-test
bash bin/check-spec-pristine.sh        # VERDICT: PRISTINE
bash bin/check-landing-refuses.sh      # VERDICT: PASS
```

```bash
grep -rho '^defmodule [A-Za-z0-9_.]*' lib/ | sort   # exactly the 9 declared modules, unchanged
git status --porcelain conformance/ | wc -l         # 0
ls -d conformance/*/ | wc -l                        # 4 directories
```

---

## 7. Report

1. **Per arm: the mutation that turned it red**, the failure line, and confirmation it perturbed the
   measured axis.
2. **How many markers you promoted, counted.**
3. ⭐ **How you spawned a fresh OS process, and whether the fence allowed it.** If not:
   `subprocess blocked in fence`, arm left red.
4. **Any differential disagreement** — reported, never fixed by editing a fixture.
5. ⭐ **A COMPLETION ASSESSMENT against spec §20's twenty acceptance items and §24's completion
   criteria:** which are now demonstrated, by which arm **named**, and which are not. ⛔ **Do not
   claim an item without naming the arm** — that is this repo's whole method (`docs/STATE.md` §1).
6. Any module created and whether it was on the `MODULE:` list.
7. Verbatim output of every command in §6.
8. ⚠️ **You probably cannot commit** (`.git` read-only). Leave the work in the tree and say so.
