#!/bin/sh

NASM_URL="https://www.nasm.us/pub/nasm/stable/nasm-2.16.03.tar.xz"
MAKE_URL="https://ftpmirror.gnu.org/make/make-4.4.1.tar.gz"
BUSYBOX_URL="https://github.com/rmyorston/busybox-w32/archive/refs/tags/FRP-5398-g89ae34445.tar.gz"
VIM_URL="https://github.com/vim/vim/archive/v9.1.0660/vim-9.1.0660.tar.gz"
FILE_URL="http://ftp.astron.com/pub/file/file-5.45.tar.gz"
LIBARCHIVE_URL="https://www.libarchive.de/downloads/libarchive-3.7.4.tar.xz"
CURL_URL="https://curl.se/download/curl-8.8.0.tar.xz"
W64DEVKIT_URL="https://github.com/skeeto/w64devkit/archive/refs/tags/v1.23.0.tar.gz"
PDCURSES_URL="https://github.com/wmcbrine/PDCurses/archive/refs/tags/3.9.tar.gz"
# TODO add release on neptunium-base-files and use that instead of directly using the master branch
NEPTUNIUM_BASE_URL="https://github.com/heliumhydride/neptunium-base-files/archive/refs/heads/master.tar.gz"


LIBRESSL_URL="https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.9.2.tar.gz"
LIBGNURX_URL="https://downloads.sourceforge.net/mingw/Other/UserContributed/regex/mingw-regex-2.5.1/mingw-libgnurx-2.5.1-src.tar.gz"

DEPENDS_X86_URL="https://www.dependencywalker.com/depends22_x86.zip"
DEPENDS_AMD64_URL="https://www.dependencywalker.com/depends22_x64.zip"

CONEMU_URL="https://github.com/Maximus5/ConEmu/releases/download/v23.07.24/ConEmuPack.230724.7z"
X64DBG_URL="https://downloads.sourceforge.net/project/x64dbg/snapshots/snapshot_2024-07-21_20-36.zip"

LLVM_MINGW_SRC_URL="https://github.com/mstorsjo/llvm-mingw/archive/refs/tags/20240619.tar.gz"
LLVM_MINGW_BIN_AMD64_URL="https://github.com/mstorsjo/llvm-mingw/releases/download/20240619/llvm-mingw-20240619-msvcrt-x86_64.zip"
LLVM_MINGW_BIN_X86_URL="https://github.com/mstorsjo/llvm-mingw/releases/download/20240619/llvm-mingw-20240619-msvcrt-i686.zip"
LLVM_MINGW_BIN_ARM64_URL="https://github.com/mstorsjo/llvm-mingw/releases/download/20240619/llvm-mingw-20240619-ucrt-aarch64.zip"

# neptunium base files
download_neptunium_base() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$NEPTUNIUM_BASE_URL" || exit 1
  tar zxvf "$NP_BUILDDIR"/download/neptunium-base-files-*.tar.gz -C "$NP_BUILDDIR"/build
  mv "$NP_BUILDDIR"/build/neptunium-base-files-* "$NP_BUILDDIR"/build/neptunium-base-files
}

install_neptunium_base() {
  cp -rv "$NP_BUILDDIR"/build/neptunium-base-files/common/*  "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/
  cp -rv "$NP_BUILDDIR"/build/neptunium-base-files/"$ARCH"/* "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/
}

# busybox-w32 (https://frippery.org/busybox-w32)
download_busybox_w32() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$BUSYBOX_URL" || exit 1
  tar zxvf "$NP_BUILDDIR"/download/busybox-w32-FRP-*.tar.gz -C "$NP_BUILDDIR"/build || exit 1
  mv "$NP_BUILDDIR"/build/busybox-w32-FRP-* "$NP_BUILDDIR"/busybox-w32 || exit 1
}

build_busybox_w32() {
  cd "$NP_BUILDDIR/build/busybox-w32" || error "directory error"
  CROSS_COMPILE="${TARGET_HOST}-"
  case $ARCH in
    amd64) make mingw64_defconfig;;
    x86)   make mingw32_defconfig;;
    arm64) make mingw64a_defconfig;;
  esac
  # patch config accordingly to neptunium64_config
  make -j${BUILD_JOBS}
}

install_busybox_w32() {
  # build aliases.c from w64devkit
  cd "$NP_BUILDDIR"/build/busybox-w32 || error "directory error"
  cp busybox.exe -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || exit 1
}

# libarchive (bsdcpio, bsdtar)
download_libarchive() {
  cd "$NP_BUILDDIR/download" || exit 1
  $_dl_cmd "$LIBARCHIVE_URL" || exit 1
  tar Jxvf "$NP_BUILDDIR"/download/libarchive-*.tar.xz -C "$NP_BUILDDIR"/build || exit 1
  mv "$NP_BUILDDIR"/libarchive-* "$NP_BUILDDIR"/libarchive || exit 1
}

build_libarchive() {
  cd "$NP_BUILDDIR"/libarchive || exit 1
  ./configure --host="$TARGET_HOST" --prefix=/"$BUILD_PREFIX" --disable-bsdcat --disable-bsdunzip --enable-bsdcpio --enable-bsdtar
  make -j${BUILD_JOBS}
}

install_libarchive() {
  make install DESTDIR="$NP_BUILDDIR"/install_dir
}

# Libressl (required for Curl)
download_host_libressl() {
  return 0 # TODO
}

build_host_libressl() {
  return 0 # TODO
}

install_host_libressl() {
  return 0 # TODO
}

install_libressl_libs() {
  return 0 # TODO
}

# Curl
download_curl() {
  return 0 # TODO
}

build_curl() {
  return 0 # TODO
}

install_curl() {
  return 0 # TODO
}

# libgnurx (required for File)
download_host_libgnurx() {
  return 0 # TODO
}

build_host_libgnurx() {
  return 0 # TODO
}

install_host_libgnurx() {
  return 0 # TODO
}

install_libgnurx_libs() {
  return 0 # TODO
}

# File
download_file() {
  return 0 # TODO
}

build_file() {
  return 0 # TODO
}

install_file() {
  return 0 # TODO
}

# ConEmu
download_conemu() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  if [ -n "$CONEMU_CUSTOM_PATH" ]; then # if we use custom conemu.7z
    cp -v "$CONEMU_CUSTOM_PATH" "$NP_BUILDDIR"/download/conemu.7z
  else
    $_dl_cmd "$CONEMU_CUSTOM_PATH" || exit 1
    mv -v "$NP_BUILDDIR"/download/ConEmuPack.*.7z "$NP_BUILDDIR"/download/conemu.7z
  fi
  mkdir -v "$NP_BUILDDIR"/build/conemu
  7z x "$NP_BUILDDIR"/download/conemu.7z -o"$NP_BUILDDIR"/build/conemu/
}

#build_conemu() {
#  cd "$BP_BUILDDIR"/build/conemu/src
#  CROSS_HOST="${TARGET_HOST}-" make -j12 -f makefile_all_gcc WIDE=y
#}

install_conemu() {
  mkdir -pv "$NP_BUILDDIR"/install_dir/share/conemu
  cp -rv "$NP_BUILDDIR"/build/conemu/* "$NP_BUILDDIR"/install_dir/share/conemu/
}

# LLVM-MinGW (http://github.com/mstorsjo/llvm-mingw)
download_llvm() {
  cd "$NP_BUILDDIR"/download || error "directory error"  
  if [ "$BUILD_LLVM" = 1 ]; then
    $_dl_cmd "$LLVM_MINGW_SRC_URL"
    tar zxvf "$NP_BUILDDIR"/download/llvm-mingw-*.tar.gz
  else
    case "$ARCH" in
      amd64) $_dl_cmd "$LLVM_MINGW_BIN_AMD64_URL";;
      x86) $_dl_cmd "$LLVM_MINGW_BIN_X86_URL";;
      arm64) $_dl_cmd "$LLVM_MINGW_BIN_ARM64_URL";;
    esac
    unzip -d "$NP_BUILDDIR"/build "$NP_BUILDDIR"/download/llvm-mingw-*.zip
  fi
  mv -v "$NP_BUILDDIR"/build/llvm-mingw-* "$NP_BUILDDIR"/build/llvm-mingw
}

build_llvm() {
  cd "$NP_BUILDDIR"/llvm-mingw || error "directory error"
  # also installs llvm-mingw in the process, which is quite handy
  ./build-all.sh --host="$TARGET_HOST" "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"
}

install_llvm() {
  cp -rv "$NP_BUILDDIR"/build/llvm-mingw/* "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"
}

# Netwide assembler
download_nasm() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$NASM_URL" || exit 1
  tar Jxvf "$NP_BUILDDIR"/download/nasm-*.tar.xz -C "$NP_BUILDDIR"/build
  mv -v "$NP_BUILDDIR"/build/nasm-* "$NP_BUILDDIR"/build/nasm
}

build_nasm() {
  ./configure --host="$TARGET_HOST" --prefix="$BUILD_PREFIX"
  make -j${BUILD_JOBS}
}

install_nasm() {
  cd "$NP_BUILDDIR"/build/nasm || error "directory error"
  cp -v nasm.exe ndisasm.exe "$NP_BUILDDIR"/install_dur/"$BUILD_PREFIX"/bin
}

# GNU Make
download_gmake() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$MAKE_URL" || exit 1
  tar zxvf "$NP_BUILDDIR"/download/make-*.tar.gz -C "$NP_BUILDDIR"/build
  mv -v "$NP_BUILDDIR"/build/make-* "$NP_BUILDDIR"/build/make
}

build_gmake() {
  cd "$NP_BUILDDIR"/build/make || error "directory error"
  ./configure --disable-nls --host="$TARGET_HOST" --prefix="$BUILD_PREFIX"
  make -j${BUILD_JOBS}
}

install_gmake() {
  cd "$NP_BUILDDIR"/build/make || error "directory error"
  make install DESTDIR="$NP_BUILDDIR/install_dir"
}

# Vim
download_vim() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$VIM_URL" || error "downloading vim failed"
  tar zxvf "$NP_BUILDDIR"/download/vim-*.tar.gz -C "$NP_BUILDDIR"/build
  mv -v "$NP_BUILDDIR"/build/vim-* "$NP_BUILDDIR"/build/vim
}

build_vim() {
  cd "$NP_BUILDDIR"/build/vim/src || error "directory error"
  make -f Make_ming.mak \
  STATIC_STDCPLUS=yes \
  FEATURES=HUGE \
  GUI=yes \
  OLE=yes \
  NETBEANS=no \
  CROSS_COMPILE=${TARGET_HOST}- \
  CROSS=yes \
  HAS_GCC_EH=no \
  VIMDLL=yes \
  WINVER=0x0601 \
  UNDER_CYGWIN=yes \
  -j${BUILD_JOBS}
}

install_vim() {
  cd "$NP_BUILDDIR"/build/vim/src
  mkdir -pv "$NP_BUILDDIR"/install_dir/share/vim
  cp -rv ../runtime "$NP_BUILDDIR"/install_dir/share/vim/
  cp -v vimrun.exe gvim.exe vim.exe "$NP_BUILDDIR"/install_dir/share/vim/
  cp -v xxd/xxd.exe "$NP_BUILDDIR"/install_dir/bin/
  # the vi/vim/gvim launchers are already installed by neptunium-base-files
}

# pkg-config, vc++filt, debugbreak from w64devkit
download_w64devkit() {
  cd "$NP_BUILDDIR"/download
  $_dl_cmd "$W64DEVKIT_URL"  || error "downloading w64devkit failed"
  tar zxvf "$NP_BUILDDIR"/download/w64devkit-*.tar.gz -C "$NP_BUILDDIR"/build
  mv -v "$NP_BUILDDIR"/build/w64devkit-* "$NP_BUILDDIR"/build/w64devkit
}

build_pkg_config() {
  cd "$NP_BUILDDIR"/build/w64devkit/src || error "directory error"
  ${TARGET_HOST}-gcc -Os -fno-asynchronous-unwind-tables -fno-builtin -Wl,--gc-sections \
        -s -nostdlib -DPKG_CONFIG_PREFIX="\"/$ARCH\"" -o pkg-config.exe pkg-config.c -lkernel32
}

build_vcppfilt() {
  cd "$NP_BUILDDIR"/build/w64devkit/src || error "directory error"
  ${TARGET_HOST}-gcc -Os -fno-asynchronous-unwind-tables -fno-builtin -Wl,--gc-sections \
        -s -nostdlib -o vc++filt.exe vc++filt.c -lkernel32 -lshell32 -ldbghelp
}


build_debugbreak() {
  cd "$NP_BUILDDIR"/build/w64devkit/src || error "directory error"
  ${TARGET_HOST}-gcc -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
        -o debugbreak.exe debugbreak.c -lkernel32
}

install_pkg_config() {
  cp -v "$NP_BUILDDIR"/build/w64devkit/src/pkg-config.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
}

install_vcppfilt() {
  cp -v "$NP_BUILDDIR"/build/w64devkit/src/vc++filt.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
}

install_debugbreak() {
  cp -v "$NP_BUILDDIR"/build/w64devkit/src/debugbreak.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
}

# PDCurses
download_pdcurses() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$PDCURSES_URL" || exit 1
  tar zxvf "$NP_BUILDDIR"/download/PDCurses-*.tar.gz -C "$NP_BUILDDIR"/build
  mv -v "$NP_BUILDDIR"/build/PDCurses-* "$NP_BUILDDIR"/build/pdcurses
}

build_pdcurses() {
  cd "$NP_BUILDDIR"/build/pdcurses/wincon || exit 1
  make CC=${TARGET_HOST}-gcc \
       LINK=${TARGET_HOST}-gcc \
       AR=${TARGET_HOST}-ar \
       STRIP=${TARGET_HOST}-strip \
       WINDRES=${TARGET_HOST}-windres \
       WIDE=Y DLL=Y UTF8=Y -j${BUILD_JOBS}
}

install_pdcurses() {
  # PDCurses is both a dependency for building vim and a package for the final build, so we install both into the toolchain directory and into the base system

  # cd "$NP_BUILDDIR"/build/pdcurses || exit 1
  # base system install
  cp -v "$NP_BUILDDIR"/build/pdcurses/curses.h "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include
  cp -v "$NP_BUILDDIR"/build/pdcurses/menu.h "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include

  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a   "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib/pdcurses.a
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a   "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib/curses.a

  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/bin/pdcurses.dll
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/bin/curses.dll

  # vim dependency
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin

  # host toolchain install
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a "$NP_BUILDDIR"/host/
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/host/
}

# x64dbg
download_x64dbg() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  if [ -n "$X64DBG_CUSTOM_PATH" ]; then # if we use custom x64dbg.zip
    cp -v "$X64DBG_CUSTOM_PATH" "$NP_BUILDDIR"/download/x64dbg.zip
  else
    $_dl_cmd "$MAKE_URL" || exit 1
    mv -v "$NP_BUILDDIR"/download/snapshot-*.zip "$NP_BUILDDIR"/download/x64dbg.zip
  fi
  mkdir -v "$NP_BUILDDIR"/build/x64dbg
  unzip "$NP_BUILDDIR"/download/x64dbg.zip -d "$NP_BUILDDIR"/build/x64dbg/
}

install_x64dbg() {
  mkdir -pv "$NP_BUILDDIR"/install_dir/share/x64dbg
  cp -rv "$NP_BUILDDIR"/build/x64dbg/release "$NP_BUILDDIR"/install_dir/share/x64dbg/
}

# Dependency walker (depends.exe)
download_depends() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  if [ "$ARCH" = "x86" ]; then
    $_dl_cmd "$DEPENDS_X86_URL" || exit 1
  else # this assumes arm64-x86_64 compatibility, and so assumes windows 11...
    $_dl_cmd "$DEPENDS_AMD64_URL" || exit 1
  fi
  mkdir -v "$NP_BUILDDIR"/build/depends
  unzip "$NP_BUILDDIR"/download/depends*.zip -d "$NP_BUILDDIR"/build/depends/
}

install_depends() {
  cp -v "$NP_BUILDDIR"/build/depends/depends.* "$NP_BUILDDIR"/install_dir/bin/
}

