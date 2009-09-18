
# Use the container project top-level directory as ours
T := ..

# Include the "parent" project configuration
sinclude $T/Config.mak

# Define the default goal when doing make in this directory
.DEFAULT_GOAL := otherproj

