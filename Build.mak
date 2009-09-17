
# Include sub-directories makefiles

C := subproj
include $T/subproj/Build.mak

C := lib1
include $T/lib1/Build.mak

C := lib2
include $T/lib2/Build.mak

C := prog
include $T/prog/Build.mak

