#!/usr/bin/env bash
set -euo pipefail

SRC=/home/bob/openssl-4.0.3
PREFIX=/home/bob/openssl-4.0.3-win32
TARGET=mingw
CROSS=i686-w64-mingw32-

cd "$SRC"

# Clean previous attempts. OpenSSL's distclean may fail if not configured yet.
make distclean 2>/dev/null || true

rm -rf "$PREFIX"
mkdir -p "$PREFIX"

# OpenSSL's official Windows notes say 32-bit MinGW uses the "mingw" target,
# and Linux/Cygwin cross-builds should pass --cross-compile-prefix=i686-w64-mingw32-.
./Configure "$TARGET" \
  --cross-compile-prefix="$CROSS" \
  --prefix="$PREFIX" \
  --openssldir="$PREFIX/ssl" \
  --libdir=lib \
  shared \
  no-tests \
  no-docs

make -j"$(nproc)"
make install_sw

echo
echo "Installed OpenSSL files:"
find "$PREFIX" \
  \( -name 'openssl.exe' \
     -o -name 'libcrypto*.dll' \
     -o -name 'libssl*.dll' \
     -o -name 'libcrypto*.dll.a' \
     -o -name 'libssl*.dll.a' \
     -o -name 'libcrypto.a' \
     -o -name 'libssl.a' \) \
  -print | sort

echo
echo "OpenSSL executable imports:"
i686-w64-mingw32-objdump -p "$PREFIX/bin/openssl.exe" | grep 'DLL Name' || true

cp -vf "$PREFIX/bin/openssl.exe" /home/bob/build/ossl.exe
cp -vf "$PREFIX/bin/libssl-4.dll" /home/bob/build/
cp -vf "$PREFIX/bin/libcrypto-4.dll" /home/bob/build/

