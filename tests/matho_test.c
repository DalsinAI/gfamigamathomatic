/* PC test of amiga/amiga_matho.c: the startup file's AmigaDOS name and the
 * script the plot command writes for gnuplot.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <math.h>
#include "amiga_matho.h"

static int fails, checks;
static void same(const char *got, const char *want, const char *what)
{
	checks++;
	if (strcmp(got, want) != 0) { fails++; printf("FAIL %s: got \"%s\", want \"%s\"\n", what, got, want); }
}

int main(void)
{
	char buf[256], small[8], line[512];
	char path[] = "/tmp/matho_plotXXXXXX";
	FILE *fp;
	int fd;

	same(amiga_rc_path(NULL, buf, sizeof(buf)), "ENVARC:mathomatic.rc", "no HOME");
	same(amiga_rc_path("", buf, sizeof(buf)), "ENVARC:mathomatic.rc", "empty HOME");
	same(amiga_rc_path("Work:", buf, sizeof(buf)), "Work:.mathomaticrc", "volume HOME");
	same(amiga_rc_path("Work:me", buf, sizeof(buf)), "Work:me/.mathomaticrc", "drawer HOME");
	same(amiga_rc_path("Work:me/", buf, sizeof(buf)), "Work:me/.mathomaticrc", "drawer/ HOME");
	same(amiga_rc_path("/home/dale", buf, sizeof(buf)), "/home/dale/.mathomaticrc", "Unix-style HOME");
	amiga_rc_path("Work:", small, sizeof(small));
	same(small, "Work:.m", "cut to the buffer");

	fd = mkstemp(path);
	if (fd < 0) { perror(path); return 1; }
	close(fd);
	checks++;
	if (!amiga_plot_script(path, "set grid; set xlabel \"X\";", "plot", "x^2", "")) { fails++; printf("FAIL plot script not written\n"); }
	fp = fopen(path, "r");
	if (fp && fgets(line, sizeof(line), fp)) same(line, "set grid; set xlabel \"X\";\n", "prefix line");
	if (fp && fgets(line, sizeof(line), fp)) same(line, "plot x^2 \n", "plot line");
	checks++;
	if (fp && fgets(line, sizeof(line), fp)) { fails++; printf("FAIL extra line: %s", line); }
	if (fp) fclose(fp);
	amiga_plot_script(path, "", "splot", "x*y", "with lines");
	fp = fopen(path, "r");
	if (fp && fgets(line, sizeof(line), fp)) same(line, "splot x*y with lines\n", "no prefix, splot");
	if (fp) fclose(fp);
	unlink(path);
	checks++;
	if (amiga_plot_script("/nonexistent-dir/x.plt", "", "plot", "x", "")) { fails++; printf("FAIL unwritable path reported written\n"); }

	{	/* gamma against the C library's, and exact factorials */
		double xs[] = { 0.5, 1.5, 2.5, 3.7, 10.25, 50.5, 120.3, 170.5, -0.5, -2.5, -7.3, 0.001 };
		size_t k;
		double worst = 0;
		for (k = 0; k < sizeof(xs) / sizeof(xs[0]); k++) {
			double want = tgamma(xs[k]), got = amiga_tgamma(xs[k]);
			double rel = fabs(got - want) / fabs(want);
			if (rel > worst) worst = rel;
		}
		checks++;
		if (worst > 5e-13) { fails++; printf("FAIL gamma off by %g relative\n", worst); }
		checks++;
		if (amiga_tgamma(6.0) != 120.0 || amiga_tgamma(21.0) != 2432902008176640000.0) { fails++; printf("FAIL exact factorials\n"); }
		errno = 0; checks++;
		if (amiga_tgamma(200.0) != HUGE_VAL || errno != ERANGE) { fails++; printf("FAIL overflow\n"); }
		errno = 0; checks++;
		if (!isnan(amiga_tgamma(-3.0)) || errno != EDOM) { fails++; printf("FAIL pole\n"); }
	}
	printf("amiga_matho: %d of %d checks passed\n", checks - fails, checks);
	return fails != 0;
}
