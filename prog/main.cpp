
#include <remake/lib1/lib1.h>
#include <remake/lib2/lib2.h>

#include <iostream>

int main()
{
	std::cout << "prog:main() start\n";
	lib1();
	lib2();
	std::cout << "prog:main() end\n";
	return 0;
}

