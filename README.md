# GFAmigaMathomatic

Mathomatic 16.0.5, the small computer algebra system by George Gesslein II,
for GFOS (AmigaOS 3.2.3 with GFOpenUp) on a 68040 or 68060, installed as a
GFOpenUp part: `C:mathomatic`.

    1.Work:> mathomatic
    1-> x^2 - 5*x + 6 = 0
    1-> solve x
    1-> integrate x
    1-> plot

It solves, simplifies, factors, differentiates, integrates and expands
equations symbolically, does exact rational and complex arithmetic, and
plots through gnuplot.

Status: built for the PC from the same patched sources as AmigaOS sees
them and passing Mathomatic's own test suite (see Tests); the Amiga build
is made by the stove, not yet run in a lab.

## What you need

- GFOS: AmigaOS 3.2 with GFOpenUp, a 68040 or 68060. Soft float: the FPU
  is used when there is one (fpuauto), so an LC040 runs it too.
- For `plot`: gnuplot (`Parts/gnuplot`, DalsinAI/gfamigagnuplot).

Install with `GFOpenUpTool INSTALL Parts/Mathomatic`. The manual is
`SYS:Docs/Mathomatic/manual.html` (with `am.html`, the command reference
card `quickrefcard.html`, and the manual page `mathomatic.1`).

## On AmigaOS

- Startup options (`set save`) go to `ENVARC:mathomatic.rc`, or to
  `.mathomaticrc` in `HOME` when the `HOME` variable is set (an AmigaDOS
  path: `Work:` or `Work:me`).
- `plot` writes its gnuplot commands to `T:mathomatic.plt` and runs
  `gnuplot -persist T:mathomatic.plt` (the AmigaDOS Shell has no `echo |`
  pipe for upstream's way).
- `edit` uses the `EDITOR` variable, or `Ed`; its temporary file is
  `T:mathomatic.tmp`. `!command` runs an AmigaDOS command in your Shell
  (through `SystemTags()`); `!` alone opens a `NewShell`.
- Not offered: the `-s level:seconds` time out (no `alarm()`), readline
  history. Screen size is upstream's 80 by 24 default (`set columns`,
  `set rows` change it).
- 256 KB of stack is set in the program, so the Shell's 4 KB is enough.

## Building

    STOVE=~/AmiCradle/stoves/os32-gcc16-open6 OUT=out sh build-amiga.sh

or in Cradle, stove_build with the os32-gcc16-open6 stove, target `.`.
Mathomatic and fpuauto are fetched at the commits `mathomatic.lock` pins.
`OUT` gets `Parts/Mathomatic` (the part) and `tests/` (Mathomatic's test
scripts, for `mathomatic -t all` in a lab, compared with `all.out`).

## Tests

`make -C tests test` on a PC: the Part file, `amiga/amiga_matho.c` (the
startup file's AmigaDOS name and the plot script), then
`tests/host-matho.sh`, which builds Mathomatic from the same patched
sources with `AMIGA=1` (no UNIX: no `ioctl`, `alarm` or readline) and
`tests/host_system.c` in place of `SystemTags()`, and checks:

- Mathomatic's own test suite (`tests/all.in`) against `all.out`, as
  upstream's `make check`;
- `plot`: a 2D and a 3D plot write `T:mathomatic.plt` and run
  `gnuplot -persist T:mathomatic.plt`;
- `set save` with no `HOME` writes `ENVARC:mathomatic.rc`, and the next
  start reads it back.

## What was changed

- `patches/0001`: `AMIGA` in `includes.h` (shelling out on, `amiga_matho.h`),
  `main.c` (no `alarm()`), `am.c` (startup file name), `cmds.c` (plot
  through a script, `T:` temporary file, `Ed`, `AMIGA` in `version status`),
  `help.c` (`NewShell`, `amiga_system()`).
- `amiga/amiga_matho.c`: the startup file name and the plot script (plain C,
  tested on the PC).
- `amiga/amiga_sys.c`: stack, `$VER`, `amiga_system()` on `SystemTags()`.

Mathomatic is LGPL 2.1 (`SYS:Docs/Mathomatic/COPYING`); this port's own
files are MIT.

Designed, tested and delivered by The AmiCradle Team.
