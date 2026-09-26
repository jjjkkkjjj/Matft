#!/bin/sh
# Build and run Extensions/MatftMLX/Examples/MatftMLXDemo.
# See scripts/build-and-test-mlx.sh for the requirements.
#
# Usage:
#   scripts/run-mlx-demo.sh                          # all demos with a synthetic image
#   scripts/run-mlx-demo.sh clip path/to/image.png   # whisper | clip | qwen2vl | all
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
DEMO="${1:-all}"
# The image path is relative to the caller's directory
IMAGE=""
if [ $# -ge 2 ]; then
    IMAGE="$(cd "$(dirname "$2")" && pwd -P)/$(basename "$2")"
fi
cd "$ROOT/Extensions/MatftMLX"

xcodebuild build \
    -scheme MatftMLXDemo \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath .build/xcode \
    -skipPackagePluginValidation \
    -quiet

if [ -n "$IMAGE" ]; then
    exec .build/xcode/Build/Products/Debug/MatftMLXDemo "$DEMO" "$IMAGE"
fi
exec .build/xcode/Build/Products/Debug/MatftMLXDemo "$DEMO"
