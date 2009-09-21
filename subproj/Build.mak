
# Symbolic target to add to all
.PHONY: otherproj
all += otherproj

# Include subdirectory to make the pkg-config stuff (it doesn't make much sense
# to have this in a separated directory, it's just to test very nested
# subdirectories :)
$(call include_subdirs,pkg-config)

# Shared library
$L/libotherproj.so: LINKER := $(CC)
$L/libotherproj.so: $(call find_objects,c)
$I/lib/libotherproj.so: $L/libotherproj.so
install += $I/lib/libotherproj.so
otherproj: $L/libotherproj.so

# Install the library's headers
$I/include/otherproj/%.h: $C/%.h
	$(call install_file)
# XXX: we can't use += here, call will be resolved lazily if we do
install := $(install) $(call find_files,.h,$I/include/otherproj)

# Build the documentation using doxygen
.PHONY: otherproj-doc
otherproj-doc: $D/otherproj/doxygen-stamp
$D/otherproj/doxygen-stamp: $C/Doxyfile $(call find_files,.h)
doc += otherproj-doc

# Create the include directory symbolic link and pkg-config flags file
setup_include_dir__ := $(call symlink_include_dir,otherproj)

