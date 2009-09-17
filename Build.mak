
setup_include_dir__ := $(call symlink_include_dir,remake)

# Include sub-directories makefiles

C := subproj
include $T/subproj/Build.mak

C := lib1
include $T/lib1/Build.mak

C := lib2
include $T/lib2/Build.mak

C := prog
include $T/prog/Build.mak
