
$L/libsubproj.so: LINKER := $(CC)
$L/libsubproj.so: $(call find_objects,c)

.PHONY: subproj
subproj: $L/libsubproj.so

all += subproj

