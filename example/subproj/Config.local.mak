
# Use the container project top-level directory as ours.
T := ..

# Define the default goal to the main target of this subproject when doing make
# in this directory (you can use "all" to make the whole super-project).
.DEFAULT_GOAL := otherproj

# Include the "parent" project and local configuration.
sinclude $T/Config.mak
sinclude $T/Config.local.mak

