/* Mathomatic on AmigaOS: the parts that are plain C (and tested on the PC,
 * tests/matho_test.c): the startup file's name and the gnuplot script.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <stdio.h>
#include <string.h>
#include "amiga_matho.h"

char *amiga_rc_path(const char *home, char *buf, size_t size)
{
	size_t n;
	const char *sep = "/";
	if (size == 0) return buf;
	if (home == NULL || *home == '\0') {
		snprintf(buf, size, "%s", AMIGA_RC_FILE);
		return buf;
	}
	n = strlen(home);
	/* "Work:" or "Work:me/" already end where a name goes */
	if (home[n - 1] == ':' || home[n - 1] == '/') sep = "";
	snprintf(buf, size, "%s%s%s", home, sep, ".mathomaticrc");
	return buf;
}

int amiga_plot_script(const char *path, const char *prefix, const char *verb,
                      const char *exprs, const char *options)
{
	FILE *fp = fopen(path, "w");
	int ok;
	if (fp == NULL) return 0;
	if (prefix && *prefix) fprintf(fp, "%s\n", prefix);
	fprintf(fp, "%s %s %s\n", verb, exprs ? exprs : "", options ? options : "");
	ok = !ferror(fp);
	if (fclose(fp)) ok = 0;
	return ok;
}
