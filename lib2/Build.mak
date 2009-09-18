
# Build the shared library
$L/liblib2.so: CXXFLAGS += $(otherproj-PC-CFLAGS)
$L/liblib2.so: $(call find_objects,cpp) $L/liblib1.so $L/libotherproj.so

# Nice shortcut target
.PHONY: lib2
lib2: $L/liblib2.so

# Install the shared library
$I/lib/liblib2.so: $L/liblib2.so
install += $I/lib/liblib2.so

# Install the library's headers
# XXX: we can't use += here, call will be resolved lazily if we do
install := $(install) $(call find_headers,h,$I/include/makeit/lib2)

