#!/usr/bin/env bash
# playdate.bash

set -euo pipefail
#set -x

DATETIME="$(date +%Y-%m-%d_%H%M%S).pdx"

: ${1?"Usage: $0 [docker] srcdir [buildir]"}
SRC_DIR="${1}"
BUILD_DIR="${2-}"

if [[ -d "$SRC_DIR" ]]; then
    SRC_DIR="$(realpath $SRC_DIR)"
else
    echo "$SRC_DIR: directory not found."
    false
fi

if [[ -f "$SRC_DIR/pdxinfo" ]]; then
    PROJECT="$(grep -m1 'bundleID=' src/pdxinfo |awk -F '=' '{ print $2 }' )"
    VERSION="$(grep -m1 'version=' src/pdxinfo |awk -F '=' '{ print $2 }' )"
    BUILD="$(grep -m1 'buildNumber=' src/pdxinfo |awk -F '=' '{ print $2 }' )"
    FILENAME="${PROJECT}_${VERSION}-build${BUILD}_$(date +%Y-%m-%d_%H%M%S).pdx"
else
    FILENAME="playdate_$(date +%Y-%m-%d_%H%M%S).pdx"
fi


if [[ -z "$BUILD_DIR" ]]; then
    if [[ -d "$SRC_DIR/../build" ]]; then
	BUILD_DIR="$(realpath $SRC_DIR/../build)"
    else
	BUILD_DIR="/tmp/playdate"
	mkdir -p "$BUILD_DIR"
    fi
fi

function macos_build {
    export PLAYDATE_SDK_PATH="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK/}"
    MAINLUA="$SRC_DIR/main.lua"
    OUTPDX="$BUILD_DIR/$FILENAME"
    "$PLAYDATE_SDK_PATH/bin/pdc" $MAINLUA $OUTPDX
}

function docker_build {
    DOCKER_TAG="playdate"
    OUTPDX="$BUILD_DIR/$FILENAME"
    docker run \
       --mount "type=bind,source=$BUILD_DIR,target=/app/build" \
       --mount "type=bind,source=$(realpath $SRC_DIR),target=/app/src/,readonly" \
       -it $DOCKER_TAG bash -c "pdc /app/src /app/build/$FILENAME"

}

macos_build
# docker_build
echo "$OUTPDX"
open "$OUTPDX"
