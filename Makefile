# -----------------------------------------------------------------------------
# Native and Cross-compile Makefile for playgsf
# -----------------------------------------------------------------------------
# Builds natively on Linux or cross-compiles for Windows (i686 / x86_64).
# Pick a target via the PLAYGSF_TARGET variable, default is the host triple.
#
# When cross-compiling for Windows, all third-party libs (SDL2, libao, zlib,
# libgcc, libstdc++) are statically linked into the final binary without
# needing any DLLs to be bundled along with it.
#
# Two of these libraries are tracked as git submodules under ./support/ and
# are built/staged by this Makefile:
#   - ./support/libao   (xiph/libao, tag: 1.2.2)
#   - ./support/SDL2    (libsdl-org/SDL, tag: release-2.32.10)
#
# Native Linux builds use system-installed shared libraries for libao and SDL2.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Supported TARGETs
# -----------------------------------------------------------------------------
#   x86_64-linux-gnu      native 64-bit Linux (or whatever your host triple is)
#   i686-w64-mingw32      cross-compile for 32-bit Windows
#   x86_64-w64-mingw32    cross-compile for 64-bit Windows
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# File/Folder Layout
# -----------------------------------------------------------------------------
# Universal
#   build-$(PLAYGSF_TARGET)/                      playgsf-related object files
#   out-$(PLAYGSF_TARGET)/playgsf{.exe}           final compiled executable
# Cross-compile only
#   staging-$(PLAYGSF_TARGET)/                    installed third-party libs
#   support/build-$(PLAYGSF_TARGET)/{libao,SDL2}  submodule build trees
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------
#   git submodule update --init            # only required for cross-compile
#
#   make                                   # native build
#   make PLAYGSF_TARGET=i686-w64-mingw32   # cross-compile, 32-bit Windows
#   make PLAYGSF_TARGET=x86_64-w64-mingw32 # cross-compile, 64-bit Windows
#
# NOTE: PLAYGSF_TARGET must be passed in to the below targets as well!
#   make libs                              # build third-party libs (cross)
#   make libao                             # build libao (cross)
#   make sdl2                              # build SDL2 (cross)
#   make clean                             # remove playgsf objects and binary
#   make distclean                         # ...and remove staging/libs (cross)
#   make [target] -jX                      # build in parallel
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Build options (override on command line, e.g., `make INTERPOLATION=no`)
# -----------------------------------------------------------------------------
#   CCORE=yes|no           Use the C emulation core (default: yes)
#                          Original configure.in auto-picked the ASM core on
#                          x86 hosts. We default to C for compatibility.
#                          Set CCORE=no at your own risk.
#   INTERPOLATION=yes|no   Compile sound interpolation code (default: yes)
#   OPTIMISATIONS=yes|no   Enable -O3 (default: yes)
# -----------------------------------------------------------------------------

CCORE         ?= yes
INTERPOLATION ?= yes
OPTIMISATIONS ?= yes

# -----------------------------------------------------------------------------
# Prerequisites (Assuming Ubuntu WSL or Ubuntu/Debian Linux)
# -----------------------------------------------------------------------------
# Native Linux:
#   sudo apt install build-essential
#   sudo apt install libao-dev libsdl2-dev zlib1g-dev
#
# Cross-compile to Windows:
#   sudo apt install mingw-w64
#   sudo apt install autoconf automake libtool pkg-config build-essential
#   sudo apt install libz-mingw-w64-dev
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Toolchain and paths
# -----------------------------------------------------------------------------
NATIVE_TARGET  := $(shell gcc -dumpmachine)
PLAYGSF_TARGET ?= $(NATIVE_TARGET)

# Detect target OS family from the triple to pick compile/link config
ifneq (,$(findstring mingw,$(PLAYGSF_TARGET)))
    OS = windows
else
    OS = linux
endif

# Native builds use plain gcc/g++
# Cross builds use triple-prefixed binaries
ifeq ($(PLAYGSF_TARGET),$(NATIVE_TARGET))
    CC  = gcc
    CXX = g++
else
    CC  = $(PLAYGSF_TARGET)-gcc
    CXX = $(PLAYGSF_TARGET)-g++
endif

LD = $(CXX)

# Base name for out of tree build paths
BUILD_DIRNAME = build-$(PLAYGSF_TARGET)

# Build paths (absolute)
PLAYGSF_BUILD = $(abspath ./$(BUILD_DIRNAME))
STAGING       = $(abspath ./staging-$(PLAYGSF_TARGET))
SUBMODULES    = $(abspath ./support)
ifeq ($(OS),windows)
    EXE_OUT_FILE = playgsf.exe
else
    EXE_OUT_FILE = playgsf
endif
EXE_OUT_DIR   = $(abspath ./out-$(PLAYGSF_TARGET))
EXE_OUT       = $(EXE_OUT_DIR)/$(EXE_OUT_FILE)
SUPPORT_BUILD = $(SUBMODULES)/$(BUILD_DIRNAME)

# Third-party library paths
LIBAO_SRC   = $(SUBMODULES)/libao
SDL2_SRC    = $(SUBMODULES)/SDL2
LIBAO_BUILD = $(SUPPORT_BUILD)/libao
SDL2_BUILD  = $(SUPPORT_BUILD)/SDL2

# Files to check if lib builds are complete
LIBAO_A_LIB = $(STAGING)/lib/libao.a
SDL2_A_LIB  = $(STAGING)/lib/libSDL2.a

# -----------------------------------------------------------------------------
# Compile flags
# -----------------------------------------------------------------------------
DEFINES = -DLINUX -DVERSION_STR=\"0.8.0\" -DHA_VERSION_STR=\"0.11\"

ifeq ($(CCORE),yes)
    DEFINES += -DC_CORE
endif
ifeq ($(INTERPOLATION),no)
    DEFINES += -DNO_INTERPOLATION
endif

ifeq ($(OPTIMISATIONS),yes)
    OPT = -O3
else
    OPT =
endif

INCLUDES = -I. -I./VBA -I./libresample/include
ifeq ($(OS),windows)
    INCLUDES += -I$(STAGING)/include
endif

WARNS = -fpermissive -Wno-narrowing -Wno-write-strings -Wno-unused-result \
        -Wno-deprecated -Wno-format

CFLAGS   = $(OPT) $(WARNS) $(DEFINES) $(INCLUDES)
CXXFLAGS = $(OPT) -std=gnu++14 $(WARNS) $(DEFINES) $(INCLUDES)

# -----------------------------------------------------------------------------
# Link flags
# -----------------------------------------------------------------------------
#   Windows: Statically link our staged third-party libs and the gcc runtime
#     -static-libgcc/-static-libstdc++  gcc runtimes statically linked into exe
#     -Wl,-Bstatic                      use .a instead of .dll.a for user libs
#     -Wl,-Bdynamic                     dynamically link Windows OS libs
#
#   Native (Linux): dynamically link system-installed shared libs
# -----------------------------------------------------------------------------

ifeq ($(OS),windows)
    LDFLAGS         = -L$(STAGING)/lib -static-libgcc -static-libstdc++
    LIBS            = -Wl,-Bstatic \
                        -lmingw32 -lSDL2main -lSDL2 -lao -lz \
                        -Wl,-Bdynamic \
                        -lm -lkernel32 -luser32 -lgdi32 -lwinmm -limm32 -lole32 \
                        -loleaut32 -lversion -luuid -ladvapi32 -lsetupapi \
                        -lshell32 -ldinput8 -lksuser
    LIBAO_CONFIGURE = --disable-esd --disable-alsa --disable-arts \
                        --disable-nas --disable-pulse
else
    LDFLAGS         =
    LIBS            = -lao -lSDL2 -lz -lm -lpthread
    LIBAO_CONFIGURE =
endif

# -----------------------------------------------------------------------------
# Sources/objects
# -----------------------------------------------------------------------------

SRC_CPP = gsf.cpp linuxmain.cpp \
          VBA/GBA.cpp VBA/Globals.cpp VBA/Sound.cpp VBA/Util.cpp \
          VBA/bios.cpp VBA/snd_interp.cpp VBA/unzip.cpp

SRC_C = VBA/memgzio.c VBA/psftag.c \
        libresample/src/filterkit.c \
        libresample/src/resample.c \
        libresample/src/resamplesubs.c

OBJS = $(SRC_CPP:%.cpp=$(PLAYGSF_BUILD)/%.o) \
       $(SRC_C:%.c=$(PLAYGSF_BUILD)/%.o)

# =============================================================================
# Targets
# =============================================================================
.PHONY: all libs libao sdl2 clean distclean

all: $(EXE_OUT)

# -----------------------------------------------------------------------------
# Windows: lib targets build and stage from submodule sources and object
#          compilation needs the staged headers being present.
# -----------------------------------------------------------------------------
# Native (Linux): system libs are used so lib targets are no-ops essentially
# -----------------------------------------------------------------------------
ifeq ($(OS),windows)
libs:  $(LIBAO_A_LIB) $(SDL2_A_LIB)
libao: $(LIBAO_A_LIB)
sdl2:  $(SDL2_A_LIB)
$(OBJS): | $(LIBAO_A_LIB) $(SDL2_A_LIB)
else
libs libao sdl2:
	@echo "Native build using system libraries, no submodule build needed."
	@echo "In case you haven't:"
	@echo "    sudo apt install libao-dev libsdl2-dev zlib1g-dev"
endif

$(EXE_OUT): $(OBJS)
	@mkdir -p $(dir $@)
	$(LD) $(OBJS) $(LDFLAGS) $(LIBS) -o $@
	@echo
	@echo "=== Build complete ($(PLAYGSF_TARGET)) ==="
	@ls -lh $@

# -----------------------------------------------------------------------------
# Compile sources under $PLAYGSF_BUILD
# -----------------------------------------------------------------------------
$(PLAYGSF_BUILD)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(PLAYGSF_BUILD)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# -----------------------------------------------------------------------------
# libao: libao only provides autogen.sh, so we still need to generate configure
# -----------------------------------------------------------------------------
$(LIBAO_A_LIB):
	@echo "=== Building libao for $(PLAYGSF_TARGET) ==="
	cd $(LIBAO_SRC) && ./autogen.sh
	mkdir -p $(LIBAO_BUILD)
	cd $(LIBAO_BUILD) && $(LIBAO_SRC)/configure \
	    --host=$(PLAYGSF_TARGET) \
	    --prefix=$(STAGING) \
	    --disable-shared --enable-static $(LIBAO_CONFIGURE)
	$(MAKE) -C $(LIBAO_BUILD)
	$(MAKE) -C $(LIBAO_BUILD) install
	cd $(LIBAO_SRC) && rm -f configure~

# -----------------------------------------------------------------------------
# SDL2: SDL2 already provides a pregenerated configure, use it
# -----------------------------------------------------------------------------
$(SDL2_A_LIB):
	@echo "=== Building SDL2 for $(PLAYGSF_TARGET) ==="
	mkdir -p $(SDL2_BUILD)
	cd $(SDL2_BUILD) && $(SDL2_SRC)/configure \
	    --host=$(PLAYGSF_TARGET) \
	    --prefix=$(STAGING) \
	    --disable-shared --enable-static
	$(MAKE) -C $(SDL2_BUILD)
	$(MAKE) -C $(SDL2_BUILD) install

clean:
	@echo Removing $(dir $(EXE_OUT))...
	@rm -rf $(dir $(EXE_OUT))
	@echo Removing $(PLAYGSF_BUILD)...
	@rm -rf $(PLAYGSF_BUILD)

distclean: clean
	@echo Removing $(SUPPORT_BUILD)...
	@rm -rf $(SUPPORT_BUILD)
	@echo Removing $(STAGING)...
	@rm -rf $(STAGING)