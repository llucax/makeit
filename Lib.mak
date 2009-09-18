ifndef Lib.mak.included
Lib.mak.included := 1

# These variables should be provided by the includer Makefile:
# P should be the project name, mostly used to handle include directories
# T should be the path to the top-level directory.
# S should be sub-directory where the current makefile is, relative to $T.

# Verbosity flag (empty show nice messages, non-empty use make messages)
# When used internal, $V expand to @ is nice messages should be printed, this
# way it's easy to add $V in front of commands that should be silenced when
# displaying the nice messages.
override V := $(if $V,,@)
# honour make -s flag
override V := $(if $(findstring s,$(MAKEFLAGS)),,$V)

# Flavor (variant), should be one of "dbg", "opt" or "cov"
F ?= opt

# Use C++ linker by default
LINKER := $(CXX)

# Default mode used to install files
IMODE ?= 0644

# Degault install flags
IFLAGS ?= -D

# Use precompiled headers if non-empty
GCH ?=


# Directories
##############

# Base directory where to install files (can be overrided, should be absolute)
prefix ?= /usr/local

# Path to a complete alternative environment, usually a jail, or an installed
# system mounted elsewhere than /.
DESTDIR ?=

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

# Installation directory
I := $(DESTDIR)$(prefix)

# Includes directory
INCLUDE_DIR ?= $G/include

# Directory of the current makefile (this might not be the same as $(CURDIR)
# This variable is "lazy" because $S changes all the time, so it should be
# evaluated in the context where $C is used, not here.
C = $T/$S


# Functions
############

# Compare two strings, if they are the same, returns the string, if not,
# returns empty.
eq = $(if $(subst $1,,$2),,$1)

# Find sources files and get the corresponding object names
# The first argument should be the sources extension ("c" or "cpp" typically)
# It expects the variable $T and $O to be defined as commented previously in
# this file.
find_objects = $(patsubst $T/%.$1,$O/%.o,$(shell find $C -name '*.$1'))

# Find sources files and get the corresponding object names
# The first argument should be the sources extension ("c" or "cpp" typically)
# It expects the variable $T and $O to be defined as commented previously in
# this file.
find_headers = $(patsubst $C/%.$1,$2/%.$1,$(shell find $C -name '*.$1'))

# Abbreviate a file name. Cut the leading part of a file if it match to the $T
# directory, so it can be displayed as if it were a relative directory. Take
# just one argument, the file name.
abbr_helper = $(subst $T,.,$(patsubst $T/%,%,$1))
abbr = $(if $(call eq,$(call abbr_helper,$1),$1),$1, \
	$(addprefix $(shell echo $R | sed 's|/\?\([^/]\+\)/\?|../|g'),\
		$(call abbr_helper,$1)))

# Execute a command printing a nice message if $V is @.
# The first argument is mandatory and it's the command to execute. The second
# and third arguments are optional and are the target name and command name to
# pretty print.
vexec = $(if $V,\
		echo '   $(notdir $(if $3,$(strip $3),$(firstword $1))) \
				$(call abbr,$(if $2,$(strip $2),$@))' ; )$1

# Same as vexec but it silence the echo command (prepending a @ if $V).
exec = $V$(call vexec,$1,$2,$3)

# Compile a source file to an object, generating pre-compiled headers and
# dependencies. The pre-compiled headers are generated only if the system
# includes change. This function is designed to be used as a command in a rule.
# It takes one argument only, the type of file to compile (typically "c" or
# "cpp"). What to compile and the output files are built using the automatic
# variables from a rule.
define compile
$(if $(GCH),\
$Vif test -f $O/$*.d; then \
	tmp=`mktemp`; \
	h=`awk -F: '!$$0 {f = 1} $$0 && f {print $$1}' $O/$*.d`; \
	grep -h '^#include <' $< $$h | sort -u > "$$tmp"; \
	if diff -q -w "$O/$*.$1.h" "$$tmp" > /dev/null 2>&1; \
	then \
		rm "$$tmp"; \
	else \
		mv "$$tmp" "$O/$*.$1.h"; \
		$(call vexec,$(COMPILE.$1) -o "$O/$*.$1.h.gch" "$O/$*.$1.h",\
				$O/$*.$1.h.gch); \
	fi \
else \
	touch "$O/$*.$1.h"; \
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

# Install a file. All arguments are optional.  The first argument is the file
# mode (defaults to 0644).  The second argument are extra flags to the install
# command (defaults to -D).  The third argument is the source file to install
# (defaults to $<) and the last one is the destination (defaults to $@).
install_file = $(call exec,install -m $(if $1,$1,0644) $(if $2,$2,-D) \
		$(if $3,$3,$<) $(if $4,$4,$@))

# Concatenate variables together.  The first argument is a list of variables
# names to concatenate.  The second argument is an optional prefix for the
# variables and the third is the string to use as separator (" ~" if omitted).
# For example:
# X_A := a
# X_B := b
# $(call varcat,A B,X_, --)
# Will produce something like "a -- b --"
varcat = $(foreach v,$1,$($2$v)$(if $3,$3, ~))

# Replace variables with specified values in a template file.  The first
# argument is a list of make variables names which will be replaced in the
# target file.  The strings @VARNAME@ in the template file will be replaced
# with the value of the make $(VARNAME) variable and the result will be stored
# in the target file.  The second (optional) argument is a prefix to add to the
# make variables names, so if the prefix is PREFIX_ and @VARNAME@ is found in
# the template file, it will be replaced by the value of the make variable
# $(PREFIX_VARNAME).  The third and fourth arguments are the source file and
# the destination file (both optional, $< and $@ are used if omitted). The
# fifth (optional) argument are options to pass to the substitute sed command
# (for example, use "g" if you want to do multiple substitutions per line).
replace = $(call exec,sed '$(foreach v,$1,s|@$v@|$($2$v)|$5;)' $(if $3,$3,$<) \
		> $(if $4,$4,$@))

# Create a symbolic link to the project under the $(INCLUDE_DIR). The first
# argument is the name of symlink to create.  The link is only created if it
# doesn't already exist.
symlink_include_dir = $(shell \
		test -L $(INCLUDE_DIR)/$1 \
			|| ln -s $C $(INCLUDE_DIR)/$1 )

# Create a file with flags used to trigger rebuilding when they change. The
# first argument is the name of the file where to store the flags, the second
# are the flags and the third argument is a text to be displayed if the flags
# have changed (optional).  This should be used as a rule action or something
# where a shell script is expected.
gen_rebuild_flags = $(shell if test x"$2" != x"`cat $1 2>/dev/null`"; then \
		$(if $3,test -f $1 && echo "$3";) \
		echo "$2" > $1 ; fi)


# Overrided flags
##################

# Warn about everything
override CPPFLAGS += -Wall

# Use the includes directories to search for includes
override CPPFLAGS += -I$(INCLUDE_DIR)

# Let the program know where it will be installed
override CPPFLAGS += -DPREFIX=$(prefix)

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


# Automatic dependency handling
################################

# These files are created during compilation.
sinclude $(shell test -d $O && find $O -name '*.d')


# Default rules
################

# Compile C objects
$O/%.o: $T/%.c $G/compile-c-flags
	$(call compile,c)

# Compile C++ objects
$O/%.o: $T/%.cpp $G/compile-cpp-flags
	$(call compile,cpp)

# Link binary programs
$B/%: $G/link-o-flags
	$(call link)

# Link shared libraries
$L/%.so: override CFLAGS += -fPIC
$L/%.so: override CXXFLAGS += -fPIC
$L/%.so: $G/link-o-flags
	$(call link,-shared)

# Create pkg-config files using a template
$L/%.pc:
	$(call replace,$(PC_VARS),$*-PC-)

# Install binary programs
$I/bin/%:
	$(call install_file,0755)

# Install system binary programs
$I/sbin/%:
	$(call install_file,0755)

# Install pkg-config specification files
$I/lib/pkgconfig/%:
	$(call install_file)

# Install libraries
$I/lib/%:
	$(call install_file)

.PHONY: clean
clean:
	$(call exec,$(RM) -r $D,$D)

# Phony rule to uninstall all built targets (like "install", uses $(install)).
.PHONY: uninstall
uninstall:
	$V$(foreach i,$(install),$(call vexec,$(RM) $i,$i);)

# These rules use the "Secondary Expansion" GNU Make feature, to allow
# sub-makes to add values to the special variables $(all), after this makefile
# was read.
.SECONDEXPANSION:
  
# Phony rule to make all the targets (sub-makefiles can append targets to build
# to the $(all) variable).
.PHONY: all
all: $$(all)

# Phony rule to install all built targets (sub-makefiles can append targets to
# build to the $(install) variable).
.PHONY: install
install: $$(install)


# Create build directory structure
###################################

# Create $O, $B, $L and $(INCLUDE_DIR) directories and replicate the directory
# structure of the project into $O. Create one symlink "last" to the current
# build directory.
#
# NOTE: the second mkdir can yield no arguments if the project don't have any
#       subdirectories, that's why the current directory "." is included, so it
#       won't show an error message in case of no subdirectories.
setup_build_dir__ := $(shell \
	mkdir -p $O $B $L $(INCLUDE_DIR); \
	mkdir -p . $(addprefix $O,$(patsubst $T%,%,\
			$(shell find $T -type d -not -path '$D*'))); \
	test -L $D/last || ln -s $F $D/last )


# Automatic rebuilding when flags or commands changes
######################################################

# Re-compile C files if one of this variables changes
COMPILE.c.FLAGS := $(call varcat,CC CPPFLAGS CFLAGS TARGET_ARCH prefix)

# Re-compile C++ files if one of this variables changes
COMPILE.cpp.FLAGS := $(call varcat,CXX CPPFLAGS CXXFLAGS TARGET_ARCH prefix)

# Re-link binaries and libraries if one of this variables changes
LINK.o.FLAGS := $(call varcat,LD LDFLAGS TARGET_ARCH)

# Create files containing the current flags to trigger a rebuild if they change
setup_flag_files__ := $(call gen_rebuild_flags,$G/compile-c-flags, \
	$(COMPILE.c.FLAGS),C compiler or flags; )
setup_flag_files__ := $(setup_flag_files__)$(call gen_rebuild_flags, \
	$G/compile-cpp-flags, $(COMPILE.cpp.FLAGS),C++ compiler or flags; )
setup_flag_files__ := $(setup_flag_files__)$(call gen_rebuild_flags, \
	$G/link-o-flags, $(LINK.o.FLAGS),linker or link flags; )

# Print any generated message (if verbose)
$(if $V,$(if $(setup_flag_files__), \
	$(info !! Something changed: $(setup_flag_files__)re-building \
			affected files...)))

endif
