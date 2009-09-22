ifndef Toplevel.mak.included
Toplevel.mak.included := 1

# Load top-level directory local configuration
sinclude $T/Config.mak

# Include the build system library
include $T/Makeit.mak

# Include the Build.mak for this directory
include $T/Build.mak

endif
