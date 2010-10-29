
# Create the include directory symbolic link
setup_include_dir__ := $(call symlink_include_dir,makeit)

# General rule to install headers of this project
$I/include/makeit/%.h: $T/%.h
	$(call install_file)

# Include sub-directories makefiles
$(call include_subdirs,
	subproj
	lib1
	lib2
	prog
)

