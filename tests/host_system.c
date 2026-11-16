/* The PC stand-in for amiga/amiga_sys.c's amiga_system(): it records the
 * command line in $MATHO_SYSTEM_LOG (one per line) and runs nothing, so the
 * plot and edit commands can be checked without gnuplot or an editor.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <stdio.h>
#include <stdlib.h>
#include "amiga_matho.h"

int amiga_system(const char *cmd)
{
	const char *log = getenv("MATHO_SYSTEM_LOG");
	FILE *fp;
	if (log && (fp = fopen(log, "a")) != NULL) { fprintf(fp, "%s\n", cmd); fclose(fp); }
	return 0;
}
