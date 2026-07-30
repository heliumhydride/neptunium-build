#!/bin/sh

generate_wget_list() {
  # build the list of files to download
  cp -v "$NP_BUILDDIR"/dl-lists/common.txt "$NP_BUILDDIR"/download/wget-list.txt

  if [ "$BUILD_LLVM" = 1 ]; then
    cat "$NP_BUILDDIR"/dl-lists/llvm-mingw-src.txt | tee -a "$NP_BUILDDIR"/download/wget-list.txt
  else
    cat "$NP_BUILDDIR"/dl-lists/llvm-mingw-bin-"$ARCH".txt | tee -a "$NP_BUILDDIR"/download/wget-list.txt
  fi

  if [ -z "$X64DBG_CUSTOM_PATH" ]; then
    cat "$NP_BUILDDIR"/dl-lists/x64dbg-bin.txt | tee -a "$NP_BUILDDIR"/download/wget-list.txt
  else
    cp -v "$X64DBG_CUSTOM_PATH" "$NP_BUILDDIR"/download/x64dbg.zip || error "copying error"
  fi

  if [ -z "$CONEMU_CUSTOM_PATH" ]; then
    cat "$NP_BUILDDIR"/dl-lists/conemu-bin.txt | tee -a "$NP_BUILDDIR"/download/wget-list.txt
  else
    cp -v "$CONEMU_CUSTOM_PATH" "$NP_BUILDDIR"/download/conemu.7z || error "copying error"
  fi

  [ "$FREE_SOFTWARE_ONLY" = 1 ] || {
    cat "$NP_BUILDDIR"/dl-lists/nonfree-"$ARCH".txt | tee -a "$NP_BUILDDIR"/download/wget-list.txt
  }
}

download_sources() {
  generate_wget_list
  cd "$NP_BUILDDIR"/download || error "directory error"
  case "$DOWNLOAD_AGENT" in
    aria2) aria2c -i wget-list.txt --auto-file-renaming=false -x "$DOWNLOAD_JOBS" || error "download failed";;
    wget) if [ "$DOWNLOAD_JOBS" -le 1 ]; then
            wget -i wget-list.txt || error "download failed"
          else
            (cat wget-list.txt | xargs -n 1 -P "$DOWNLOAD_JOBS" wget) || error "download failed"
          fi
    ;;
    curl) if [ "$DOWNLOAD_JOBS" -le 1 ]; then
            cat wget-list.txt | xargs curl -LJ --remote-name-all || error "download failed"
          else
            (cat wget-list.txt | xargs -n 1 -P "$DOWNLOAD_JOBS" curl -LJO) || error "download failed"
          fi
    ;;
  esac
}

# neptunium base files
extract_neptunium_base() {
  tar zxvf "$NP_BUILDDIR"/download/neptunium-base-files-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/neptunium-base-files-* "$NP_BUILDDIR"/build/neptunium-base-files || error "extraction error"
}

install_neptunium_base() {
  cp -rv "$NP_BUILDDIR"/build/neptunium-base-files/common/*  "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/ || error "installation error"
  cp -rv "$NP_BUILDDIR"/build/neptunium-base-files/"$ARCH"/* "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/ || error "installation error"
}

# busybox-w32 (https://frippery.org/busybox-w32)
extract_busybox_w32() {
  tar zxvf "$NP_BUILDDIR"/download/busybox-w32-FRP-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv "$NP_BUILDDIR"/build/busybox-w32-FRP-* "$NP_BUILDDIR"/build/busybox-w32 || error "extraction error"
}

build_busybox_w32() {
  cd "$NP_BUILDDIR"/build/busybox-w32 || error "directory error"
  case $ARCH in
    amd64|x86) CROSS_COMPILE="${TARGET_HOST}-" make mingw64_defconfig || error "build error";;
    arm64) CROSS_COMPILE="${TARGET_HOST}-" make mingw64a_defconfig || error "build error";;
  esac
  # TODO patch config accordingly to neptunium64_config
  # patch config with sed, w64devkit style
  # do we keep 'man' on windows ? how do we configure it to use '/neptunium*/share/man/...' ?
  sed -ri 's/^(CONFIG_AR)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_DPKG\w*)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_FTP\w*)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_LINK)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_MAN)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_MAKE)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_PDPMAKE)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_RPM\w*)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_STRINGS)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_TEST2)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_TSORT)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_UNLINK)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_VI)=y/\1=n/' .config || error "build error"
  sed -ri 's/^(CONFIG_XXD)=y/\1=n/' .config || error "build error"
  make -j "$BUILD_JOBS" CROSS_COMPILE="${TARGET_HOST}-" || error "build error"
}

install_busybox_w32() {
  # busybox aliases installed from w64devkit busybox-alias.c
  cd "$NP_BUILDDIR"/build/busybox-w32 || error "directory error"
  cp busybox.exe -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || error "installation error"
}

# aria2
extract_aria2() {
  tar -Jxvf "$NP_BUILDDIR"/download/aria2-*.tar.xz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/aria2* "$NP_BUILDDIR"/build/aria2 || error "extraction error"
}

build_aria2() {
  cd "$NP_BUILDDIR"/build/aria2 || error "directory error"
  [ "$(uname -s)" = "Windows_NT" ] && patch-configure
  ./configure --host="$TARGET_HOST" --prefix="$BUILD_PREFIX" \
    --without-included-gettext --disable-nls --without-libcares \
    --without-gnutls --without-openssl --without-sqlite3 \
    --without-libxml2 --without-libexpat --without-libz \
    --without-libgmp --without-libssh2 --without-libgcrypt \
    --without-libnettle ARIA2_STATIC=yes  || error "build error"
  make -j"$BUILD_JOBS" || error "build error"
}

install_aria2() {
  cd "$NP_BUILDDIR"/build/aria2 || error "directory error"
  make install DESTDIR="$NP_BUILDDIR"/install_dir
}

# libgnurx (required for File)
extract_host_libgnurx() {
  # destdir patch from mingw-packages, should it be hardcoded like that ?
  # patch not needed because we install libgnurx manually, but keep it here just in case this changes in the near future
  # https://raw.githubusercontent.com/msys2/MINGW-packages/refs/heads/master/mingw-w64-libgnurx/mingw-w64-libgnurx-honor-destdir.patch
  tar zxvf "$NP_BUILDDIR"/download/mingw-libgnurx-* -C "$NP_BUILDDIR"/build/ || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/mingw-libgnurx-* "$NP_BUILDDIR"/build/libgnurx || error "extraction error"
}

build_libgnurx() {
  cd "$NP_BUILDDIR"/build/libgnurx || error "directory error"
  # if we're on neptunium, fix configure
  [ "$(uname -s)" = "Windows_NT" ] && patch-configure
  ./configure --prefix="$BUILD_PREFIX" --host="$TARGET_HOST" || error "build error"
  make -j"$BUILD_JOBS" || error "build error"
}

install_host_libgnurx() {
  mkdir -pv "$NP_BUILDDIR"/host/lib || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/host/bin || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/host/include || error "installation error"
  cp -v "$NP_BUILDDIR"/build/libgnurx/regex.h "$NP_BUILDDIR"/host/include || error "installation error"
  cp -v "$NP_BUILDDIR"/build/libgnurx/libgnurx-*.dll "$NP_BUILDDIR"/host/bin || error "installation error"
  cp -v "$NP_BUILDDIR"/build/libgnurx/libgnurx.dll.a "$NP_BUILDDIR"/host/lib || error "installation error"
  cp -v "$NP_BUILDDIR"/build/libgnurx/libregex.a "$NP_BUILDDIR"/host/lib || error "installation error"
}

install_libgnurx() {
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin || error "installation error"
  cp -v "$NP_BUILDDIR"/build/libgnurx/regex.h "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include || error "installation error"
  cp -v "$NP_BUILDDIR"/build/libgnurx/libgnurx-*.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin || error "installation error"
  cp -v "$NP_BUILDDIR"/build/libgnurx/libgnurx.dll.a "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib || error "installation error"
  cp -v "$NP_BUILDDIR"/build/libgnurx/libregex.a "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib || error "installation error"
}

# File
extract_file() {
  tar zxvf "$NP_BUILDDIR"/download/file-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/file-* "$NP_BUILDDIR"/build/file || error "extraction error"
}

build_file() {
  cd "$NP_BUILDDIR"/build/file || error "directory error"
  patch -Np0 < "$NP_BUILDDIR"/patches/00-file-cdf_ctime-fix.patch || error "patch error" # fixes build error with mingw64-gcc 14.2.0
  patch -Np0 < "$NP_BUILDDIR"/patches/01-file-fix-cross-compile.patch || error "patch error"
  if [ "$(uname -s)" = "Windows_NT" ]; then
    patch-configure
    _cross_comp_flags=""
  else
    _cross_comp_flags="--build=x86_64-linux"
  fi
  # TODO might affect self-building capabilities ? does file use this besides deciding wether cross-compiling is running or not ?
  CFLAGS="-I${NP_BUILDDIR}/host/include" \
  LDFLAGS="-L${NP_BUILDDIR}/host/lib" \
  ./configure --prefix="$BUILD_PREFIX" \
              --enable-static \
              --enable-shared \
              --libdir="$BUILD_PREFIX"/"$TARGET_HOST"/lib \
              --includedir="$BUILD_PREFIX"/"$TARGET_HOST"/include \
              $_cross_comp_flags \
              --host="$TARGET_HOST" \
              --disable-zlib \
              --disable-bzlib \
              --disable-lzlib \
              --disable-zstdlib \
              --disable-libseccomp || error "build error"
  make -j"$BUILD_JOBS" || error "build error"
}

install_file() {
  cd "$NP_BUILDDIR"/build/file || error "directory error"
  make install DESTDIR="$NP_BUILDDIR"/install_dir || error "installation error"
  # libmagic runtime dll needs to be alongside file.exe
  cp -v "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/bin/libmagic-*.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || error "installation error"
}

# ConEmu
extract_conemu() {
  [ -z "$CONEMU_CUSTOM_PATH" ] && (mv -v "$NP_BUILDDIR"/download/ConEmuPack.*.7z "$NP_BUILDDIR"/download/conemu.7z || error "file operation error")
  mkdir -v "$NP_BUILDDIR"/build/conemu || error "extraction error"
  7z x "$NP_BUILDDIR"/download/conemu.7z -o"$NP_BUILDDIR"/build/conemu/ || error "extraction error"
}

#build_conemu() {
#  cd "$BP_BUILDDIR"/build/conemu/src || error "directory error"
#  CROSS_HOST="${TARGET_HOST}-" make -j12 -f makefile_all_gcc WIDE=y || error "build error"
#}

install_conemu() {
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/conemu || error "installation error"
  cp -rv "$NP_BUILDDIR"/build/conemu/* "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/conemu/ || error "installation error"
}

# LLVM-MinGW (http://github.com/mstorsjo/llvm-mingw)
extract_llvm() {
  cd "$NP_BUILDDIR"/download || error "directory error"  
  if [ "$BUILD_LLVM" = 1 ]; then
    tar zxvf "$NP_BUILDDIR"/download/llvm-mingw-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  else
    unzip -d "$NP_BUILDDIR"/build "$NP_BUILDDIR"/download/llvm-mingw-*.zip || error "extraction error"
  fi
  mv -v "$NP_BUILDDIR"/build/llvm-mingw-* "$NP_BUILDDIR"/build/llvm-mingw || error "file operation error"
}

build_llvm() {
  cd "$NP_BUILDDIR"/build/llvm-mingw || error "directory error"
  # also installs llvm-mingw in the process, which is quite handy
  ./build-all.sh --host="$TARGET_HOST" "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/ || error "build/installation error"
}

install_llvm() {
  cp -rv "$NP_BUILDDIR"/build/llvm-mingw/* "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/ || error "installation error"
}

# Netwide assembler
extract_nasm() {
  tar Jxvf "$NP_BUILDDIR"/download/nasm-*.tar.xz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/nasm-* "$NP_BUILDDIR"/build/nasm || error "file operation error"
}

build_nasm() {
  cd "$NP_BUILDDIR"/build/nasm || error "directory error"
  [ "$(uname -s)" = "Windows_NT" ] && patch-configure
  ./configure --host="$TARGET_HOST" --prefix="$BUILD_PREFIX" || error "build error"
  make -j"$BUILD_JOBS" || error "build error"
}

install_nasm() {
  cd "$NP_BUILDDIR"/build/nasm || error "directory error"
  cp -v nasm.exe ndisasm.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin || error "installation error"
}

# GNU Make
extract_gmake() {
  tar zxvf "$NP_BUILDDIR"/download/make-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/make-* "$NP_BUILDDIR"/build/make || error "file operation error"
}

build_gmake() {
  cd "$NP_BUILDDIR"/build/make || error "directory error"
  [ "$(uname -s)" = "Windows_NT" ] && patch-configure
  ./configure --disable-nls --host="$TARGET_HOST" --prefix="$BUILD_PREFIX" || error "build error"
  make -j"$BUILD_JOBS" || error "build error"
}

install_gmake() {
  cd "$NP_BUILDDIR"/build/make || error "directory error"
  make install DESTDIR="$NP_BUILDDIR"/install_dir || error "installation error"
}

# Vim
extract_vim() {
  tar zxvf "$NP_BUILDDIR"/download/vim-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/vim-* "$NP_BUILDDIR"/build/vim || error "file operation error"
}

build_vim() {
  cd "$NP_BUILDDIR"/build/vim/src || error "directory error"
  vim_common_build_flags="FEATURES=HUGE GUI=yes OLE=yes NETBEANS=no CROSS_COMPILE=${TARGET_HOST}- CROSS=yes HAS_GCC_EH=no VIMDLL=yes WINVER=0x0601 UNDER_CYGWIN=yes"
  if [ "$BUILD_WITH_CLANG" = 1 ]; then
    make -f Make_ming.mak \
    $vim_common_build_flags \
    CC=${TARGET_HOST}-clang \
    CXX=${TARGET_HOST}-clang++ \
    -j"$BUILD_JOBS" || error "build error"
  else # only possibility left is gcc; tcc isn't supported because microsoft went like "muh c++ for muh directx !!!!"
    make -f Make_ming.mak \
    STATIC_STDCPLUS=yes \
    $vim_common_build_flags \
    -j"$BUILD_JOBS" || error "build error"
  fi
}

install_vim() {
  cd "$NP_BUILDDIR"/build/vim/src || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/vim || error "installation error"
  cp -rv ../runtime "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/vim/ || error "installation error"
  cp -v vimrun.exe gvim.exe vim.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/vim/ || error "installation error"
  cp -v xxd/xxd.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || error "installation error"
  # the vi/vim/gvim launchers are already installed by neptunium-base-files
  # ---- install the required dlls
  # TODO vim arm64 support
  [ "$ARCH" = "amd64" ] && cp -v vim64.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/vim/
  [ "$ARCH" = "arm64" ] && cp -v vim64.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/vim/ # arm64 also has vim64.dll
  [ "$ARCH" = "x86" ] && cp -v vim32.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/vim/
  if [ "$BUILD_WITH_CLANG" = 1 ]; then
    llvm_install_dir="$(${TARGET_HOST}-clang -v 2>&1|grep InstalledDir|cut -f2 -d' ')"/..
    # use -n because it might be installed my llvm-mingw, but it's just to be safe
    cp -nv "$llvm_install_dir"/"$TARGET_HOST"/bin/libc++.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
    cp -nv "$llvm_install_dir"/"$TARGET_HOST"/bin/libunwind.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
  else
    gcc_sysroot="$(${TARGET_HOST}-gcc -print-sysroot)"
    cp -v "$gcc_sysroot"/bin/libwinpthread-1.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
    [ "$ARCH" = "amd64" ] && cp -v "$gcc_sysroot"/lib/libgcc_s_seh-1.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
    [ "$ARCH" = "x86" ] && cp -v "$gcc_sysroot"/lib/libgcc_s_sjlj-1.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
    cp -v "$gcc_sysroot"/lib/libstdc++-6.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/
  fi
}

# pkg-config, vc++filt, debugbreak, busybox aliases from w64devkit
extract_w64devkit() {
  tar zxvf "$NP_BUILDDIR"/download/w64devkit-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/w64devkit-* "$NP_BUILDDIR"/build/w64devkit || error "file operation error"
}

build_pkg_config() {
  cd "$NP_BUILDDIR"/build/w64devkit/src || error "directory error"
  ${TARGET_HOST}-gcc -Os -fno-asynchronous-unwind-tables -fno-builtin -Wl,--gc-sections \
        -s -nostdlib -DPKG_CONFIG_PREFIX="\"/$ARCH\"" -o pkg-config.exe pkg-config.c -lkernel32 || error "build error"
}

build_vcppfilt() {
  cd "$NP_BUILDDIR"/build/w64devkit/src || error "directory error"
  ${TARGET_HOST}-gcc -Os -fno-asynchronous-unwind-tables -fno-builtin -Wl,--gc-sections \
        -s -nostdlib -o vc++filt.exe vc++filt.c -lkernel32 -lshell32 -ldbghelp
}

build_debugbreak() {
  cd "$NP_BUILDDIR"/build/w64devkit/src || error "directory error"
  ${TARGET_HOST}-gcc -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
        -o debugbreak.exe debugbreak.c -lkernel32 || error "build error"
}

build_busybox_alias() {
  cd "$NP_BUILDDIR"/build/w64devkit/src || error "directory error"
  "${TARGET_HOST}-gcc" -Os -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -nostdlib \
        -o bbalias.exe busybox-alias.c -lkernel32 || error "build error"
}

install_pkg_config() {
  cp -v "$NP_BUILDDIR"/build/w64devkit/src/pkg-config.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || error "installation error"
}

install_vcppfilt() {
  cp -v "$NP_BUILDDIR"/build/w64devkit/src/vc++filt.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || error "installation error"
}

install_debugbreak() {
  cp -v "$NP_BUILDDIR"/build/w64devkit/src/debugbreak.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || error "installation error"
}

install_busybox_alias() {
  for prog in arch ascii ash awk base32 base64 basename bash bc bunzip2 bzcat bzip2 cal cat cdrop chattr chmod cksum clear cmp comm cp cpio crc32 cut date dc dd df diff dirname dos2unix drop du echo ed egrep env expand expr factor false fgrep find fold free fsync getopt grep groups gunzip gzip hd head hexdump httpd iconv id inotifyd install ipcalc jn kill killall lash less ln logname ls lsattr lzcat lzma lzop lzopcat md5sum mkdir mktemp mv nc nl nproc od paste patch pdrop pgrep pidof pipe_progress pkill printenv printf ps pwd readlink realpath reset rev rm rmdir sed seq sh sha1sum sha256sum sha3sum sha512sum shred shuf sleep sort split ssl_client stat su sum sync tac tar tail tee test time timeout touch tr true truncate ts ttysize uname uncompress unexpand uniq unix2dos unlzma unlzop unxz unzip uptime usleep uudecode uuencode watch wc wget which whoami whois xargs xz xzcat yes zcat; do
    cp -v "$NP_BUILDDIR"/build/w64devkit/src/bbalias.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/"$prog".exe || error "installation error"
  done
}

# PDCurses
extract_pdcurses() {
  tar zxvf "$NP_BUILDDIR"/download/PDCurses-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/PDCurses-* "$NP_BUILDDIR"/build/pdcurses || error "file operation error"
}

build_pdcurses() {
  cd "$NP_BUILDDIR"/build/pdcurses/wincon || error "directory error"
  make CC=${TARGET_HOST}-gcc \
       AR=${TARGET_HOST}-ar \
       STRIP=${TARGET_HOST}-strip \
       WINDRES=${TARGET_HOST}-windres \
       WIDE=Y DLL=Y UTF8=Y -j"$BUILD_JOBS" || error "build error"
}

install_pdcurses() {
  # PDCurses is both a dependency for building vim and a package for the final build, so we install both into the toolchain directory and into the base system

  # cd "$NP_BUILDDIR"/build/pdcurses || exit 1
  # make directories
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/bin || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/host/lib || error "installation error"
  mkdir -pv "$NP_BUILDDIR"/host/include || error "installation error"
  # base system install
  cp -v "$NP_BUILDDIR"/build/pdcurses/curses.h "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/panel.h "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/include || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a   "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib/libpdcurses.a || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a   "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/lib/libcurses.a || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/bin/libpdcurses.dll || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/"$TARGET_HOST"/bin/libcurses.dll || error "installation error"

  # vim dependency (needs to be copied as pdcurses.dll to be used)
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || error "installation error"

  # host toolchain install
  cp -v "$NP_BUILDDIR"/build/pdcurses/curses.h "$NP_BUILDDIR"/host/include/ || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/panel.h "$NP_BUILDDIR"/host/include/ || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a "$NP_BUILDDIR"/host/lib/libpdcurses.a || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/host/lib/libpdcurses.dll || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.a "$NP_BUILDDIR"/host/lib/libcurses.a || error "installation error"
  cp -v "$NP_BUILDDIR"/build/pdcurses/wincon/pdcurses.dll "$NP_BUILDDIR"/host/lib/libcurses.dll || error "installation error"
}

# x64dbg
extract_x64dbg() {
  [ -z "$X64DBG_CUSTOM_PATH" ] && (mv -v "$NP_BUILDDIR"/download/snapshot_*.zip "$NP_BUILDDIR"/download/x64dbg.zip || error "file operation error")
  mkdir -v "$NP_BUILDDIR"/build/x64dbg || error "extraction error"
  unzip "$NP_BUILDDIR"/download/x64dbg.zip -d "$NP_BUILDDIR"/build/x64dbg/ || error "extraction error"
}

install_x64dbg() {
  mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/x64dbg || error "installation error"
  cp -rv "$NP_BUILDDIR"/build/x64dbg/release "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share/x64dbg/ || error "installation error"
}

# Dependency walker (depends.exe)
extract_depends() {
  mkdir -v "$NP_BUILDDIR"/build/depends || error "file operation error"
  unzip "$NP_BUILDDIR"/download/depends*.zip -d "$NP_BUILDDIR"/build/depends/ || error "extraction error"
}

install_depends() {
  cp -v "$NP_BUILDDIR"/build/depends/depends.* "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/ || error "installation error"
}

# 7-Zip
extract_7zip() {
  tar zxvf "$NP_BUILDDIR"/download/7zip-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/7zip-* "$NP_BUILDDIR"/build/7zip || error "file operation error"
}

build_7zip() {
  cd "$NP_BUILDDIR"/build/7zip || error "directory error"

  # if we're not cross compiling
  [ "$(uname -s)" = "Windows_NT" ] || {
    patch -p1 < "$NP_BUILDDIR"/patches/02-7zip_mingw_cross_compilation.patch || error "patching failed"
    _7z_cross_flags="IS_MINGW_CROSS=1"
  }

  cd "$NP_BUILDDIR"/build/7zip/CPP/7zip/Bundles/Alone2 || error "directory error"
  make -f makefile.gcc -j"$BUILD_JOBS" CC=${TARGET_HOST}-gcc CXX=${TARGET_HOST}-g++ RC=${TARGET_HOST}-windres $_7z_cross_flags || error "build error"
}

install_7zip() {
  cp -v "$NP_BUILDDIR"/build/7zip/CPP/7zip/Bundles/Alone2/_o/7zz.exe "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/7z.exe || error "installation error"
}

# Cppcheck
extract_cppcheck() {
  tar zxvf "$NP_BUILDDIR"/download/cppcheck-*.tar.gz -C "$NP_BUILDDIR"/build || error "extraction error"
  mv -v "$NP_BUILDDIR"/build/cppcheck-* "$NP_BUILDDIR"/build/cppcheck || error "file operation error"
}

build_cppcheck() {
  cd "$NP_BUILDDIR"/build/cppcheck || error "directory error"
  make -j"$BUILD_JOBS" CXX="${TARGET_HOST}-g++" RDYNAMIC="" || error "build error"
}

install_cppcheck() {
  # needed because makefile tries to copy cppcheck, assumes no extension
  cp cppcheck.exe cppcheck || erorr "file operation error"
  make CXX=x86_64-w64-mingw32-g++ -j12 RDYNAMIC="" install DESTDIR="$NP_BUILDDIR"/install_dir FILESDIR=/share/cppcheck PREFIX=/"$BUILD_PREFIX"
  mv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/cppcheck "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin/cppcheck.exe
}
