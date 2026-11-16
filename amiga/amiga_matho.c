/* Mathomatic on AmigaOS: the parts that are plain C (and tested on the PC,
 * tests/matho_test.c): the startup file's name and the gnuplot script.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <math.h>
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

static const double lanczos[9] = {
	0.99999999999980993, 676.5203681218851, -1259.1392167224028,
	771.32342877765313, -176.61502916214059, 12.507343278686905,
	-0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7
};

double amiga_tgamma(double x)
{
	double t, a;
	int i;
	if (x != x) return x;
	if (x == floor(x) && x <= 0.0) { errno = EDOM; return NAN; }
	if (x == floor(x) && x <= 171.0) {	/* (x-1)!, exact while it fits */
		double d = 1.0;
		for (t = 2.0; t < x; t += 1.0) d *= t;
		return d;
	}
	if (x > 171.7) { errno = ERANGE; return HUGE_VAL; }
	if (x < 0.5)	/* reflection: G(x) G(1-x) = pi / sin(pi x) */
		return M_PI / (sin(M_PI * x) * amiga_tgamma(1.0 - x));
	x -= 1.0;
	a = lanczos[0];
	t = x + 7.5;
	for (i = 1; i < 9; i++) a += lanczos[i] / (x + i);
	/* t^(x+0.5) split in two so it doesn't overflow near 171 */
	return sqrt(2.0 * M_PI) * pow(t, (x + 0.5) / 2.0) * (pow(t, (x + 0.5) / 2.0) * exp(-t)) * a;
}
