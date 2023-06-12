#!/usr/bin/env bash
set -euo pipefail

BUNDLE="$(basename $PWD).pdx"
pdc src/main.lua "$BUNDLE"
open "$BUNDLE"
