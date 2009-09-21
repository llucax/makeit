
# Symbolic target to add to all
.PHONY: otherproj-pc
all += otherproj-pc

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

