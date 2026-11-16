/* Mathomatic on AmigaOS: stack, $VER, and Shell commands through dos.library
 * SystemTags() (the plot command's gnuplot, edit's editor, "!").
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <proto/dos.h>
#include <dos/dostags.h>
#include "amiga_matho.h"

/* Mathomatic's simplifier recurses deeply; the Shell's 4 KB is far too
 * little. libnix's startup gives the program this much. */
unsigned long __stack = 256 * 1024;
static const char version[] __attribute__((used)) =
	"$VER: Mathomatic " MATHO_AMIGA_VERSION " (" MATHO_AMIGA_DATE ") GFOS";

int amiga_system(const char *cmd)
{
	LONG rc = SystemTags((CONST_STRPTR)cmd,
	                     SYS_Input, Input(), SYS_Output, Output(),
	                     SYS_UserShell, TRUE, TAG_DONE);
	return rc == -1 ? -1 : (int)rc;
}
