# What build-amiga.sh (the stove) and tests/host-matho.sh (the PC) share:
# fetching Mathomatic and applying patches/. Sourced; needs HERE (the repo)
# and mathomatic.lock's settings.
# MIT, Copyright (c) 2026 AmiCradle Team.

# Mathomatic's program, as upstream's makefile (MATHOMATIC_OBJECTS)
MATHO_SRCS="main.c globals.c am.c solve.c help.c parse.c cmds.c simplify.c
 factor.c super.c unfactor.c poly.c diff.c integrate.c complex.c complex_lib.c
 list.c gcd.c factor_int.c"

# a repository at one commit, fetched once: fetch_at DIR URL COMMIT
fetch_at() {
    if [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "${1:?}"; mkdir -p "$1"
        git -C "$1" init -q
        git -C "$1" fetch -q --depth 1 "$2" "$3"
        git -C "$1" checkout -q FETCH_HEAD
        [ "$(git -C "$1" rev-parse HEAD)" = "$3" ] || { echo "$1: commit mismatch"; exit 1; }
    fi
}

# Mathomatic at MATHO_COMMIT with patches/ applied, into $1 (redone when either changes)
matho_source() {
    PSUM=$(cat "$HERE"/patches/*.patch | sha256sum | cut -c1-16)
    if [ "$(cat "$1/.patched" 2>/dev/null)" != "$MATHO_COMMIT-$PSUM" ]; then
        rm -rf "$1"
        fetch_at "$1" "$MATHO_GIT" "$MATHO_COMMIT"
        for p in "$HERE"/patches/*.patch; do
            patch -s -d "$1" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
        done
        echo "$MATHO_COMMIT-$PSUM" > "$1/.patched"
    fi
}
