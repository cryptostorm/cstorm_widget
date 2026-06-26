#!/usr/bin/env bash
set -euo pipefail

SRC=/home/bob/openvpn-2.7.4
BUILD="$SRC/build-mingw-ossl4"
OPENSSL_4_ROOT=/home/bob/openssl-4.0.1-win32

# Prefer the dependency tree created by the OpenVPN mingw-x86 preset.
TAP_INCLUDE="$SRC/out/build/mingw/x86/vcpkg_installed/x86-mingw-ovpn/include"

# Fallback to your global vcpkg checkout if needed.
if [ ! -f "$TAP_INCLUDE/tap-windows.h" ]; then
  TAP_INCLUDE="/home/bob/vcpkg/packages/tap-windows6_x86-mingw-ovpn/include"
fi

SSL_DLL_A="$OPENSSL_4_ROOT/lib/libssl.dll.a"
CRYPTO_DLL_A="$OPENSSL_4_ROOT/lib/libcrypto.dll.a"

test -f "$SSL_DLL_A" || { echo "Missing $SSL_DLL_A"; exit 1; }
test -f "$CRYPTO_DLL_A" || { echo "Missing $CRYPTO_DLL_A"; exit 1; }
test -f "$TAP_INCLUDE/tap-windows.h" || { echo "Missing tap-windows.h in $TAP_INCLUDE"; exit 1; }

cd "$SRC"

rm -f config.h
rm -rf "$BUILD"

cmake -S "$SRC" -B "$BUILD" \
  -G "Ninja Multi-Config" \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_C_COMPILER=/usr/bin/i686-w64-mingw32-gcc \
  -DCMAKE_CXX_COMPILER=/usr/bin/i686-w64-mingw32-g++ \
  -DCMAKE_RC_COMPILER=/usr/bin/i686-w64-mingw32-windres \
  -DBUILD_TESTING=OFF \
  -DUSE_WERROR=OFF \
  -DENABLE_LZO=OFF \
  -DENABLE_LZ4=OFF \
  -DENABLE_PKCS11=OFF \
  -DOPENSSL_ROOT_DIR:PATH="$OPENSSL_4_ROOT" \
  -DOPENSSL_INCLUDE_DIR:PATH="$OPENSSL_4_ROOT/include" \
  -DOPENSSL_USE_STATIC_LIBS:BOOL=FALSE \
  -DOPENSSL_SSL_LIBRARY:FILEPATH="$SSL_DLL_A" \
  -DOPENSSL_CRYPTO_LIBRARY:FILEPATH="$CRYPTO_DLL_A" \
  -DOPENSSL_SSL_LIBRARY_RELEASE:FILEPATH="$SSL_DLL_A" \
  -DOPENSSL_CRYPTO_LIBRARY_RELEASE:FILEPATH="$CRYPTO_DLL_A" \
  -DCMAKE_C_FLAGS:STRING="-I$TAP_INCLUDE" \
  -DCMAKE_CXX_FLAGS:STRING="-I$TAP_INCLUDE"

echo
echo "OpenSSL cache entries:"
grep -E 'OPENSSL|OpenSSL' "$BUILD/CMakeCache.txt" || true

echo
echo "TAP include:"
echo "$TAP_INCLUDE"

cmake --build "$BUILD" --config Release --target openvpn -j"$(nproc)"

echo
echo "Built EXEs:"
find "$BUILD" -name 'openvpn.exe' -print

echo
echo "DLL imports:"
i686-w64-mingw32-objdump -p "$BUILD/Release/openvpn.exe" | grep 'DLL Name' || true

cp -vf "$BUILD/Release/openvpn.exe" /home/bob/build/csvpn.exe
