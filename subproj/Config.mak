
# Use the container project top-level directory as ours
T := ..

# Include the "parent" project config
sinclude $T/Toplevel.mak

# Include the "parent" project config
.DEFAULT_GOAL := subproj

