#!/usr/bin/env bash
# Gate: jes's filed specs are BYTE-IDENTICAL to their declared sha256.
#
# WHY THIS IS A FILE. Adapted from commonplace-doc-sync's copy of commonplace-dir's
# gate, which exists because an in-place edit to a filed spec failed only by a wrong
# patch anchor and was then reported as done. THIS repo's spec is jes's, was committed
# byte-identical at aac51f9, and is NEVER edited: amendments go in docs/spec-errata.md.
#
# Exit: 0 = all pristine · 1 = a spec changed · 2 = instrument blind (a declared
# file is missing, or the table below is empty). Both arms demonstrated in
# docs/IMPLEMENTATION-PLAN-P1.md.
# ⛔ `-e` IS DELIBERATELY ABSENT AND THAT IS LOAD-BEARING, NOT AN OVERSIGHT.
# This script reports on a corpus, so it MUST survive commands that legitimately
# return non-zero: `grep -c` on no match, a false `[ ]` in a `&&` chain, a diff that
# finds a difference. Under `set -e` several of those abort MID-REPORT, and the abort
# looks exactly like a clean early finish.
# ⚠️ commonplace-biscuit's rule: WHEN YOU CHECK AND COME BACK CLEAN, CHECK WHETHER YOUR
# CLEANLINESS IS LOAD-BEARING OR INCIDENTAL. Mine is load-bearing, and `set -e` is the
# single most natural hardening someone would later apply -- it would arm silently.
set -uo pipefail
cd "$(dirname "$0")/.."
# path <TAB> declared sha256 (full)
SPECS=$(cat <<'TSV'
docs/proposals/2026-08-24-commonplace-value-spec.md	1ac9a43741c75564937584c99dd7a22269ecb8ca2485d160c7a56f9727504966
docs/proposals/2026-08-25-value-composition-ruling.md	b0cc25b4078a18fe1013c94bcd3ed896e5812ce1f0f3b0e529fbf60c929a3d67
TSV
)
[ -n "$SPECS" ] || { echo "INSTRUMENT BLIND: no specs declared"; exit 2; }
changed=0
while IFS=$'\t' read -r path declared; do
  [ -f "$path" ] || { echo "INSTRUMENT BLIND: $path not found"; exit 2; }
  actual=$(sha256sum "$path" | cut -d' ' -f1)
  if [ "$actual" = "$declared" ]; then
    echo "  pristine $path"
  else
    echo "  CHANGED  $path (declared ${declared:0:16}, actual ${actual:0:16})"; changed=$((changed+1))
  fi
done <<< "$SPECS"
if [ "$changed" -eq 0 ]; then echo "VERDICT: PRISTINE -- every filed spec is byte-identical as declared"; exit 0; fi
echo "VERDICT: CHANGED -- $changed filed spec(s) edited. Amendments belong in docs/spec-errata.md." >&2
echo "VERDICT: CHANGED -- $changed filed spec(s) edited."; exit 1
