
# Build the shared library
$L/liblib1.so: LINKER := $(CC)
$L/liblib1.so: $(call find_objects,c)

# Nice shortcut target
.PHONY: lib1
lib1: $L/liblib1.so

# Install the shared library
$I/lib/liblib1.so: $L/liblib1.so
install += $I/lib/liblib1.so

# Install the library's headers
# XXX: we can't use += here, call will be resolved lazily if we do
install := $(install) $(call find_files,.h,$I/include/makeit/lib1)

