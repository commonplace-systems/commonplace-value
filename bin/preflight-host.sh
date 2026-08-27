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
# ⛔ `-e` IS DELIBERATELY ABSENT AND THAT IS LOAD-BEARING, NOT AN OVERSIGHT.
# This script reports on a corpus, so it MUST survive commands that legitimately
# return non-zero: `grep -c` on no match, a false `[ ]` in a `&&` chain, a diff that
# finds a difference. Under `set -e` several of those abort MID-REPORT, and the abort
# looks exactly like a clean early finish.
# ⚠️ commonplace-biscuit's rule: WHEN YOU CHECK AND COME BACK CLEAN, CHECK WHETHER YOUR
# CLEANLINESS IS LOAD-BEARING OR INCIDENTAL. Mine is load-bearing, and `set -e` is the
# single most natural hardening someone would later apply -- it would arm silently.
set -uo pipefail

# ⭐⭐ DEFER TO THE OWNER OF THE AXIS. boss-clod owns memory and load and has filed
# boss-clod/box-health.sh. commonplace-log-reducer made the coordination point:
# "a filed artifact fires" argues for filing it SOMEWHERE, and the right somewhere is
# whoever owns the shared runner -- not five repos each with a private copy that
# drifts. We spent this evening proving what five cp'd copies of one script do.
# ⛔ AND MY OWN COPY HAD ALREADY DRIFTED: my threshold was 1500 where his is 2500, so
# my gate printed SAFE TO START at a headroom his refuses. That is the
# two-sources-of-truth defect with a 1000 MB gap, in the tool I wrote to avoid
# guessing. plan ruled the same mismatch for yelixer: take the owner's number.
BOSS_HEALTH=/home/jes/boss-clod/box-health.sh
if [ -f "$BOSS_HEALTH" ]; then
  # ⛔ VERIFY THE OWNER'S TOOL ACTUALLY RAN. Deferring to a LIVE file in another repo
  # means my gate's behaviour depends on someone else's editing state -- and it bit
  # immediately: at 18:25 I deferred and got THEIR syntax error at line 131, mid-edit.
  # Two minutes later the same file ran clean (they had landed 0540457).
  # ⚠️ A non-zero rc is NOT the discriminator: BLIND rc=2 is a legitimate verdict from
  # their tool. The discriminator is whether it EMITTED A VERDICT AT ALL. ⭐ Same rule
  # as everywhere else tonight: UNPARSEABLE MUST NOT LOOK LIKE A RESULT.
  # ⭐ Capture once, read the capture many times -- do not re-invoke for the rc.
  # ⭐ PUBLISH THE REFERENT. boss-clod publishes the sha of this tool, and warned that
  # anyone who copied it mid-write holds TORN BYTES that `bash -n` will happily pass --
  # the wrong-referent class in a new costume: not the wrong file, the right file at
  # the wrong instant. I invoke it live rather than copying, so a torn read shows up as
  # "no verdict emitted" below. ⇒ But the box line must say WHICH BYTES ANSWERED, so a
  # reader can compare against what the owner published instead of assuming.
  health_sha=$(sha256sum "$BOSS_HEALTH" 2>/dev/null | cut -c1-16)
  health_out=$(bash "$BOSS_HEALTH" 2>&1); health_rc=$?
  if printf '%s\n' "$health_out" | grep -q '^\(BOX\||VERDICT|\)'; then
    echo "  deferring to the axis owner: $BOSS_HEALTH (sha ${health_sha:-unreadable})"
    printf '%s\n' "$health_out"
    exit "$health_rc"
  fi
  echo "  ⛔ $BOSS_HEALTH produced no BOX/VERDICT line (rc=$health_rc) -- it may be mid-edit." >&2
  printf '%s\n' "$health_out" | head -3 | sed 's/^/     | /' >&2
  echo "  ⇒ NOT treating that as a verdict. Falling back to this repo's local copy," >&2
  echo "    whose numbers may have drifted from the owner's. Tell the owner." >&2
fi
echo "  ⚠️ $BOSS_HEALTH not found -- falling back to this repo's local copy."
echo "     Its numbers may have drifted from the owner's. Prefer the owner's tool."

# ⛔⛔ GATE ON WHAT THE RUN NEEDS, REPORT THE RESERVE AS INFORMATION -- doc-sync's
# split, adopted by boss-clod after his 2500 floor proved UNREACHABLE. Reporting and
# gating are different jobs and one number was doing both.
# ⚠️ MY FALLBACK HAD THE UNREACHABLE FORM AND I ONLY FOUND IT BY TESTING IT:
#     best available seen 4429 - reserve (VmHWM 2854 - rss ~350) = 1925 achievable
#     my floor                                                   = 2500
# ⇒ it could never go green. AND IT LIVES IN THE PATH THAT ONLY RUNS WHEN THE
# OWNER'S TOOL IS BROKEN, so it would never be exercised on a normal day and would
# refuse forever exactly when it is the only instrument left.
FLOOR_MB=1500        # what must remain after a suite
SUITE_COST_MB=500    # what one suite here costs
CROWDED_LOAD1=30           # crowded, NOT dangerous: only timing-sensitive results suffer.

available=$(awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo)
MEMTOTAL_MB=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
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

# ⛔ THE SERVE OSCILLATES BY MORE THAN THE ENTIRE DANGER MARGIN. Same pid, never
# restarted, five readings on 2026-08-27: 2605 → 385 → 317 → 2768 → 298 MB. Four
# reversals, range 2451 MB, driven by nothing the fleet does. ⇒ `available` alone
# can read GREEN because the serve happened to page OUT and RED because it paged
# IN. boss-clod's revised criterion judges on the PESSIMISTIC figure: the headroom
# left if it faults its pages back mid-run, which it did once inside fourteen
# minutes.
#
# ⛔⛔ AND THE OBVIOUS LOOKUP SELF-MATCHES. `pgrep -f commonplace-serve-pin`
# returned MY OWN SHELL (comm=bash, rss 3 MB) because my command line contained
# the path, plus the serve's tailwind and esbuild sidecars -- so `head -1` had a
# 3-in-4 chance of a wrong process, and the one it picked made the pessimistic
# figure look ~300 MB WORSE than it is. ⭐ Sixth instance today of matching a
# string I also typed, and the FIRST that pointed toward false alarm rather than
# false comfort.
# ✅ Enumerate by comm, then confirm with a kernel fact the shell cannot fake.
# ⭐ USE VmHWM, NOT THE HIGHEST SAMPLE ANYONE HAPPENED TO CATCH -- commonplace-biscuit.
# 2768 was a READING; VmHWM is a kernel-maintained HIGH-WATER MARK that only moves
# up. ⇒ the pessimistic figure stops depending on who was looking when the serve
# peaked, and is slightly more conservative. A PROPERTY rather than a sample.
# The constant remains only as a floor for the case where VmHWM cannot be read.
SERVE_PEAK_FALLBACK_MB=2768
serve_rss=0; serve_pid=""; serve_hwm=0
for p in $(pgrep -x beam.smp); do
  case "$(readlink "/proc/$p/cwd" 2>/dev/null)" in
    *commonplace-serve-pin)
      serve_pid=$p
      serve_rss=$(awk '/VmRSS/{print int($2/1024)}' "/proc/$p/status" 2>/dev/null)
      serve_hwm=$(awk '/VmHWM/{print int($2/1024)}' "/proc/$p/status" 2>/dev/null)
      ;;
  esac
done
# ⛔ AN UNVERIFIED /proc READ MUST NOT RESOLVE TO A NUMBER AT ALL. commonplace-log hit
# this inside its own fix (sentinel -1 for both terms gave `available - (-1 - -1)` =
# available) and commonplace-markdown hit it adopting that fix (empty terms are 0 in
# bash arithmetic, so a FAILED read printed headroom == available -- the most
# flattering answer possible, from no measurement).
# ⚠️ MY DIRECTION HAPPENS TO BE CONSERVATIVE -- an empty rss reads as 0 and inflates
# the reserve -- but "happens to be" is exactly why it needs saying. A pid can be
# found AND the read still fail, and those two absences do not share a code path.
if [ -n "$serve_pid" ] && ! printf '%s\n' "$serve_rss" | grep -q '^[0-9][0-9]*$'; then
  echo "  serve rss MB : ⛔ UNREADABLE for pid $serve_pid -- headroom UNVERIFIABLE, computing nothing." >&2
  echo "VERDICT: BLIND -- the serve was found but its /proc read failed." >&2
  exit 2
fi
if [ -n "$serve_pid" ]; then
  peak=${serve_hwm:-0}
  [ "$peak" -lt "$SERVE_PEAK_FALLBACK_MB" ] && peak=$SERVE_PEAK_FALLBACK_MB
  pessimistic=$((available - (peak - serve_rss)))
else
  pessimistic=$available
fi

echo "  available MB : $available   (need > $((FLOOR_MB + SUITE_COST_MB)) to seat a ${SUITE_COST_MB}MB suite)"
if [ -n "$serve_pid" ]; then
  echo "  serve rss MB : $serve_rss   (pid $serve_pid, by comm+cwd -- never by pattern)"
  # ⛔⛔ VmHWM IS MONOTONIC AND THAT MAKES IT A RATCHET -- commonplace, correcting
  # biscuit's fix which I adopted twenty minutes ago. It only ever moves UP and
  # nothing resets it short of a process restart. This serve has been up 3d 21h, so
  # 2855 may be a peak from days ago, and if it ever touches 5 GB for one minute the
  # fleet reserves 5 GB PERMANENTLY -- including on every future quiet night.
  # ⇒ THAT IS `swap free > 1000 MB` ARRIVING BY ANOTHER ROUTE: a criterion whose
  # green arm gets harder to reach over time, which nobody notices is drifting
  # because each individual reading is defensible.
  # ✅ Fix is not a redesign, it is PRINTING ALL THREE so the ratchet is READABLE.
  # A reserve that has quietly grown from 2.5 GB to 4 GB shows up in the output
  # instead of being an invisible drift. Same shape as the two-constants rule: a
  # single number has nothing to disagree with.
  echo "  serve VmHWM  : ${serve_hwm}MB   <- the most it has EVER held SINCE IT STARTED,"
  echo "                          not the most it holds. Monotonic; diverges further each day it stays up."
  echo "  RESERVE      : $((peak - serve_rss))MB   <- VmHWM minus current rss. WATCH THIS NUMBER GROW."
  echo "  PESSIMISTIC  : $pessimistic   = available - reserve"
else
  echo "  serve rss MB : NOT FOUND -- pessimistic figure unavailable, treating available as-is"
fi
echo "  load1        : $load1   (crowded > $CROWDED_LOAD1 -- timing-sensitive results only)"
echo "  real suites  : $suites"
echo "  BEAMs        : $beams   <- the control: proof the instrument can see anything"
# ⚠️ Honest limit, commonplace's: this counts suites that REACHED BEAM STARTUP, so a
# `mix test` still compiling is real load and absent here. It is a FLOOR, which is
# the safe direction for a pre-flight -- it under-reports rather than inventing
# neighbours.
echo "  (suites is a FLOOR: a suite that has not yet spawned its BEAM is real load and not counted)"

# ⭐⭐ REACHABILITY SELF-CHECK, AND IT MUST TEST THE CRITERION ACTUALLY GATED ON.
# commonplace-log's self-check tested a STRICTER criterion than the one it guarded
# (it still subtracted the reserve after the gate had stopped doing so) and produced
# a FALSE REFUSAL -- which nearly stood, because four true unreachable-gate findings
# had just been published and "confirmed at a fifth door" was the expected shape.
# ⛔ A RED THAT AGREES WITH A TRUE FINDING SOMEONE ELSE JUST PUBLISHED IS THE HARDEST
# KIND TO DOUBT, and a spurious refusal fails silently in the safe direction.
# ⇒ So this tests `available - SUITE_COST > FLOOR`, the exact expression below.
if [ $((MEMTOTAL_MB - SUITE_COST_MB)) -le "$FLOOR_MB" ]; then
  echo "VERDICT: BLIND -- UNREACHABLE CRITERION: FLOOR($FLOOR_MB) + SUITE_COST($SUITE_COST_MB)" >&2
  echo "         >= MemTotal($MEMTOTAL_MB). This gate can never go green." >&2
  exit 2
fi

if [ $((available - SUITE_COST_MB)) -le "$FLOOR_MB" ]; then
  echo "VERDICT: DO NOT START -- ${available}MB available leaves $((available - SUITE_COST_MB))MB" >&2
  echo "         after a ${SUITE_COST_MB}MB suite, at or below the ${FLOOR_MB}MB floor." >&2
  echo "VERDICT: DO NOT START -- would leave $((available - SUITE_COST_MB))MB, floor ${FLOOR_MB}MB."
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
