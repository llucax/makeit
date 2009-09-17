
ifndef Lib.mak.included
Lib.mak.included := 1

# These variables should be provided by the includer Makefile:
# P should be the project name, mostly used to handle include directories
# T should be the path to the top-level directory.
# C should be the path to the current directory.

# Load top-level directory local configuration
sinclude $T/Config.mak

# Verbosity flag (empty show nice messages, 1 be verbose)
# honour make -s flag
override V := $(if $(findstring s,$(MAKEFLAGS)),1,$V)

# Flavor (variant), should be one of "dbg", "opt" or "cov"
F ?= opt

# Use C++ linker by default
LINKER := $(CXX)

# Use precompiled headers if non-empty
GCH ?=


# Directories
##############

# Use absolute paths to avoid problems with automatic dependencies when
# building from subdirectories
T := $(abspath $T)

# Name of the current directory, relative to $T
R := $(subst $T,,$(patsubst $T/%,%,$(CURDIR)))

# Base directory where to put variants
D ?= $T/build

# Generated files top directory
G ?= $D/$F

# Objects (and other garbage like precompiled headers and dependency files)
# directory
O ?= $G/obj

# Binaries directory
B ?= $G/bin

# Libraries directory
L ?= $G/lib

# Includes directory
I ?= $G/include

# Generated includes directory
J ?= $G/geninc


# Functions
############

# Find sources files and get the corresponding object names
# The first argument should be the sources extension ("c" or "cpp" typically)
# It expects the variable $T and $O to be defined as commented previously in
# this file. $C should be defined to the path to the current directory relative
# to the top-level.
find_objects = $(patsubst $T/%.$1,$O/%.o,$(shell find $T/$C -name '*.$1'))

# Abbreviate a file name. Cut the leading part of a file if it match to the $T
# directory, so it can be displayed as if it were a relative directory. Take
# just one argument, the file name.
abbr = $(addprefix $(shell echo $R | sed 's|/\?\([^/]\+\)/\?|../|g'),\
		$(subst $T,.,$(patsubst $T/%,%,$1)))

# Execute a command printing a nice message if $V is empty
# The first argument is mandatory and it's the command to execute. The second
# and third arguments are optional and are the target name and command name to
# pretty print.
vexec = $(if $V,,\
		echo '   $(notdir $(if $3,$(strip $3),$(firstword $1))) \
				$(call abbr,$(if $2,$(strip $2),$@))' ; )$1

# Same as vexec but it silence the echo command (prepending a @).
exec = $(if $V,,@)$(call vexec,$1,$2,$3)

# Compile a source file to an object, generating pre-compiled headers and
# dependencies. The pre-compiled headers are generated only if the system
# includes change. This function is designed to be used as a command in a rule.
# It takes one argument only, the type of file to compile (typically "c" or
# "cpp"). What to compile and the output files are built using the automatic
# variables from a rule.
define compile
$(if $(GCH),\
@if test -f $O/$*.d; then \
	tmp=`mktemp`; \
	h=`awk -F: '!$$0 {f = 1} $$0 && f {print $$1}' $O/$*.d`; \
	grep -h '^#include <' $(call abbr,$<) $$h | sort -u > "$$tmp"; \
	if diff -q -w "$(call abbr,$O/$*.$1.h)" "$$tmp" > /dev/null 2>&1; \
	then \
		rm "$$tmp"; \
	else \
		mv "$$tmp" "$(call abbr,$O/$*.$1.h)"; \
		$(call vexec,$(COMPILE.$1) -o "$O/$*.$1.h.gch" "$O/$*.$1.h",\
				$O/$*.$1.h.gch); \
	fi \
else \
	touch "$(call abbr,$O/$*.$1.h)"; \
fi \
)
$(call exec,$(COMPILE.$1) -o $@ -MMD -MP $(if $(GCH),-include $O/$*.$1.h) $<)
endef

# Link object files to build an executable. The objects files are taken from
# the prerequisite files ($O/%.o). If in the prerequisite files are shared
# objects ($L/lib%.so), they are included as libraries to link to (-l%). This
# function is designed to be used as a command in a rule. The ouput name is
# taken from the rule automatic variables. If an argument is provided, it's
# included in the link command line. The variable LINKER is used to link the
# executable; for example, if you want to link a C++ executable, you should use
# LINKER := $(CXX).
link = $(call exec,$(LINKER) $(LDFLAGS) $(TARGET_ARCH) -o $@ $1 \
		$(patsubst $L/lib%.so,-l%,$(filter %.so,$^)) \
		$(foreach obj,$(filter %.o,$^),$(obj)))


# Overrided flags
##################

# Warn about everything
override CPPFLAGS += -Wall

# Use the includes directories to search for includes
override CPPFLAGS += -I$I -I$J

# Be standard compilant
override CFLAGS += -std=c99 -pedantic
override CXXFLAGS += -std=c++98 -pedantic

# Use the generated library directory to for libraries
override LDFLAGS += -L$L -Wall

# Make sure the generated libraries can be found
export LD_LIBRARY_PATH := $L:$(LD_LIBRARY_PATH)


# Variant flags
################

ifeq ($F,dbg)
override CPPFLAGS += -ggdb -DDEBUG
endif

ifeq ($F,opt)
override CPPFLAGS += -O2 -DNDEBUG
endif

ifeq ($F,cov)
override CPPFLAGS += -ggdb -pg --coverage
override LDFLAGS += -pg --coverage
endif


# Automatic rebuilding when flags or commands changes
######################################################

# Re-compile C files if one of this variables changes
COMPILE.c.FLAGS := $(CC) ~ $(CPPFLAGS) ~ $(CFLAGS) ~ $(TARGET_ARCH)

# Re-compile C++ files if one of this variables changes
COMPILE.cpp.FLAGS := $(CXX) ~ $(CPPFLAGS) ~ $(CXXFLAGS) ~ $(TARGET_ARCH)

# Re-link binaries and libraries if one of this variables changes
LINK.o.FLAGS := $(LD) ~ $(LDFLAGS) ~ $(TARGET_ARCH)


# Default rules
################

$O/%.o: $T/%.c $G/compile-c-flags
	$(call compile,c)

$O/%.o: $T/%.cpp $G/compile-cpp-flags
	$(call compile,cpp)

$B/%: $G/link-o-flags
	$(call link)

$L/%.so: override CFLAGS += -fPIC
$L/%.so: override CXXFLAGS += -fPIC
$L/%.so: $G/link-o-flags
	$(call link,-shared)

.PHONY: clean
clean:
	$(call exec,$(RM) -r $D,$D)


# Automatic dependency handling
################################

sinclude $(shell test -d $O && find $O -name '*.d')


# Create build directory structure
###################################

# Create a file with flags used to trigger rebuilding when they change. The
# first argument is the name of the file where to store the flags, the second
# are the flags and the third argument is a text to be displayed if the flags
# have changed.  This should be used as a rule action or something where
# a shell script is expected.
gen_rebuild_flags = if test x"$2" != x"`cat $1 2>/dev/null`"; then \
		test -f $1 && echo "$3"; \
		echo "$2" > $1 ; fi

# Create $O, $B, $L, $I and $J directories and replicate the directory
# structure of the project into $O. Create one symlink "last" to the current
# build directory and another to use as include directory.  It update the flags
# files to detect flag and/or compiler changes to force a rebuild.
#
# NOTE: the second mkdir can yield no arguments if the project don't have any
#       subdirectories, that's why the current directory "." is included, so it
#       won't show an error message in case of no subdirectories.
setup_build_dir__ := $(shell \
	mkdir -p $O $B $L $I $J; \
	mkdir -p . $(addprefix $O,$(patsubst $T%,%,\
			$(shell find $T -type d -not -path '$D*'))); \
	$(call gen_rebuild_flags,$G/compile-c-flags, \
			$(COMPILE.c.FLAGS),C compiler or flags;); \
	$(call gen_rebuild_flags,$G/compile-cpp-flags, \
			$(COMPILE.cpp.FLAGS),C++ compiler or flags;); \
	$(call gen_rebuild_flags,$G/link-o-flags, \
			$(LINK.o.FLAGS),linker or link flags;); \
	test -L $I/$P || ln -s $T $I/$P; \
	test -L $D/last || ln -s $F $D/last )

# Print any generated message (if verbose)
$(if $V,,$(if $(setup_build_dir__), \
	$(info !! Something changed: $(setup_build_dir__) \
			re-building affected files...)))

endif
