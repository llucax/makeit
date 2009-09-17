
$L/liblib2.so: $(call find_objects,cpp) $L/liblib1.so $L/libsubproj.so

.PHONY: lib2
lib2: $L/liblib2.so

