# PlayGSF (cross)

An attempt to visualize GBA/GB music.

A modified version of [Highly Advanced](https://caitsith2.com/gsf/), the `.gsf` input plugin for Winamp, originally by CaitSith2 and Zoopd, which was ported to Linux by [Raphael Assenat](https://projects.raphnet.net/#playgsf), with a visualizer added by [yshui](https://github.com/yshui/playgsf), and modifications to the project structure and build process to target Windows by myself.

![Demo](https://github.com/Savestate2A03/playgsf-cross/raw/main/demo.gif)

## Limitations

PCM channels are not visualized.

## Changelog

### v0.8.0

- Update configuration for easier compilation on Windows

### v0.7.1

- Fixed a crash when the -e option was used.

Thanks to nemesis661 for reporting this!

### v0.7.0

Got a patch from Urpo Lankinen which adds:

- Output to wave file
- Sound output using [libao](http://www.xiph.org/ao/)

### v0.6.0

- Improvements in the configure script to support non-Linux unix like platforms (Tested on freebsd)
- Added a configure option to disable optimisations in case gcc runs out of memory (happens on freebsd with g++ 3.4.2)

Many thanks to Emanuel Haupt for providing me a shell on a FreeBSD machine!

### v0.5.0  

- Added a configure script, tested on non-x86 archs and on big-endian
- Fixed a path manipulation bug and a typo
- Updated documentation

### v0.4.0

Fixed way timing/fade was handled (CaitSith2)

### v0.3.0

Sync with Highly Advanced Version 0.11

### v0.2.0

Added option -r to play files in random order and fixed a display bug

### v0.1.0

Initial release

## Building

From the original repository:
> **Note**: Since `libresample` is required to build this project and it is
> not distributed yet by most Linux distributions (not in gentoo yet, and the
> `libresample` makefile does not have an install target...), I have included
> `libresample-0.1.3` with playgsf.
>
> It will be built automatically.

### Cross-compiling for Windows

In WSL, navigate to a directory of choice and run:

```bash
git clone https://github.com/Savestate2A03/playgsf-cross
cd playgsf-cross
git submodule update --init
sudo apt install mingw-w64 autoconf automake libtool pkg-config build-essential libz-mingw-w64-dev
make PLAYGSF_TARGET=i686-w64-mingw32 -j8   # 32-bit
make PLAYGSF_TARGET=x86_64-w64-mingw32 -j8 # 64-bit
```

### Compiling Natively for Linux

```bash
git clone https://github.com/Savestate2A03/playgsf-cross
cd playgsf-cross
sudo apt install build-essential libao-dev libsdl2-dev zlib1g-dev
make -j8
```

### Makefile targets

```bash
# -----------------------------------------------------------------------------
git submodule update --init             # only required for cross-compile
# -----------------------------------------------------------------------------
make                                    # native build
make PLAYGSF_TARGET=i686-w64-mingw32    # cross-compile, 32-bit Windows
make PLAYGSF_TARGET=x86_64-w64-mingw32  # cross-compile, 64-bit Windows
# -----------------------------------------------------------------------------
# NOTE: PLAYGSF_TARGET must be passed in to these as well if cross-compiling!
# -----------------------------------------------------------------------------
make libs                               # build third-party libs (cross)
make libao                              # build libao (cross)
make sdl2                               # build SDL2 (cross)
make clean                              # remove playgsf objects and binary
make distclean                          # ...and remove staging/libs (cross)
make [target] -jX                       # build in parallel
# -----------------------------------------------------------------------------
```

### Additional Makefile options

You may pass some additional options to the `Makefile`:

|**Options**|**Choices**|**Default**|**Description**|
|-|-|-|-|
|`CCORE`|`yes`, `no`|`yes`|Use the C emulation core.<br>Originally, `configure.in` auto-picked the ASM core on x86 hosts.<br>We default to C for compatibility.|
|`INTERPOLATION`|`yes`, `no`|`yes`|Compile sound interpolation code|
|`OPTIMISATIONS`|`yes`, `no`|`yes`|Enable `-O3`|

Example: `make -j8 TARGET=i686-w64-mingw32 CCORE=no INTERPOLATION=no OPTIMISATIONS=no`

## Usage

```txt
playgsf{.exe} [options] [files...]
  -l        Enable low pass filer
  -s        Detect silence
  -L        Set silence length in seconds (for detection). Default 5
  -t        Set default track length in milliseconds. Default 150000 ms
  -i        Ignore track length (use default length)
  -e        Endless play
  -r        Play files in random order
  -h        Displays what you are reading right now
```

Example: `playgsf.exe Krawall-1.minigsf`

**NOTE**: `.minigsf` files usually requires a library file (`.gsflib`) alongside. `playgsf.exe` expects
this file to be in the same directory as the `.minigsf`

## Music

There are gsf tunes available from [GSF Central](http://www.caitsith2.com/gsf/)!