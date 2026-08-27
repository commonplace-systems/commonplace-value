#!/usr/bin/env bash
# ⛔ REFUSE TO START WITHOUT THE QUEUE'S PERMISSION, NOT MERELY THE BOX'S.
#
# WHY THIS IS A FILE AND NOT A HABIT. 2026-08-27: `suites == 0` is a
# TIME-OF-CHECK/TIME-OF-USE race, so every disciplined door observing it
# independently SYNCHRONISES on the same edge. Four suites started within seconds,
# each having honestly read zero. ⭐ THE DISCIPLINE IS WHAT CORRELATES THE STARTS.
#
# ⭐⭐ commonplace-log's sentence, which is the whole point: THE DIFFERENCE BETWEEN
# AGREEING WITH A RULING AND BEING UNABLE TO VIOLATE IT. commonplace-markdown's
# agreement at 18:30 was sincere and produced a collision; a token file produces the
# right outcome with no agreement required.
#
# ⭐ AND THE PROPERTY THAT MATTERS IS THE ONE THAT CAUGHT biscuit, NOT log:
# IT GATES THE SCRIPT, NOT YOUR CLASSIFICATION OF WHAT YOU ARE DOING.
# "I was thinking demonstrate a step and the thing I typed was start a suite."
# A token file cannot be talked out of noticing.
#
# ⚠️ STATED LIMIT, per commonplace-log and commonplace-markdown: THIS NARROWS THE
# HOLE, IT DOES NOT CLOSE IT. A bare `mix test` at a prompt calls nothing — which is
# exactly how commonplace-merkle-crdt's seven silent suites got out. It gates the
# scripts that call it and nothing else.
#
# ⚠️ AND IT IS THE LOCK, NOT THE INTERLOCK. The box check in bin/preflight-host.sh is
# the interlock. An empty box is permission from the HOST; the queue is permission
# from the ORDERING, and three doors read the first as the second tonight.
#
# Exit: 0 slot held · 76 no token.
# ⛔ `-e` DELIBERATELY ABSENT -- see the other gates in this directory.
set -uo pipefail
cd "$(dirname "$0")/.."
TOKEN=tmp/SLOT_GRANTED

if [ -f "$TOKEN" ]; then
  echo "slot: held$( [ -s "$TOKEN" ] && echo " ($(head -1 "$TOKEN"))" )"
  exit 0
fi
echo "REFUSED: no slot token at $TOKEN." >&2
echo "         The box being clear is permission from the HOST, not from the ORDERING." >&2
echo "         Create it only when the queue names this repo:  echo '<who granted, when>' > $TOKEN" >&2
exit 76
