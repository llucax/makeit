
# Use debug flavor by default
F := dbg

# C compiler
CC := gcc

# Use pre-compiled headers
GCH := 1

# Warn about everything
override CPPFLAGS += -Wall
override LDFLAGS += -Wall

# Be standard compliant
override CFLAGS += -std=c99 -pedantic
override CXXFLAGS += -std=c++98 -pedantic


# Flavors (variants) flags
##########################

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

