
# Create the include directory symbolic link
setup_include_dir__ := $(call symlink_include_dir,makeit)

# General rule to install headers of this project
$I/include/makeit/%.h: $T/%.h
	$(call install_file)

# Include sub-directories makefiles

S := subproj
include $T/$S/Build.mak

S := lib1
include $T/$S/Build.mak

S := lib2
include $T/$S/Build.mak

S := prog
include $T/$S/Build.mak

