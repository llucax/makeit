
#include "lib2.h"

#include <otherproj/otherproj.h>
#include <remake/lib1/lib1.h>

#include <stdio.h>

void lib2(void)
{
	printf("lib2()\n");
	lib1();
	otherproj();
}

