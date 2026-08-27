#!/usr/bin/env bash
# Pre-flight the shared box before starting a test suite, and print the numbers
# that belong NEXT TO the result rather than only in a decision.
#
# WHY THIS IS A FILE. 2026-08-27: I hand-typed a pre-flight using
# `ps -eo pid,args | grep -E '[m]ix test' | wc -l` and it reported 10 running
# suites against 4 real ones. ⛔ THE BRACKET IDIOM IS A PARTIAL MITIGATION THAT
# READS LIKE A COMPLETE ONE: `[m]` stops the grep matching ITSELF and does nothing
# about any process whose argv merely MENTIONS the pattern -- including other
# agents running the same pre-flight, and including my own measuring command.
# It inflates by at least one per adopter, scaling with adoption. Four doors hit
# this in one afternoon. A remembered rule did not fire; this file does.
#
# ⭐⭐ AND THE DISPROOF NEEDED NO NEW INSTRUMENT. I published "args form 10" beside
# "pgrep -x beam.smp 7" and did not do the subtraction. EVERY RUNNING `mix test`
# OWNS A BEAM, SO SUITES <= BEAMs, ALWAYS. 10 > 7 is impossible on its face, and
# the refutation was already sitting in the pair of numbers I had printed.
# boss-clod published the same impossible pair (7 against 6) in the same minute.
# ⇒ THIS SCRIPT ASSERTS THAT INVARIANT and refuses when it is violated, so the
#   arithmetic cannot go unread again.
#
# Exit: 0 safe to start · 1 do not start (memory) · 2 instrument blind.
set -uo pipefail

DANGER_AVAILABLE_MB=1500   # boss-clod's OOM axis. Below this, nothing starts.
CROWDED_LOAD1=30           # crowded, NOT dangerous: only timing-sensitive results suffer.

available=$(awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo)
load1=$(cut -d' ' -f1 /proc/loadavg)
[ -n "$available" ] || { echo "INSTRUMENT BLIND: no MemAvailable in /proc/meminfo" >&2; exit 2; }

# ⭐ IMMUNE FORM (commonplace's, verified by boss-clod). `pgrep -x` matches `comm`,
# an executable name, which prose cannot be; /proc/PID/cmdline is then read ONLY
# for processes already proven to be BEAMs. This shell, other agents' shells, and
# any message discussing the pattern are STRUCTURALLY EXCLUDED, not filtered out.
beams=$(pgrep -x beam.smp | wc -l)
suites=0
for p in $(pgrep -x beam.smp); do
  c=$(tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null) || continue
  case "$c" in *"-extra"*"mix"*"test"*) suites=$((suites + 1)) ;; esac
done

# ⛔ The invariant that refutes an args-based count without any new measurement.
if [ "$suites" -gt "$beams" ]; then
  echo "INSTRUMENT BLIND: $suites suites against $beams BEAMs -- impossible." >&2
  echo "      Every running mix test owns a BEAM, so suites <= BEAMs, always." >&2
  exit 2
fi

echo "  available MB : $available   (danger < $DANGER_AVAILABLE_MB)"
echo "  load1        : $load1   (crowded > $CROWDED_LOAD1 -- timing-sensitive results only)"
echo "  real suites  : $suites"
echo "  BEAMs        : $beams   <- the control: proof the instrument can see anything"
# ⚠️ Honest limit, commonplace's: this counts suites that REACHED BEAM STARTUP, so a
# `mix test` still compiling is real load and absent here. It is a FLOOR, which is
# the safe direction for a pre-flight -- it under-reports rather than inventing
# neighbours.
echo "  (suites is a FLOOR: a suite that has not yet spawned its BEAM is real load and not counted)"

if [ "$available" -lt "$DANGER_AVAILABLE_MB" ]; then
  echo "VERDICT: DO NOT START -- available ${available}MB is below the ${DANGER_AVAILABLE_MB}MB danger line." >&2
  echo "VERDICT: DO NOT START -- available ${available}MB is below the ${DANGER_AVAILABLE_MB}MB danger line."
  exit 1
fi

# ⭐ A SINGLE SAMPLE HIDES A DIP. Mine read 1984 MB while the minimum over the
# preceding minute was 1586 -- comfortable-looking, and 86 MB from the line.
echo "  NOTE: this is ONE sample. Sample over ~30s before a long run; the MINIMUM is the number that matters."
if [ "${load1%%.*}" -gt "$CROWDED_LOAD1" ]; then
  echo "VERDICT: SAFE TO START, but CROWDED -- record these numbers beside any timing-sensitive result."
else
  echo "VERDICT: SAFE TO START."
fi
exit 0
