#!/bin/sh
# PC test for scripts/write-part.sh: the Part file GFOpenUpTool reads.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/C" "$T/Docs/Mathomatic"
: > "$T/C/mathomatic"; : > "$T/Docs/Mathomatic/ReadMe"; : > "$T/Docs/Mathomatic/COPYING"
sh "$HERE/../scripts/write-part.sh" "$T" 16.0.5
fail=0
expect() { grep -qxF "$1" "$T/Part" || { echo "FAIL: no line: $1"; fail=1; }; }
expect 'part Mathomatic 16.0.5'
expect 'needs 68040'
expect 'copy "C/mathomatic" "SYS:C/mathomatic"'
expect 'copy "Docs/Mathomatic/ReadMe" "SYS:Docs/Mathomatic/ReadMe"'
expect 'copy "Docs/Mathomatic/COPYING" "SYS:Docs/Mathomatic/COPYING"'
[ "$(head -1 "$T/Part")" = 'part Mathomatic 16.0.5' ] || { echo "FAIL: first line"; fail=1; }
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: file count (the Part file itself must not be listed)"; fail=1; }
sh "$HERE/../scripts/write-part.sh" "$T" 16.0.5   # a second run: the same file
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: second run lists the Part file"; fail=1; }
[ $fail = 0 ] && echo "Part file: all checks passed"
exit $fail
