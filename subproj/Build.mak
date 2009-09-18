
# Create the include directory symlink
setup_include_dir__ := $(call symlink_include_dir,otherproj)

# Build the shared library
$L/libotherproj.so: LINKER := $(CC)
$L/libotherproj.so: $(call find_objects,c)
all += otherproj

# Nice shortcut target
.PHONY: otherproj
otherproj: $L/libotherproj.so

# Install the shared library
$I/lib/libotherproj.so: $L/libotherproj.so
install += $I/lib/libotherproj.so

# Install the library's headers
$I/include/otherproj/%.h: $C/%.h
	$(call install_file)
# XXX: we can't use += here, call will be resolved lazily if we do
install := $(install) $(call find_headers,h,$I/include/otherproj)

