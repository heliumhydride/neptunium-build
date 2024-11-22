#!/bin/sh
# //// This script is fully POSIX sh compatible ////
# made by heliumhydride

ANSI_RED="\033[1;31m"
ANSI_GREEN="\033[1;32m"
ANSI_YELLOW="\033[1;33m"
ANSI_BLUE="\033[1;34m"
ANSI_NORM="\033[0m"

error() {
  printf "${ANSI_RED}error -> %s${ANSI_NORM}\n" "$1" >&2
  [ "$_continue" = 1 ] || {
    info "cleaning up files"
    cleanup_files
    exit 1
  }
  _error_occured=1
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

cleanup_files() {
  rm -fv .npts_*
}

# TODO if --continue is passed, ignore errors
print_usage() {
  echo 'Neptunium test suite by helium hydride'
  echo 'usage: np_test_suite.sh [options]'
  echo 'options:'
  echo '  -c, --continue: continue tests even after one test failed'
}

while :; do
  case "$1" in
    -c|--clean) _continue=1;;
    --) shift; break;;
    '') break;;
    *) print_usage;;
  esac
  shift
done

# TODO test nasm; openssl; make; pkg-config; vc++filt; debugbreak; pdcurses; x64dbg; dependency walker; llvm-strings, llvm-ar, llvm-objcopy, llvm-objdump, lldb?, win64-lld, libc++/libunwind

info "testing nasm ----"
cat >> .npts_tmp.asm << EOF
    global  _main
    extern  _printf

    section .text
_main:
    push    message
    call    _printf
    add     esp, 4
    ret
message:
    db  'Hello, World', 10, 0
EOF
nasm -fwin32 -o .npts_test.o || error "nasm test failed"
cc .npts_test.o -o .npts_test || error "nasm test failed"
./.npts_test || error "nasm test failed"
rm .npts_test .npts_test.o

info "testing curl ----"
curl https://example.com || error "curl test failed"

info "testing clang + lld ----"
# TODO test other tools of llvm
cat >> .npts_tmp.c << EOF
#define _XOPEN_SOURCE   600
#define _POSIX_C_SOURCE 200112L
#include <stdio.h>
int main(void) {
  printf("compiler test\n");
  return 0;
}
EOF

cc .npts_tmp.c -o .npts_tmp || error "c compiler test failed"
./.npts_tmp || error "c compiler test failed"

info "testing vim ----"
vim --version || error "vim test failed"

info "testing libarchive ----"
# TODO test cpio
# TODO test tar with gzip, xz, bzip, ...
echo 'test file contents' > .npts_tmp.txt 
tar cvf .npts_tmp.tar .npts_tmp.txt || error "tar test failed"
rm -v .npts_tmp.txt
tar xvf .npts_tmp.tar || error "tar test failed"
cat .npts_tmp.txt || error "tar test failed"

info "testing file ----"
file $(which cc busybox find vim curl) || error "file test failed"

info "cleaning up temporary files ----"
cleanup_files || warn "clean up error"

if [ "$_error_occured" = 1 ]; then
  warn "test finished with errors ----"
else
  success "test finish with no errors ----"
fi
