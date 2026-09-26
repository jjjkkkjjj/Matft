#!/bin/sh
# Build and test Extensions/MatftMLX.
#
# MLX needs its Metal shaders (default.metallib) even for CPU-only computation,
# and the SwiftPM CLI (`swift build` / `swift test`) cannot build them. Hence xcodebuild is used.
# Requirements: Apple Silicon Mac, macOS 14+, Xcode with the Metal Toolchain
#   (xcodebuild -downloadComponent MetalToolchain)
#
# Usage:
#   scripts/build-and-test-mlx.sh                                 # all tests
#   scripts/build-and-test-mlx.sh MatftMLXTests.MLXToMatftTests   # a test class (or Class/testMethod)
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$ROOT/Extensions/MatftMLX"

xcodebuild build-for-testing \
    -scheme MatftMLX-Package \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath .build/xcode \
    -skipPackagePluginValidation \
    -quiet

# `xcodebuild test` sometimes fails to load the test bundle ("Failed to create a bundle instance representing ..."),
# so run the bundle with xctest directly
BUNDLE=".build/xcode/Build/Products/Debug/MatftMLXTests.xctest"
if [ $# -gt 0 ]; then
    xcrun xctest -XCTest "$1" "$BUNDLE"
else
    xcrun xctest "$BUNDLE"
fi
