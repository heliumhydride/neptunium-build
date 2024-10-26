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
  # TODO patch config accordingly to neptunium64_config
  make -j${BUILD_JOBS}
}

install_busybox_w32() {
  # busybox aliases installed from w64devkit busybox-alias.c
  cd "$NP_BUILDDIR"/build/busybox-w32 || error "directory error"
  cp busybox.exe -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || exit 1
}

# libarchive (bsdcpio, bsdtar)
download_libarchive() {
  cd "$NP_BUILDDIR/download" || exit 1
  $_dl_cmd "$LIBARCHIVE_URL" || exit 1
  tar Jxvf "$NP_BUILDDIR"/download/libarchive-*.tar.xz -C "$NP_BUILDDIR"/build || exit 1
  mv -v "$NP_BUILDDIR"/libarchive-* "$NP_BUILDDIR"/libarchive || exit 1
}

build_libarchive() {
  cd "$NP_BUILDDIR"/build/libarchive || error "directory error"
  ./configure --host="$TARGET_HOST" --prefix="$BUILD_PREFIX" --disable-bsdcat --disable-bsdunzip --enable-bsdcpio --enable-bsdtar || error "build error"
  make -j${BUILD_JOBS} || error "build error"
}

install_libarchive() {
  make install DESTDIR="$NP_BUILDDIR"/install_dir
  mv -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/bsdtar.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/tar.exe
  mv -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/bsdcpio.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/cpio.exe
}

# Libressl (required for Curl)
download_libressl() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$LIBRESSL_URL" || exit 1
  tar zxvf "$NP_BUILDDIR"/download/libressl-*.tar.gz -C "$NP_BUILDDIR"/build || exit 1
  mv -v "$NP_BUILDDIR"/libressl-* "$NP_BUILDDIR"/libressl || exit 1
}

build_host_libressl() {
  cd "$NP_BUILDDIR"/build/libressl || error "directory error"
  ./configure --host="$TARGET_HOST" --prefix="$NP_BUILDDIR"/host --disable-nc || error "build error"
  make -j"$BUILD_JOBS" || error "build error"
}

install_host_libressl() {
  cd "$NP_BUILDDIR"/build/libressl || error "directory error"
  make install
}

build_libressl() {
  cd "$NP_BUILDDIR"/build/libressl || error "directory error"
  make distclean || error "build error" # we built host-libressl earlier, so we need to restart from zero to change the --prefix setting... this is why gnu autotools is absolute hot garbage
  ./configure --host="$TARGET_HOST" --prefix="$BUILD_PREFIX" --disable-nc || error "build error"
  make -j"$BUILD_JOBS" || error "build error"
}

install_libressl() {
  cd "$NP_BUILDDIR"/build/libressl || error "directory error"
  make install DESTDIR="$NP_BUILDDIR"/install_dir
}

# Curl
download_curl() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$CURL_URL" || error "download error"
  tar Jxvf "$NP_BUILDDIR"/download/curl-*.tar.xz -C "$NP_BUILDDIR"/build
  mv -v "$NP_BUILDDIR"/build/curl-* "$NP_BUILDDIR"/build/curl
}

build_curl() {
  cd "$NP_BUILDDIR"/build/curl || error "directory error"
  ./configure --prefix="$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX" \
              --with-openssl="$NP_BUILDDIR"/host \
              --enable-threaded-resolver \
              --host="$TARGET_HOST" \
              --includedir="$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include \
              --libdir="$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib \
              --with-ca-path="$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/etc/ssl/certs || error "build error"
  make -j"$BUILD_JOBS" || error "build error"
}

install_curl() {
  cd "$NP_BUILDDIR"/build/curl || error "directory error"
  make install
  # curl runtime dll needs to be copied alongside curl.exe
  cp -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib/libcurl-*.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
}

# libgnurx (required for File)
download_host_libgnurx() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$LIBGNURX_URL"
  # destdir patch from mingw-packages, should it be hardcoded like that ?
  # $_dl_cmd https://raw.githubusercontent.com/msys2/MINGW-packages/refs/heads/master/mingw-w64-libgnurx/mingw-w64-libgnurx-honor-destdir.patch
  tar zxvf "$NP_BUILDDIR"/download/mingw-libgnurx-* -C "$NP_BUILDDIR"/build/
  mv -v "$NP_BUILDDIR"/build/mingw-libgnurx-* "$NP_BUILDDIR"/build/libgnurx
}

build_libgnurx() {
  cd "$NP_BUILDDIR"/build/libgnurx || error "directory error"
  ./configure --prefix="$BUILD_PREFIX" --host="$TARGET_HOST"
  make -j"$BUILD_JOBS"
}

install_host_libgnurx() {
  mkdir -v "$NP_BUILDDIR"/host/lib
  mkdir -v "$NP_BUILDDIR"/host/bin
  mkdir -v "$NP_BUILDDIR"/host/include
  cp -v "$NP_BUILDDIR"/build/libgnurx/regex.h "$NP_BUILDDIR"/host/include
  cp -v "$NP_BUILDDIR"/build/libgnurx/libgnurx-*.dll "$NP_BUILDDIR"/host/bin
  cp -v "$NP_BUILDDIR"/build/libgnurx/libgnurx.dll.a "$NP_BUILDDIR"/host/lib
  cp -v "$NP_BUILDDIR"/build/libgnurx/libregex.a "$NP_BUILDDIR"/host/lib
}

install_libgnurx() {
  mkdir -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib
  mkdir -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include
  mkdir -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin
  cp -v "$NP_BUILDDIR"/build/libgnurx/regex.h "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include
  cp -v "$NP_BUILDDIR"/build/libgnurx/libgnurx-*.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin
  cp -v "$NP_BUILDDIR"/build/libgnurx/libgnurx.dll.a "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib
  cp -v "$NP_BUILDDIR"/build/libgnurx/libregex.a "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib
}

# File
download_file() {
  cd "$NP_BUILDDIR"/download || error "directory error"
  $_dl_cmd "$FILE_URL" || error "download error"
  tar zxvf "$NP_BUILDDIR"/download/file-*.tar.gz -C "$NP_BUILDDIR"/build
  mv -v "$NP_BUILDDIR"/build/file-* "$NP_BUILDDIR"/build/file
}

build_file() {
  cd "$NP_BUILDDIR"/build/file || error "directory error"
  patch -Np0 < "$NP_BUILDDIR"/patches/00-file-cdf_ctime-fix.patch || error "patch error" # fixes build error with mingw64-gcc 14.2.0
  CFLAGS="-I/tmp/win32libs/include" \
  LDFLAGS="-L/tmp/win32libs/lib" \
  ./configure --prefix="$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX" \
              --enable-static \
              --enable-shared \
              --libdir="$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib \
              --includedir="$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include \
              --host="$TARGET_HOST" \
              --disable-zlib \
              --disable-bzlib \
              --disable-lzlib \
              --disable-zstdlib \
              --disable-libseccomp || error "build error"
  make -j"$BUILD_JOBS"
}

install_file() {
  cd "$NP_BUILDDIR"/build/file || error "directory error"
  make install DESTDIR="$NP_BUILDDIR"/install_dir
  # libmagic runtime dll needs to be alongside file.exe
  cp -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/bin/libmagic-*.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
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
  cp -rv "$NP_BUILDDIR"/build/conemu/* "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/conemu/
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
  ./build-all.sh --host="$TARGET_HOST" "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/
}

install_llvm() {
  cp -rv "$NP_BUILDDIR"/build/llvm-mingw/* "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/
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
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/vim
  cp -rv ../runtime "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/vim/
  cp -v vimrun.exe gvim.exe vim.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/vim/
  cp -v xxd/xxd.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
  # the vi/vim/gvim launchers are already installed by neptunium-base-files
}

# pkg-config, vc++filt, debugbreak, busybox aliases from w64devkit
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

build_busybox_alias() {
  cd "$NP_BUILDDIR"/build/w64devkit/src || error "directory error"
  "${TARGET_HOST}-gcc" -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
        -o bbalias.exe busybox-alias.c -lkernel32
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

install_busybox_alias() {
  for prog in "arch ascii ash awk base32 base64 basename bash bc bunzip2 bzcat bzip2 cal cat cdrop chattr chmod cksum clear cmp comm cp crc32 cut date dc dd df diff dirname dos2unix drop du echo ed egrep env expand expr factor false fgrep find fold free fsync ftpget ftpput getopt grep groups gunzip gzip hd head hexdump httpd id inotifyd install ipcalc jn kill killall lash less link ln logname ls lsattr lzcat lzma lzop lzopcat man md5sum mkdir mktemp mv nc nl nproc od paste patch pdrop pgrep pidof pipe_progress pkill printenv printf ps pwd readlink realpath reset rev rm rmdir sed seq sh sha1sum sha256sum sha3sum sha512sum shred shuf sleep sort split ssl_client stat su sum sync tac tail tee test time timeout touch tr true truncate ts tsort ttysize uname unexpand uniq unix2dos unlink unlzma unlzop unxz unzip uptime usleep uudecode uuencode watch wc wget which whoami whois xargs xz xzcat yes zcat"; do
    cp -v "$NP_BUILDDIR"/build/w64devkit/src/bbalias.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/"$prog".exe
  done
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
  # make directories
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin
  mkdir -pv "$NP_BUILDDIR"/host/lib
  mkdir -pv "$NP_BUILDDIR"/host/include
  # base system install
  cp -v "$NP_BUILDDIR"/build/pdcurses/curses.h "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include
  cp -v "$NP_BUILDDIR"/build/pdcurses/menu.h "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a   "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib/libpdcurses.a
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a   "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib/libcurses.a
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/bin/libpdcurses.dll
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/bin/libcurses.dll

  # vim dependency (needs to be copied as pdcurses.dll to be used)
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/

  # host toolchain install
  cp -v "$NP_BUILDDIR"/build/pdcurses/curses.h "$NP_BUILDDIR"/host/include/
  cp -v "$NP_BUILDDIR"/build/pdcurses/menu.h "$NP_BUILDDIR"/host/include/
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a "$NP_BUILDDIR"/host/lib/libpdcurses.a
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/host/lib/libpdcurses.dll
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a "$NP_BUILDDIR"/host/lib/libcurses.a
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/host/lib/libcurses.dll
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

