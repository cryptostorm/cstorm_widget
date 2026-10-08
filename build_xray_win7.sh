#!/usr/bin/env bash
set -euo pipefail

SRC=/home/bob/Xray-core
OUT=/home/bob/xray-win7-build
GOZIP=/home/bob/go-for-win7-linux-amd64.zip
GOROOT_WIN7=/home/bob/go-win7

mkdir -p "$OUT"
cd "$SRC"

# Download the patched Win7-capable Go toolchain used by Xray's own workflow.
if [ ! -f "$GOZIP" ]; then
  curl -L \
    -o "$GOZIP" \
    https://github.com/XTLS/go-win7/releases/latest/download/go-for-win7-linux-amd64.zip
fi

rm -rf "$GOROOT_WIN7"
mkdir -p "$GOROOT_WIN7"
unzip -q "$GOZIP" -d "$GOROOT_WIN7"

export GOROOT="$GOROOT_WIN7"
export PATH="$GOROOT/bin:$PATH"
export CGO_ENABLED=0
export GOOS=windows

echo "Using Go:"
go version
go env GOROOT GOOS GOARCH CGO_ENABLED

COMMID="$(git describe --always --dirty 2>/dev/null || echo custom)"

echo
echo "Building Win7 32-bit..."
GOARCH=386 go build \
  -o "$OUT/xray-win7-32.exe" \
  -trimpath \
  -buildvcs=false \
  -gcflags="all=-l=4" \
  -ldflags="-X github.com/xtls/xray-core/core.build=${COMMID} -s -w -buildid=" \
  -v ./main

echo
echo "Building Win7 64-bit..."
GOARCH=amd64 go build \
  -o "$OUT/xray-win7-64.exe" \
  -trimpath \
  -buildvcs=false \
  -gcflags="all=-l=4" \
  -ldflags="-X github.com/xtls/xray-core/core.build=${COMMID} -s -w -buildid=" \
  -v ./main

echo
echo "Outputs:"
file "$OUT"/xray-win7-*.exe
cp -vf "$OUT"/xray-win7-32.exe /home/bob/build/xray.exe