
# Project name
P := remake

# Include the build system library
include $T/Lib.mak

# Include the Build.mak for this directory
include $T/Build.mak

# Phony rule to make all the targets (sub-makefiles can append targets to build
# to the $(all) variable).
.PHONY: all
all: $(all)

