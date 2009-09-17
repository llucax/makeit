
# Project name
P := subproj

# Load top-level directory local configuration
sinclude $T/Config.mak

# Include the build system library
include $T/Lib.mak

# Include the Build.mak for this directory
include $T/Build.mak

# Phony rule to make all the targets (sub-makefiles can append targets to build
# to the $(all) variable).
.PHONY: all
all: $(all)

