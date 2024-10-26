#!/bin/sh

ANSI_RED="\033[1;31m"
ANSI_GREEN="\033[1;32m"
ANSI_YELLOW="\033[1;33m"
ANSI_BLUE="\033[1;34m"
ANSI_NORM="\033[0m"

LOG_FILE="build.log"
DOWNLOAD_AGENT="curl"
BUILD_JOBS="$(nproc)"

NP_BUILDDIR="$(dirname "$0")/"
[ -z "$NP_BUILDDIR" ] && exit 2

. "${NP_BUILDDIR}dl_build_install.sh"

error() {
  printf "${ANSI_RED}error -> %s${ANSI_NORM}\n" "$1"
  exit 1
}

warn() {
  printf "${ANSI_YELLOW}warn -> %s${ANSI_NORM}\n" "$1"
}

info() {
  printf "${ANSI_BLUE}-> %s${ANSI_NORM}\n" "$1"
}

success() {
  printf "${ANSI_GREEN}-> %s${ANSI_NORM}\n" "$1"
}

check_installed() {
  which $1 > /dev/null 2>&1
  [ "$?" -eq 1 ] && error "$1 command not installed / not found in \$PATH"
}

print_usage() {
  echo "Neptunium Build Script by heliumhydride"
  echo "usage: build.sh [OPTIONS]"
  echo "options:"
  echo "  -a, --arch [neptunium_arch]: architecture to build, amd64, x86, or arm64"
  echo "  -j, --jobs [num. of jobs]:   use make with n jobs (default: number of logical cpus)"
  echo "  -h, --help: shows this help"
  echo "  -c, --clean: cleanup downloads, build files and output zips"
  echo "  -v, --verbose: output commands to stdout, not log file (overrides -o)"
  echo "  -o, --output-log [LOG_FILE]: output to log"
  echo "  --x64dbg [custom_zip]: Use a custom-built version of x64dbg (must be same directory structure as in the snapshots of x64dbg)"
  echo "  --conemu [custom_7z]: Use a custom-built version of conemu (must be same directory structure as in the ConEmuPack.*.7z)"
  echo "  --no-prebuilt-llvm: Build llvm-mingw instead of pulling a binary (VERY LONG!)"
  echo "  --free: use FOSS tools only (no dependency walker)"
  echo "  --dl-agent [program]: use [program] to download files, default is curl (supported: curl,wget)"
  echo ""
  echo "you can edit ${NP_BUILDDIR}dl_build_install.sh to change URLs of downloads, build flags, etc..."
  echo "NOTE: arm64 building is UNTESTED"
  exit 1
}


[ -z "$*" ] && print_usage
while :; do
  case "$1" in
    -a|--arch) shift; ARCH=$1;;
    -j|--jobs) shift; BUILD_JOBS=$1;;
    --no-prebuilt-llvm) BUILD_LLVM=1;;
    --x64dbg) shift; X64DBG_CUSTOM_PATH=$1;;
    --conemu) shift; CONEMU_CUSTOM_PATH=$1;;
    --dl-agent) shift; DOWNLOAD_AGENT="$1";;
    --free) FREE_SOFTWARE_ONLY=1;;
    -o|--output-log) shift; LOG_FILE="$1";;
    -v|--verbose) LOG_FILE='';;
    -c|--clean) _clean_mode=1;;
    --) shift; break;;
    '') break;;
    *) print_usage;;
  esac
  shift
done

if [ "$_clean_mode" = 1 ]; then
  info "cleaning all inside build directory and downloads"
  clean_fail=0
  rm -rv "${NP_BUILDDIR}build"/* || warn "something wrong happened while cleaning build files"; _clean_fail=1
  rm -rv "${NP_BUILDDIR}download"/* || warn "something wrong happened while cleaning downloads"; _clean_fail=1
  rm -rv "${NP_BUILDDIR}output"/* || warn "something wrong happened while cleaning output zips" _clean_fail=1
  exit "$clean_fail"
fi

check_installed "$DOWNLOAD_AGENT"
check_installed tar
check_installed gzip
check_installed xz
check_installed unzip
check_installed 7z

case "$ARCH" in
  amd64) TARGET_HOST="x86_64-w64-mingw32"
         BUILD_PREFIX="/neptunium64";;
  x86)   TARGET_HOST="i686-w64-mingw32"
         BUILD_PREFIX="/neptunium32";;
  arm64) TARGET_HOST="aarch64-w64-mingw32"
         BUILD_PREFIX="/neptuniumarm64";;
esac

check_installed "$TARGET_HOST"-gcc
check_installed "$TARGET_HOST"-g++

case "$ARCH" in
  amd64|x86|arm64);;
  *) error "unsupported architecture $ARCH";;
esac

case "$DOWNLOAD_AGENT" in
  curl) _dl_cmd="curl -LJO";;
  wget) _dl_cmd="wget";;
  *) error "unsupported download agent $DOWNLOAD_AGENT";;
esac

echo
echo "${ANSI_BLUE}arch:                   ${ANSI_GREEN}${ARCH}${ANSI_NORM}"
echo "${ANSI_BLUE}download agent:         ${ANSI_GREEN}${DOWNLOAD_AGENT}${ANSI_NORM}"

if [ "$BUILD_LLVM" = 1 ]; then echo "${ANSI_BLUE}build llvm-mingw:       ${ANSI_GREEN}yes${ANSI_NORM}"
else echo "${ANSI_BLUE}build llvm-mingw:       ${ANSI_RED}no${ANSI_NORM}"
fi

if [ "$FREE_SOFTWARE_ONLY" = 1 ]; then echo "${ANSI_BLUE}free software only:     ${ANSI_GREEN}yes${ANSI_NORM}"
else echo "${ANSI_BLUE}free software only:     ${ANSI_RED}no${ANSI_NORM}"
fi

[ -n "$X64DBG_CUSTOM_PATH" ] && echo "${ANSI_BLUE}x64dbg custom zip path: ${ANSI_GREEN}${X64DBG_CUSTOM_PATH}${ANSI_NORM}"
[ -n "$CONEMU_CUSTOM_PATH" ] && echo "${ANSI_BLUE}conemu custom zip path: ${ANSI_GREEN}${CONEMU_CUSTOM_PATH}${ANSI_NORM}"

echo "Proceed with these parameters ? (Y/n)"
read -r _proceed
case "$_proceed" in [nN]) exit 0;; esac


info "ok, downloading needed files"

# ---DOWNLOADING---
# base system tools
info "downloading busybox-w32"
download_busybox_w32
info "downloading libarchive"
download_libarchive
info "downloading curl"
download_curl
info "downloading file"
download_file
info "downloading conemu"
download_conemu
# development tools
info "downloading llvm-mingw"
download_llvm
info "downloading nasm"
download_nasm
info "downloading gmake"
download_gmake
info "downloading vim"
download_vim
info "downloading w64devkit (pkg-config, vc++filt, debugbreak)"
download_w64devkit
info "downloading libressl"
download_libressl
info "downloading/copying x64dbg"
download_x64dbg
[ "$FREE_SOFTWARE_ONLY" = 1 ] || {
  info "downloading dependency walker"
  download_depends
}
# additional libs
info "downloading pdcurses"
download_pdcurses
info "downloading host-libgnurx"
download_host_libgnurx

info "creating base directory structure"
# create base directory structure
mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/bin
mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/etc
mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/home
mkdir -pv "$NP_BUILDDIR"/install_dir/"$BUILD_PREFIX"/share

# --- COMPILING HOST LIBS ---
info "building pdcurses"
build_pdcurses
info "installing pdcurses"
install_pdcurses
info "building host-libressl"
build_host_libressl
info "installing host-libressl"
install_host_libressl
info "building libgnurx"
build_libgnurx
info "installing host-libgnurx"
install_host_libgnurx

# --- COMPILING NEPTUNUM DISTRIBUTION ---
info "building busybox-w32"
build_busybox_w32
info "building libarchive"
build_libarchive
info "building libressl"
build_libressl
info "building curl"
build_curl
info "building file"
build_file
#info "building conemu"
#build_conemu
info "building nasm"
build_nasm
info "building gmake"
build_gmake
info "building vim"
build_vim
info "building pkg-config from w64devkit"
build_pkg_config
info "building vc++filt from w64devkit"
build_vcppfilt
info "building debugbreak from w64devkit"
build_debugbreak
info "building busybox alias from w64devkit"
build_busybox_alias
#info "building x64dbg"
#build_x64dbg
[ "$BUILD_LLVM" = 1 ] && {
  info "building llvm-mingw (takes a long time)"
  build_llvm
}

# --- INSTALLING ---
info "installing busybox-w32"
install_busybox_w32
info "installing libarchive"
install_libarchive
info "installing libressl"
install_libressl
info "installing curl"
install_curl
info "installing libgnurx"
install_libgnurx
info "installing file"
install_file
info "installing conemu"
install_conemu
[ "$BUILD_LLVM" = 1 ] || {
  info "installing llvm-mingw"
  install_llvm
}
info "installing nasm"
install_nasm
info "installing gmake"
install_gmake
info "installing vim"
install_vim
info "installing pkg-config from w64devkit"
install_pkg_config
info "installing vc++filt from w64devkit"
install_vcppfilt
info "installing debugbreak from w64devkit"
install_debugbreak
info "installing aliases to busybox"
install_busybox_alias
info "installing x64dbg"
install_x64dbg
[ "$FREE_SOFTWARE_ONLY" = 1 ] || {
  info "installing dependency walker"
  install_depends
}

info "creating distribution zip"
ZIPNAME="neptunium-$ARCH-$(date +%Y.%m.%d).7z"

7z a -mx7 -r "$NP_BUILDDIR"/output/"$ZIPNAME" "$NP_BUILDDIR"/install_dir/* || error "creating distribution zip failed"
success "enjoy your new neptunium $ARCH build at $NP_BUILDDIR/output/$ZIPNAME !"
