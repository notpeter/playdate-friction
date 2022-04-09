#!/usr/bin/env bash
# playdate.bash

set -euo pipefail

export PLAYDATE_SDK_PATH="$HOME/Developer/PlaydateSDK/"

: ${1?"Usage: $0 main.lua [whatever.pdx]"}

WHATEVER="/tmp/whatever.pdx"
MAINLUA="${1}"
OUTPDX="${2-$WHATEVER}"

"$PLAYDATE_SDK_PATH/bin/pdc" $MAINLUA $OUTPDX
#open "$PLAYDATE_SDK_PATH/bin/Playdate Simulator.app" $OUTPDX
open "$OUTPDX"
