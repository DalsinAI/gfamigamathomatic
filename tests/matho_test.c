/* PC test of amiga/amiga_matho.c: the startup file's AmigaDOS name and the
 * script the plot command writes for gnuplot.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
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

	printf("amiga_matho: %d of %d checks passed\n", checks - fails, checks);
	return fails != 0;
}
