#!/usr/bin/env bash
set -euo pipefail

SRC=/home/bob/stunnel-5.82
SSL=/home/bob/openssl-4.0.3-win32
STAGE=/home/bob/stunnel-5.82-win32-msvcrt-openssl403-test

cd "$SRC"

echo "Checking compiler CRT..."
cat > /tmp/hello-mingw.c <<'EOC'
int main(void) { return 0; }
EOC

i686-w64-mingw32-gcc /tmp/hello-mingw.c -o /tmp/hello-mingw.exe
i686-w64-mingw32-objdump -p /tmp/hello-mingw.exe | grep 'DLL Name'

if i686-w64-mingw32-objdump -p /tmp/hello-mingw.exe | grep -q 'api-ms-win-crt'; then
  echo "ERROR: i686-w64-mingw32-gcc is still producing UCRT binaries"
  exit 1
fi

echo
echo "Checking OpenSSL tree:"
test -d "$SSL" || { echo "ERROR: missing SSL prefix: $SSL"; exit 1; }
test -d "$SSL/include/openssl" || { echo "ERROR: missing OpenSSL headers: $SSL/include/openssl"; exit 1; }
test -d "$SSL/lib" || { echo "ERROR: missing OpenSSL libs: $SSL/lib"; exit 1; }
test -d "$SSL/bin" || { echo "ERROR: missing OpenSSL DLL dir: $SSL/bin"; exit 1; }

ls -l "$SSL/bin"/libcrypto-*.dll "$SSL/bin"/libssl-*.dll
ls -l "$SSL/lib"/libcrypto.dll.a "$SSL/lib"/libssl.dll.a 2>/dev/null || true

echo
echo "OpenSSL DLL imports:"
for f in "$SSL/bin"/libcrypto-*.dll "$SSL/bin"/libssl-*.dll; do
  echo
  echo "== $f =="
  file "$f"
  i686-w64-mingw32-objdump -p "$f" | grep 'DLL Name' || true
done

make distclean 2>/dev/null || true
rm -rf "$SRC/bin/win32" "$SRC/obj/win32" "$STAGE"

./configure

make -C src mingw \
  win32_ssl_dir="$SSL" \
  win32_cflags="-g -mthreads -O2 -Wall -Wextra -Wpedantic -Wconversion -std=c99 -DUNICODE -D_UNICODE -U_FORTIFY_SOURCE -fno-stack-protector" \
  win32_common_libs="-lws2_32 -lkernel32"

mkdir -p "$STAGE"

cp "$SRC/bin/win32/stunnel.exe" "$STAGE/"
cp "$SRC/bin/win32/tstunnel.exe" "$STAGE/"

# OpenSSL 4 uses libcrypto-4.dll/libssl-4.dll, but glob this so it also works
# if the DLL naming differs in your local build.
cp "$SSL/bin"/libcrypto-*.dll "$STAGE/"
cp "$SSL/bin"/libssl-*.dll "$STAGE/"

# Copy common compression/runtime DLLs if your OpenSSL build produced them.
for dll in zlib1.dll zstd.dll libzstd.dll libgcc_s_sjlj-1.dll libgcc_s_dw2-1.dll libwinpthread-1.dll; do
  if [ -f "$SSL/bin/$dll" ]; then
    cp "$SSL/bin/$dll" "$STAGE/"
  fi
done

if [ -d "$SSL/lib/ossl-modules" ]; then
  mkdir -p "$STAGE/ossl-modules"
  cp -a "$SSL/lib/ossl-modules/"* "$STAGE/ossl-modules/" 2>/dev/null || true
fi

echo
echo "Imports:"
BAD=0
while IFS= read -r -d '' f; do
  echo
  echo "== $f =="
  file "$f"
  i686-w64-mingw32-objdump -p "$f" | grep 'DLL Name' || true

  if file "$f" | grep -q 'PE32+'; then
    echo "ERROR: 64-bit PE32+ file staged: $f"
    BAD=1
  fi

  if i686-w64-mingw32-objdump -p "$f" | grep -q 'api-ms-win-crt'; then
    echo "ERROR: UCRT dependency staged: $f"
    BAD=1
  fi

  if i686-w64-mingw32-objdump -p "$f" | grep -q 'libssp-0.dll'; then
    echo "ERROR: libssp dependency staged: $f"
    BAD=1
  fi
done < <(find "$STAGE" -type f \( -name '*.exe' -o -name '*.dll' \) -print0)

if [ "$BAD" -ne 0 ]; then
  echo
  echo "Build staged bad runtime dependencies."
  exit 1
fi

echo
echo "Good stage dir:"
echo "$STAGE"

cp -vf "$STAGE"/tstunnel.exe /home/bob/build/cs-https-tun.exe