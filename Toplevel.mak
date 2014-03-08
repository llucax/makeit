# Copyright Leandro Lucarella 2006 - 2014
# Distributed under the Boost Software License, Version 1.0
# See the LICENSE file for details, or http://www.boost.org/LICENSE_1_0.txt

ifndef Toplevel.mak.included
Toplevel.mak.included := 1

# Load top-level directory project configuration
sinclude $T/Config.mak

# Load top-level directory local configuration
sinclude $T/Config.local.mak

# Include the build system library
include $T/Makeit.mak

# Include the Build.mak for this directory
include $T/Build.mak

endif
