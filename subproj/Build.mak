
setup_include_dir__ := $(call symlink_include_dir,otherproj)

$L/libotherproj.so: LINKER := $(CC)
$L/libotherproj.so: $(call find_objects,c)

.PHONY: otherproj
otherproj: $L/libotherproj.so

all += otherproj

