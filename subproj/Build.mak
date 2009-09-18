
# Symbolic target to add to all
.PHONY: otherproj
all += otherproj

# pkg-config specification file
otherproj-PC-PREFIX := $(prefix)
otherproj-PC-NAME := otherproj
otherproj-PC-DESC := Some other project
otherproj-PC-URL := http://www.otherproj.example.com/
otherproj-PC-VERSION := 1.0
otherproj-PC-LIBS := -lotherproject
otherproj-PC-CFLAGS := -DOTHERPROJ_DEFINE
otherproj-PC-VARS := PREFIX NAME DESC URL VERSION LIBS CFLAGS
$L/otherproj.pc: PC_VARS := $(otherproj-PC-VARS)
$L/otherproj.pc: $C/otherproj.pc.in $L/otherproj.pc-flags
# trigger a rebuild when flags change
setup_flags_files__ := $(call gen_rebuild_flags,$L/otherproj.pc-flags,\
		$(call varcat,$(otherproj-PC-VARS),otherproj-PC-))
# install
$I/lib/pkgconfig/otherproj.pc: $L/otherproj.pc
install += $I/lib/pkgconfig/otherproj.pc
otherproj: $L/otherproj.pc

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
install := $(install) $(call find_headers,h,$I/include/otherproj)

# Create the include directory symlink and pkg-config flags file
setup_include_dir__ := $(call symlink_include_dir,otherproj)

