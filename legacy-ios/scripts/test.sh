#!/usr/bin/env bash
# Run the ForgeCodeEngine test suite.
#
# WHY THIS EXISTS: the machine currently has only Command Line Tools (no full
# Xcode), and CLT ships a broken SwiftPM — stock `swift build`/`swift test`
# crash at launch (dyld can't resolve SWBBuildService.framework). A machine-local
# shim toolchain at ~/.forge-swiftpm-shim works around it. Once full Xcode is
# installed, stock `swift test` works and this script is no longer needed.
set -euo pipefail
cd "$(dirname "$0")/.."

SHIM="$HOME/.forge-swiftpm-shim/bin/swift-test"
FW=/Library/Developer/CommandLineTools/Library/Developer/Frameworks

if command -v xcrun >/dev/null 2>&1 && xcodebuild -version >/dev/null 2>&1; then
  # Full Xcode present — use stock tooling.
  exec swift test "$@"
elif [ -x "$SHIM" ]; then
  exec "$SHIM" -Xswiftc -F -Xswiftc "$FW" -Xlinker -F -Xlinker "$FW" -Xlinker -rpath -Xlinker "$FW" "$@"
else
  echo "No working Swift test runner found. Install full Xcode, or restore the shim at $SHIM." >&2
  exit 1
fi
