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
set -uo pipefail
cd "$(dirname "$0")/.."
# path <TAB> declared sha256 (full)
SPECS=$(cat <<'TSV'
docs/proposals/2026-08-24-commonplace-value-spec.md	1ac9a43741c75564937584c99dd7a22269ecb8ca2485d160c7a56f9727504966
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
