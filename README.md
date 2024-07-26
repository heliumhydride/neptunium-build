<a href=#><img src=https://raw.githubusercontent.com/heliumhydride/neptunium-build/master/misc/pics/neptunium32.png width=80 align=left></a>
# Neptunium
A handy development environment for Windows 7+

## Using Neptunium
### System requirements
- An x86/arm64 device with Windows 7 or over
- [7-Zip](https://7-zip.org) or [WinRAR](https://www.rarlab.com/download.htm) to decompress

### Running
- Download a 7z file from the [releases page](https://github.com/heliumhydride/neptunium-build/releases) according to your architecture
- Extract it to the root of any drive (C:/, D:/, ...)
- Run neptunium.cmd in the extracted directory

## Building neptunium
### Build requirements
- A Unix-like environment like Linux, MSYS2, FreeBSD, w64devkit, ... (Or Neptunium itself lol)
- GNU make
- p7zip, tar, gzip, xz, unzip
- A mingw toolchain (gcc or llvm)

### The building process
- Clone this repository:
```git clone https://github.com/heliumhydride/neptunium-build```
- Go into the `neptunium-build`directory
- To build for `amd64` architecture (corresponds to `x86_64`), run
```./build.sh -a amd64```
- (Run `./build.sh -h` to see available architectures, build options, ...)

## Credits
* [w64devkit](https://github.com/skeeto/w64devkit), a few files from this project are used and the main inspiration for this project
- [llvm-mingw](https://github.com/mstorsjo/llvm-mingw), half of what makes this project possible
- [busybox-w32](https://github.com/rmyorston/busybox-w32), the other half of what makes this project possible
