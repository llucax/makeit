
$B/prog: $(call find_objects,cpp) $L/liblib1.so $L/liblib2.so

.PHONY: prog
prog: $B/prog

all += prog

