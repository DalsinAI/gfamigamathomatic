#!/bin/sh
# Builds Mathomatic, the computer algebra system, for GFOS (AmigaOS 3.2.3
# with GFOpenUp) with a stove: 68040, soft float with the FPU taken when
# there is one (fpuauto).
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# Mathomatic and fpuauto are fetched at the commits mathomatic.lock gives;
# nothing third-party is kept here. The PC tests (tests/host-matho.sh:
# Mathomatic's own test suite on the same sources) run first when there is
# a PC compiler; HOST_TESTS=0 skips them.
# OUT gets Parts/Mathomatic: a GFOpenUp part (its Part file, C:mathomatic,
# the manual and licence in SYS:Docs/Mathomatic), installed with
#   GFOpenUpTool INSTALL Parts/Mathomatic
# and tests/: Mathomatic's test files, for mathomatic -t all in a lab.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/mathomatic.lock"
. "$HERE/scripts/matho-common.sh"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK="${WORK:-$HOME/.cache/gfamigamathomatic/build}"; OUT="${OUT:-$WORK/out}"; JOBS=${JOBS:-8}
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK/deps" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)

# --- the PC tests first: the same sources, Mathomatic's own test suite --------
if [ "${HOST_TESTS:-1}" != 0 ] && command -v "${HOST_CC:-cc}" > /dev/null 2>&1; then
    WORK="$WORK/host" sh "$HERE/tests/host-matho.sh" > "$WORK/host-tests.log" 2>&1 || { tail -40 "$WORK/host-tests.log"; exit 1; }
    grep -E "matches|checks passed" "$WORK/host-tests.log"
fi

# --- fpuauto: libfpuauto.a and its link specs ---------------------------------
FPD="$WORK/deps/fpuauto"
if [ "$(git -C "$FPD" rev-parse HEAD 2>/dev/null)" != "$FPA_COMMIT" ]; then
    rm -rf "$FPD"; mkdir -p "$FPD"; git -C "$FPD" init -q
    git -C "$FPD" config core.sparseCheckout true
    echo "/common/fpuauto/" > "$FPD/.git/info/sparse-checkout"
    git -C "$FPD" fetch -q --depth 1 --filter=blob:none "$FPA_REPO" "$FPA_COMMIT"
    git -C "$FPD" checkout -q FETCH_HEAD
fi
FA="$FPD/common/fpuauto"; FAL="$WORK/fpuauto"
if [ ! -f "$FAL/libfpuauto.a" ] || [ "$(cat "$FAL/.rev" 2>/dev/null)" != "$FPA_COMMIT" ]; then
    rm -rf "$FAL"; mkdir -p "$FAL/obj"
    m68k-amigaos-gcc -m68040 -DFPUAUTO_COMMON -c "$FA/fpuauto.S" -o "$FAL/obj/fa_common.o"
    for n in $(sed 's/^--wrap=//' "$FA/fpuauto.wraps"); do
        m68k-amigaos-gcc -m68040 -DR_$n -c "$FA/fpuauto.S" -o "$FAL/obj/fa_$n.o"
    done
    m68k-amigaos-ar rcs "$FAL/libfpuauto.a" "$FAL"/obj/fa_*.o
    echo "$FPA_COMMIT" > "$FAL/.rev"
fi

# --- Mathomatic at its pinned commit, with patches/ ----------------------------
SRC="$WORK/mathomatic"
matho_source "$SRC"
LINK="m68k-amigaos-gcc -noixemul -m68040 -specs=$HERE/scripts/m68k-soft-m68040.specs -specs=$FA/fpuauto.specs -L$FAL"

# --- compile -------------------------------------------------------------------
LATE=""
if m68k-amigaos-gcc -fno-late-combine-instructions -S -o /dev/null -x c /dev/null 2>/dev/null; then LATE="-fno-late-combine-instructions"; fi
# no loops turned into memset/memcpy calls (GCC 16), address 0 is memory
CF="-std=gnu99 -noixemul -m68040 -O2 -fno-tree-loop-distribute-patterns -fno-delete-null-pointer-checks $LATE \
 -Werror=implicit-function-declaration -Werror=int-conversion -w \
 -DAMIGA=1 -DUSE_TGAMMA=1 -Dtgamma=amiga_tgamma -DVERSION=\\\"$MATHO_VERSION\\\" -I$HERE/amiga -I$SRC \
 -DMATHO_AMIGA_VERSION=\\\"$MATHO_VERSION\\\" -DMATHO_AMIGA_DATE=\\\"$(date -u +%d.%m.%Y)\\\""
O="$WORK/obj"
# objects made against another Mathomatic or patch set go
[ "$(cat "$O/.src" 2>/dev/null)" = "$(cat "$SRC/.patched")" ] || { rm -rf "$O"; mkdir -p "$O"; cat "$SRC/.patched" > "$O/.src"; }
M="$O/Makefile"
{
    echo "CF = $CF"
    A=""
    for f in $MATHO_SRCS; do
        o="$(echo "$f" | sed 's/\.c$/.o/')"; A="$A $o"
        printf '%s: %s\n\tm68k-amigaos-gcc $(CF) -MMD -c $< -o $@\n' "$o" "$SRC/$f"
    done
    for f in amiga_matho amiga_sys; do
        A="$A $f.o"
        printf '%s.o: %s\n\tm68k-amigaos-gcc $(CF) -MMD -c $< -o $@\n' "$f" "$HERE/amiga/$f.c"
    done
    echo "OBJS =$A"
    echo "all: \$(OBJS)"
    echo "-include *.d"
} > "$M"
(cd "$O" && nice -n 19 make -k -j"$JOBS" all > make.log 2>&1) || { grep -E 'error' "$O/make.log" | head -40; tail -20 "$O/make.log"; exit 1; }
echo "compile: $(( $(date +%s) - t0 )) s"

# --- link: soft-float specs, then fpuauto's ------------------------------------
# shellcheck disable=SC2046
$LINK -o "$O/mathomatic.debug" $(cd "$O" && for f in $(sed -n 's/^OBJS =//p' Makefile); do echo "$O/$f"; done) \
    -lm > "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }

# --- the GFOpenUp part: Parts/Mathomatic ------------------------------------------
P="$OUT/Parts/Mathomatic"; D="$P/Docs/Mathomatic"; rm -rf "$P"; mkdir -p "$P/C" "$D"
m68k-amigaos-strip -o "$P/C/mathomatic" "$O/mathomatic.debug"
cp "$HERE/README.md" "$D/ReadMe"
cp "$SRC/COPYING" "$D/COPYING"
cp "$SRC/AUTHORS" "$D/AUTHORS"
cp "$SRC/mathomatic.1" "$D/mathomatic.1"
for f in manual.html am.html quickrefcard.html doc.css fdl-1.3-standalone.html; do
    cp "$SRC/doc/$f" "$D/$f"
done
sh "$HERE/scripts/write-part.sh" "$P" "$MATHO_VERSION"
# Mathomatic's test files, for "mathomatic -t all" in a lab (not in the part)
rm -rf "$OUT/tests"; mkdir -p "$OUT/tests"
cp -R "$SRC"/tests/. "$OUT/tests/"
ls -l "$P/C/mathomatic"
echo "part: $(grep -c '^copy' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "fpuauto: $(m68k-amigaos-nm "$O/mathomatic.debug" | grep -c ' T ___wrap_') wrapped routines"
echo "total: $(( $(date +%s) - t0 )) s"
