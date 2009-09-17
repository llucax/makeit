
#include "lib2.h"

#include <remake/subproj/subproj.h>
#include <remake/lib1/lib1.h>

#include <stdio.h>

void lib2(void)
{
	printf("lib2()\n");
	lib1();
	subproj();
}

