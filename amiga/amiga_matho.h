/* Mathomatic on AmigaOS: the startup file, the gnuplot script and running
 * Shell commands. MIT, Copyright (c) 2026 AmiCradle Team. */
#ifndef AMIGA_MATHO_H
#define AMIGA_MATHO_H
#include <stddef.h>

/* the startup file when HOME is not set (ENVARC: keeps it over a reboot) */
#define AMIGA_RC_FILE	"ENVARC:mathomatic.rc"
/* the script the plot command hands to gnuplot */
#define AMIGA_PLOT_FILE	"T:mathomatic.plt"

/* The startup file's name into buf: HOME joined AmigaDOS-style
 * ("Work:" + ".mathomaticrc", "Work:me" + "/.mathomaticrc"), or
 * AMIGA_RC_FILE when home is NULL or empty. Returns buf. */
char *amiga_rc_path(const char *home, char *buf, size_t size);

/* Writes "<prefix>; <verb> <exprs> <options>" to path for gnuplot to read.
 * Returns 1 when written, 0 (errno set) when not. */
int amiga_plot_script(const char *path, const char *prefix, const char *verb,
                      const char *exprs, const char *options);

/* Runs an AmigaDOS command line in the user's Shell, with this program's
 * input and output; its return code, or -1 when it can't be started. */
int amiga_system(const char *cmd);

/* Gamma for the factorial (libnix has no tgamma or lgamma): exact products
 * for whole numbers up to 171, Lanczos (g=7) otherwise, reflection below
 * 1/2; errno ERANGE on overflow, EDOM at poles. Built in place of
 * tgamma() with -DUSE_TGAMMA -Dtgamma=amiga_tgamma. */
double amiga_tgamma(double x);
#endif
