
# Build the shared library
$B/prog: $(call find_objects,cpp) $L/liblib1.so $L/liblib2.so
all += prog

# Nice shortcut target
.PHONY: prog
prog: $B/prog

# Install the program executable
$I/bin/prog: $B/prog
install += $I/bin/prog

