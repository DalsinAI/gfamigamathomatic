#!/bin/sh
# Builds Mathomatic for the PC from the same patched sources the stove
# builds, as AmigaOS sees them (AMIGA=1, no UNIX: no ioctl, alarm or
# readline), with tests/host_system.c in place of SystemTags(), then runs:
#  - Mathomatic's own test suite (tests/all.in) against all.out;
#  - plot: the script in T:mathomatic.plt and the gnuplot command line;
#  - set save with no HOME: the startup file is ENVARC:mathomatic.rc, and it
#    is read back at the next start.
#   WORK=... sh tests/host-matho.sh
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$HERE/mathomatic.lock"
. "$HERE/scripts/matho-common.sh"
WORK="${WORK:-$HERE/build-host}"; CC="${HOST_CC:-cc}"
mkdir -p "$WORK"; WORK=$(cd "$WORK" && pwd)
SRC="$WORK/mathomatic"
matho_source "$SRC"
B="$WORK/bin"; rm -rf "$B"; mkdir -p "$B"
# shellcheck disable=SC2086
(cd "$SRC" && $CC -std=gnu99 -O2 -w -DAMIGA=1 -DVERSION=\"$MATHO_VERSION\" -I"$HERE/amiga" \
    $MATHO_SRCS "$HERE/amiga/amiga_matho.c" "$HERE/tests/host_system.c" -lm -o "$B/mathomatic")
M="$B/mathomatic"
fail=0
"$M" -v | grep -q "$MATHO_VERSION" || { echo "FAIL: version"; fail=1; }
echo "version status" | "$M" -q 2>&1 | grep -q "Compile-time defines used:.* AMIGA" || { echo "FAIL: version status doesn't list AMIGA"; fail=1; }

# Mathomatic's own tests, as its makefile's "make check"
(cd "$SRC/tests" && "$M" -t all 0<&- > "$WORK/test.out") || { echo "FAIL: test run"; fail=1; }
if diff -u --strip-trailing-cr "$SRC/tests/all.out" "$WORK/test.out" > "$WORK/test.diff"; then
    echo "test suite: all.out matches ($(grep -c "^read" "$SRC/tests/all.in") test scripts)"
else
    head -40 "$WORK/test.diff"; echo "FAIL: test suite differs"; fail=1
fi

# plot: a 2D and a 3D plot through T:mathomatic.plt
T="$WORK/run"; rm -rf "$T"; mkdir -p "$T"
LOG="$T/system.log"
(cd "$T" && printf 'y=x^2+1\nplot\nz=x*y\nplot\n' | env -u HOME MATHO_SYSTEM_LOG="$LOG" "$M" -q > "$T/plot.out" 2>&1) || true
[ "$(grep -c '^gnuplot -persist T:mathomatic.plt$' "$LOG" 2>/dev/null)" = 2 ] || { echo "FAIL: gnuplot command line"; cat "$LOG" 2>/dev/null; fail=1; }
grep -q '^splot ' "$T/T:mathomatic.plt" || { echo "FAIL: 3D plot script"; cat "$T/T:mathomatic.plt"; fail=1; }
grep -q 'set grid' "$T/T:mathomatic.plt" || { echo "FAIL: plot prefix"; fail=1; }
grep -q '3D surface plot' "$T/plot.out" && grep -q '2D plot' "$T/plot.out" || { echo "FAIL: plot messages"; cat "$T/plot.out"; fail=1; }
[ $fail = 0 ] && echo "plot: script and gnuplot command line right"

# set save with no HOME: ENVARC:mathomatic.rc, read back at the next start
(cd "$T" && printf 'set precision 10\nset save\n' | env -u HOME "$M" > "$T/save.out" 2>&1) || true
[ -f "$T/ENVARC:mathomatic.rc" ] && grep -q 'precision = 10 digits' "$T/ENVARC:mathomatic.rc" || { echo "FAIL: set save"; cat "$T/save.out"; fail=1; }
(cd "$T" && printf 'quit\n' | env -u HOME "$M" 2>&1 | grep -q 'Loading startup set options from "ENVARC:mathomatic.rc"') || { echo "FAIL: startup file not read back"; fail=1; }
[ $fail = 0 ] && echo "startup file: ENVARC:mathomatic.rc saved and read back"
[ $fail = 0 ] && echo "host tests: all checks passed"
exit $fail
