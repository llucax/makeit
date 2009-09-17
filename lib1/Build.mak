
$L/liblib1.so: LINKER := $(CC)
$L/liblib1.so: $(call find_objects,c)

.PHONY: lib1
lib1: $L/liblib1.so

