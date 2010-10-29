
# Use the container project top-level directory as ours
T := ..

# Define the default goal when doing make in this directory
.DEFAULT_GOAL := otherproj

# Include the "parent" project configuration
sinclude $T/Config.mak

