#!/bin/sh
# Writes the Part file GFOpenUpTool INSTALL reads (gfopenup src/openuptool.c)
# for the part drawer the build made: C/mathomatic to C:mathomatic and
# Docs/Mathomatic/ to SYS:Docs/Mathomatic/.
#   write-part.sh <part drawer> <version>
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
P=$1; V=$2
{
    echo "part Mathomatic $V"
    echo "; Mathomatic: the computer algebra system (C:mathomatic); its plot command runs gnuplot (Parts/gnuplot)"
    echo "needs 68040"
    (cd "$P" && find C Docs -type f | LC_ALL=C sort) | while read -r f; do
        echo "copy \"$f\" \"SYS:$f\""
    done
} > "$P/Part"
