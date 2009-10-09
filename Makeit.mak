ifndef Makeit.mak.included
Makeit.mak.included := 1

# These variables should be provided by the Makefile that include us:
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

# If $V is non-empty, colored output is used if $(COLOR) is non-empty too
COLOR ?= 1

# ANSI color used for the command if $(COLOR) is non-empty
# The color is composed with 2 numbers separated by ;
# The first is the style. 00 is normal, 01 is bold, 04 is underline, 05 blinks,
# 07 is reversed mode
# The second is the color: 30 dark gray/black, 31 red, 32 green, 33 yellow, 34
# blue, 35 magenta, 36 cyan and 37 white.
# If empty, no special color is used.
COLOR_CMD ?= 00;33

# ANSI color used for the argument if $(COLOR) is non-empty
# See COLOR_CMD comment for details.
COLOR_ARG ?=

# ANSI color used for the warnings if $(COLOR) is non-empty
# See COLOR_CMD comment for details.
COLOR_WARN ?= 00;36

# ANSI color used for commands output if $(COLOR) is non-empty
# See COLOR_CMD comment for details.
COLOR_OUT ?= 00;31

# Flavor (variant), should be one of "dbg", "opt" or "cov"
F ?= opt

# Use C++ linker by default
LINKER := $(CXX)

# Default mode used to install files
IMODE ?= 0644

# Default install flags
IFLAGS ?= -D

# Use pre-compiled headers if non-empty
GCH ?=

# If non-empty, use valgrind to run commands via the "valgrind" function
VALGRIND ?=

# Options to pass to valgrind; if the variable $(VALGRIND_SUPP) is non-empty
# it will be used as a suppressions file.
VALGRIND_CMD ?= valgrind --tool=memcheck --leak-check=yes --db-attach=no \
		--num-callers=24 --leak-resolution=high --track-fds=yes \
		--error-exitcode=1 \
		$(if $V,--log-file=$<.valgrind.log) \
		$(if $(VALGRIND_SUPP),--suppressions=$(VALGRIND_SUPP))

# Command to generate Sphinx based documentation
SPHINX ?= sphinx-build

# Format to build using Sphinx (html, pickle, htmlhelp, latex, changes or
# linkcheck; see sphinx-build docs for details)
SPHINX_FORMAT ?= html

# Paper size for Sphinx LaTeX output (a4, letter, etc.)
SPHINX_PAPERSIZE ?= a4

# Name of the build directory (to use when excluding some paths)
BUILD_DIR_NAME ?= build

# Directories to exclude from the build directory tree replication
BUILD_DIR_EXCLUDE ?= $(BUILD_DIR_NAME) .git .hg .bzr _darcs .svn CVS


# Directories
##############

# Base directory where to install files (can be overridden, should be absolute)
prefix ?= /usr/local

# Path to a complete alternative environment, usually a jail, or an installed
# system mounted elsewhere than /.
DESTDIR ?=

# Use absolute paths to avoid problems with automatic dependencies when
# building from subdirectories
T := $(abspath $T)

# Name of the current directory, relative to $T
R := $(subst $T,,$(patsubst $T/%,%,$(CURDIR)))

# Base directory where to put variants (Variants Directory)
VD ?= $T/$(BUILD_DIR_NAME)

# Generated files top directory
G ?= $(VD)/$F

# Objects (and other garbage like pre-compiled headers and dependency files)
# directory
O ?= $G/obj

# Binaries directory
B ?= $G/bin

# Libraries directory
L ?= $G/lib

# Documentation directory
D ?= $(VD)/doc

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

# Find sources files and get the corresponding object names.  The first
# argument should be the sources extension ("c" or "cpp" typically).  The
# second argument is where to search for the sources ($C if omitted).  The
# resulting files will always have the suffix "o" and the directory rewritten
# to match the directory structure (from $T) but in the $O directory.  For
# example, if $T is "/usr/src", $O is "/tmp/obj", $C is "/usr/src/curr" and it
# have 2 C sources: "/usr/src/curr/1.c" and "/usr/src/curr/dir/2.c", the call:
# $(call find_objects,c)
# Will yield "/tmp/obj/curr/1.o" and "/tmp/obj/curr/dir/2.o".
find_objects = $(patsubst $T/%.$1,$O/%.o,$(shell \
		find $(if $2,$2,$C) -name '*.$1'))

# Find files and get the their file names relative to another directory.  The
# first argument should be the files suffix (".h" or ".cpp" for example).  The
# second argument is a directory rewrite, the matched files will be rewriten to
# be in the directory specified in this argument (it defaults to the third
# argument if omitted).  The third argument is where to search for the files
# ($C if omitted).
find_files = $(patsubst $(if $3,$3,$C)/%$1,$(if $2,$2,$(if $3,$3,$C))/%$1, \
		$(shell find $(if $3,$3,$C) -name '*$1'))

# Abbreviate a file name. Cut the leading part of a file if it match to the $T
# directory, so it can be displayed as if it were a relative directory. Take
# just one argument, the file name.
abbr_helper = $(subst $T,.,$(patsubst $T/%,%,$1))
abbr = $(if $(call eq,$(call abbr_helper,$1),$1),$1,$(addprefix \
		$(shell echo $R | sed 's|/\?\([^/]\+\)/\?|../|g'),\
		$(call abbr_helper,$1)))

# Execute a command printing a nice message if $V is @.
# The first argument is mandatory and it's the command to execute. The second
# and third arguments are optional and are the target name and command name to
# pretty print.
vexec_pc = $(if $1,\033[$1m%s\033[00m,%s)
vexec_p = $(if $(COLOR), \
	'   $(call vexec_pc,$(COLOR_CMD)) $(call vexec_pc,$(COLOR_ARG))\n$(if \
			$(COLOR_OUT),\033[$(COLOR_OUT)m)', \
	'   %s %s\n')
vexec = $(if $V,printf $(vexec_p) \
		'$(call abbr,$(if $3,$(strip $3),$(firstword $1)))' \
		'$(call abbr,$(if $2,$(strip $2),$@))' ; )$1 \
		$(if $V,$(if $(COLOR),$(if $(COLOR_OUT), \
				; r=$$? ; printf '\033[00m' ; exit $$r)))

# Same as vexec but it silence the echo command (prepending a @ if $V).
exec = $V$(call vexec,$1,$2,$3)

# Compile a source file to an object, generating pre-compiled headers (if
# $(GCH) is non-empty) and dependencies. The pre-compiled headers are generated
# only if the system includes change. This function is designed to be used as
# a command in a rule.  The first argument is the type of file to compile
# (typically "c" or "cpp").  What to compile and the output files are built
# using the automatic variables from a rule.  The second argument is the base
# output directory (typically $O).  You can add non-propagated object-specific
# flags defining a variable with the name of the target followed with
# ".EXTRA_FLAGS".
#
# XXX: The pre-compiled headers generation is not very useful if you include
#      local files using #include <...>, because the system headers detection
#      is a little simplistic now, it just parse the source file and all its
#      dependencies searching for lines starting with "#include <" and
#      extracting the included files from them.
define compile
$(if $(GCH),\
$Vif test -f $2/$*.d; then \
	tmp=`mktemp`; \
	h=`awk -F: '!$$0 {f = 1} $$0 && f {print $$1}' $2/$*.d`; \
	grep -h '^#include <' $< $$h | sort -u > "$$tmp"; \
	if diff -q -w "$2/$*.$1.h" "$$tmp" > /dev/null 2>&1; \
	then \
		rm "$$tmp"; \
	else \
		mv "$$tmp" "$2/$*.$1.h"; \
		$(call vexec,$(COMPILE.$1) $($@.EXTRA_FLAGS) \
			-o "$2/$*.$1.h.gch" "$2/$*.$1.h",$2/$*.$1.h.gch); \
	fi \
else \
	touch "$2/$*.$1.h"; \
fi \
)
$(call exec,$(COMPILE.$1) $($@.EXTRA_FLAGS) -o $@ -MMD -MP \
		$(if $(GCH),-include $2/$*.$1.h) $<)
endef

# Link object files to build an executable. The objects files are taken from
# the prerequisite files ($O/%.o). If in the prerequisite files are shared
# objects ($L/lib%.so), they are included as libraries to link to (-l%). This
# function is designed to be used as a command in a rule. The output name is
# taken from the rule automatic variables. If an argument is provided, it's
# included in the link command line. The variable LINKER is used to link the
# executable; for example, if you want to link a C++ executable, you should use
# LINKER := $(CXX).  You can add non-propagated target-specific flags defining
# a variable with the name of the target followed with ".EXTRA_FLAGS".  You can
# specify a non-propagated object-specific linker defining a variable with the
# name of the target followed with ".LINKER".
link = $(call exec,$(if $($@.LINKER),$($@.LINKER),$(LINKER)) \
		$(LDFLAGS) $(TARGET_ARCH) $($@.EXTRA_FLAGS) -o $@ $1 \
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
# argument is the name of symbolic link to create.  The link is only created if
# it doesn't already exist.
symlink_include_dir = $(shell \
		test -L $(INCLUDE_DIR)/$1 \
			|| ln -s $C $(INCLUDE_DIR)/$1 )

# Create a file with flags used to trigger rebuilding when they change. The
# first argument is the name of the file where to store the flags, the second
# are the flags and the third argument is a text to be displayed if the flags
# have changed (optional).  This should be used as a rule action or something
# where a shell script is expected.
gen_rebuild_flags = $(shell if test x"$2" != x"`cat $1 2>/dev/null`"; then \
		$(if $3,test -f $1 && echo "$(if $(COLOR),$(if $(COLOR_WARN),\
			\033[$(COLOR_WARN)m$3\033[00m,$3),$3);";) \
		echo "$2" > $1 ; fi)

# Include sub-directory's Build.mak.  The only argument is a list of
# subdirectories for which Build.mak should be included.  The $S directory is
# set properly before including each sub-directory's Build.mak and restored
# afterwards.
define build_subdir_code
_parent__$d__dir_ := $$S
S := $$(if $$(_parent__$d__dir_),$$(_parent__$d__dir_)/$d,$d)
include $$T/$$S/Build.mak
S := $$(_parent__$d__dir_)
endef
include_subdirs = $(foreach d,$1,$(eval $(build_subdir_code)))

# Run a command through valgrind if $(VALGRIND) is non-empty.  The first
# argument is the command to run.  If $(VALGRIND) is empty, the command is
# executed as passed to this function.  If valgrind is used, the
# $(VALGRIND_CMD) is prepended to the command to run.  See VALGRIND_CMD
# definition for extra options that can be passed as make variables.  The
# second argument is the name of the command to print when $V is non-empty (if
# omitted, the first word of the first argument is used).
valgrind = $(call exec,$(if $(VALGRIND),$(VALGRIND_CMD)) $1,\
		$(if $(VALGRIND),[$(firstword $(VALGRIND_CMD))], ),\
		$(if $2,$2,$(firstword $1)))


# Overridden flags
##################

# Warn about everything
override CPPFLAGS += -Wall

# Use the includes directories to search for includes
override CPPFLAGS += -I$(INCLUDE_DIR)

# Let the program know where it will be installed
override CPPFLAGS += -DPREFIX=$(prefix)

# Be standard compliant
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
	$(call compile,c,$O)

# Compile C++ objects
$O/%.o: $T/%.cpp $G/compile-cpp-flags
	$(call compile,cpp,$O)

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

# Run doxygen to build the documentation.  It expects the first prerequisite to
# be the Doxyfile to use and the next prerequisites the input files.  You
# can override Doxyfile configuration variables by defining a DOXYGEN_VARS
# Make variable for this rule.  For example, defining:
# PROJECT_NAME := myproj
# DOXYGEN_VARS := PROJECT_NAME
# You can override Doxygen's PROJECT_NAME configuration option. Optionally, you
# can define DOXYGEN_VARS_PREFIX too, to avoid polluting your Makefile with
# Doxygen variables.  For example:
# DOXY.PROJECT_NAME := myproj
# DOXYGEN_VARS_PREFIX := DOXY.
# DOXYGEN_VARS := PROJECT_NAME
# This rule might be still a little restrictive, but you can always make your
# own if it doesn't fit your needs ;)
$D/%/doxygen-stamp:
	$V mkdir -p $(@D)
	$(call exec,(cat $<; \
		echo "FULL_PATH_NAMES=YES"; \
		$(if $(filter INPUT,$(DOXYGEN_VARS)),,\
			echo "INPUT=$(patsubst $(<D)/%,$(INCLUDE_DIR)/$*/%, \
					$(wordlist 2,$(words $^),$^))";) \
		echo "OUTPUT_DIRECTORY=$(@D)"; \
		echo "STRIP_FROM_PATH=$(INCLUDE_DIR)"; \
		echo "STRIP_FROM_INC_PATH=$(INCLUDE_DIR)"; \
		echo "QUIET=$(if $V,YES,NO)"; \
		$(foreach v,$(DOXYGEN_VARS),\
				echo '$v=$($(DOXYGEN_VARS_PREFIX)$v)';) \
		) | doxygen -,$(@D),doxygen)
	$V touch $@

# Run Sphinx to build the documentation.  It expects the variable SPHINX_DIR
# to be set to the directory where the Sphinx's conf.py and reST source files
# are.  This rule is a little restrictive, but you can always make your own if
# it doesn't fit your needs ;)
$D/%/sphinx-stamp: $G/sphinx-flags
	$V mkdir -p $(@D)/$(SPHINX_FORMAT)
	$(call exec,$(SPHINX) $(if $V,-q) -b $(SPHINX_FORMAT) \
		-d $(@D)/doctrees -D latex_paper_size=$(SPHINX_PAPERSIZE) \
		$(SPHINX_DIR) $(@D)/$(SPHINX_FORMAT),$(@D),$(SPHINX))
	$V touch $@

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
	$(call exec,$(RM) -r $(VD),$(VD))

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

# Phony rule to build all documentation targets (sub-makefiles can append
# documentation to build to the $(doc) variable).
.PHONY: doc
doc: $$(doc)

# Phony rule to build and run all test (sub-makefiles can append targets to
# build and run tests to the $(test) variable).
.PHONY: test
test: $$(test)


# Create build directory structure
###################################

# Create $O, $B, $L, $D and $(INCLUDE_DIR) directories and replicate the
# directory structure of the project into $O. Create one symbolic link "last"
# to the current build directory.
#
# NOTE: the second mkdir can yield no arguments if the project don't have any
#       subdirectories, that's why the current directory "." is included, so it
#       won't show an error message in case of no subdirectories.
setup_build_dir__ := $(shell \
	mkdir -p $O $B $L $D $(INCLUDE_DIR) $(addprefix $O,$(patsubst $T%,%,\
		$(shell find $T -type d $(foreach d,$(BUILD_DIR_EXCLUDE), \
				-not -path '*/$d' -not -path '*/$d/*')))); \
	rm -f $(VD)/last && ln -s $F $(VD)/last )


# Automatic rebuilding when flags or commands changes
######################################################

# Re-compile C files if one of this variables changes
COMPILE.c.FLAGS := $(call varcat,CC CPPFLAGS CFLAGS TARGET_ARCH prefix)

# Re-compile C++ files if one of this variables changes
COMPILE.cpp.FLAGS := $(call varcat,CXX CPPFLAGS CXXFLAGS TARGET_ARCH prefix)

# Re-link binaries and libraries if one of this variables changes
LINK.o.FLAGS := $(call varcat,LD LDFLAGS TARGET_ARCH)

# Re-build sphinx documentation if one of these variables changes
SPHINX.FLAGS := $(call varcat,SPHINX SPHINX_FORMAT SPHINX_PAPERSIZE)

# Create files containing the current flags to trigger a rebuild if they change
setup_flag_files__ := $(call gen_rebuild_flags,$G/compile-c-flags, \
	$(COMPILE.c.FLAGS),C compiler)
setup_flag_files__ := $(setup_flag_files__)$(call gen_rebuild_flags, \
	$G/compile-cpp-flags, $(COMPILE.cpp.FLAGS),C++ compiler)
setup_flag_files__ := $(setup_flag_files__)$(call gen_rebuild_flags, \
	$G/link-o-flags, $(LINK.o.FLAGS),linker)
setup_flag_files__ := $(setup_flag_files__)$(call gen_rebuild_flags, \
	$G/sphinx-flags, $(SPHINX.FLAGS),sphinx)

# Print any generated message (if verbose)
$(if $V,$(if $(setup_flag_files__), \
	$(info !! Flags or commands changed:$(setup_flag_files__) re-building \
			affected files...)))

endif
