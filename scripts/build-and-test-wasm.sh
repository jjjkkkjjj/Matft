#!/bin/bash
set -e

echo "🌐 =========================================="
echo "🌐  Building and Testing Matft for WebAssembly"
echo "🌐 =========================================="
echo ""

# Configuration for CI (GitHub Actions)
SWIFT_WASM_SDK_URL="https://github.com/swiftwasm/swift/releases/download/swift-wasm-6.1-RELEASE/swift-wasm-6.1-RELEASE-wasm32-unknown-wasi.artifactbundle.zip"
SWIFT_WASM_SDK_CHECKSUM="7550b4c77a55f4b637c376f5d192f297fe185607003a6212ad608276928db992"
CI_SDK_NAME="wasm32-unknown-wasi"

# Swift command to use (may be overridden if toolchain detected)
SWIFT_CMD="swift"

# Detect development snapshot toolchain with WASM support
detect_toolchain() {
    echo "🔍 Detecting Swift toolchain..."

    # Check for development snapshot toolchains in the standard location
    TOOLCHAIN_DIR="$HOME/Library/Developer/Toolchains"

    if [ -d "$TOOLCHAIN_DIR" ]; then
        # Find the most recent development snapshot toolchain
        TOOLCHAIN=$(ls -1 "$TOOLCHAIN_DIR" 2>/dev/null | grep -E "swift-DEVELOPMENT-SNAPSHOT.*\.xctoolchain" | sort -r | head -1)

        if [ -n "$TOOLCHAIN" ]; then
            TOOLCHAIN_SWIFT="$TOOLCHAIN_DIR/$TOOLCHAIN/usr/bin/swift"
            if [ -x "$TOOLCHAIN_SWIFT" ]; then
                SWIFT_CMD="$TOOLCHAIN_SWIFT"
                echo "✅ Found development toolchain: $TOOLCHAIN"
                return 0
            fi
        fi
    fi

    echo "ℹ️  Using system Swift"
    return 0
}

# Detect available WASM SDK
detect_wasm_sdk() {
    echo "📦 Detecting WASM SDK..."

    # Get list of installed SDKs
    INSTALLED_SDKS=$($SWIFT_CMD sdk list 2>/dev/null || echo "")

    # First, check if the CI SDK is available (for GitHub Actions)
    if echo "$INSTALLED_SDKS" | grep -q "^${CI_SDK_NAME}$"; then
        SWIFT_SDK_NAME="$CI_SDK_NAME"
        echo "✅ Found SDK: $SWIFT_SDK_NAME"
        return 0
    fi

    # For local development with development toolchains, prefer matching SDKs
    # Extract toolchain version if using a development toolchain
    if echo "$SWIFT_CMD" | grep -q "DEVELOPMENT-SNAPSHOT"; then
        TOOLCHAIN_VERSION=$(echo "$SWIFT_CMD" | grep -oE "DEVELOPMENT-SNAPSHOT-[0-9]{4}-[0-9]{2}-[0-9]{2}-a")
        if [ -n "$TOOLCHAIN_VERSION" ]; then
            SDK_MATCH=$(echo "$INSTALLED_SDKS" | grep "$TOOLCHAIN_VERSION" | grep -v "embedded" | head -1)
            if [ -n "$SDK_MATCH" ]; then
                SWIFT_SDK_NAME="$SDK_MATCH"
                echo "✅ Found matching SDK: $SWIFT_SDK_NAME"
                return 0
            fi
        fi
    fi

    # Try to find any WASM SDK (prefer development snapshots with threads for local dev)
    for pattern in "DEVELOPMENT-SNAPSHOT.*wasm32-unknown-wasip1-threads$" "swift-.*-RELEASE_wasm$" "wasm32-unknown-wasi" "wasm"; do
        SDK_MATCH=$(echo "$INSTALLED_SDKS" | grep -E "$pattern" | grep -v "embedded" | head -1)
        if [ -n "$SDK_MATCH" ]; then
            SWIFT_SDK_NAME="$SDK_MATCH"
            echo "✅ Found SDK: $SWIFT_SDK_NAME"
            return 0
        fi
    done

    return 1
}

# Install Swift WASM SDK if not found
install_swift_wasm_sdk() {
    if detect_wasm_sdk; then
        echo ""
        return 0
    fi

    echo "⬇️  No WASM SDK found. Installing Swift WASM SDK..."
    $SWIFT_CMD sdk install "$SWIFT_WASM_SDK_URL" --checksum "$SWIFT_WASM_SDK_CHECKSUM"
    SWIFT_SDK_NAME="$CI_SDK_NAME"
    echo "✅ Swift WASM SDK installed successfully"
    echo ""
}

# Check if wasmtime is installed
install_wasmtime() {
    echo "🔧 Checking wasmtime..."
    if command -v wasmtime &> /dev/null; then
        echo "✅ wasmtime already installed: $(wasmtime --version)"
        return 0
    fi

    echo "⬇️  Installing wasmtime..."

    # Pinned version to avoid issues with dynamic version fetching
    # The wasmtime.dev/install.sh script can fail when GitHub API rate limits
    # cause the version to be parsed incorrectly (e.g., returning '{' as version)
    WASMTIME_VERSION="29.0.1"

    # Detect platform
    case "$(uname -s)" in
        Linux)
            WASMTIME_ARCH="x86_64-linux"
            ;;
        Darwin)
            if [ "$(uname -m)" = "arm64" ]; then
                WASMTIME_ARCH="aarch64-macos"
            else
                WASMTIME_ARCH="x86_64-macos"
            fi
            ;;
        *)
            echo "❌ Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac

    WASMTIME_URL="https://github.com/bytecodealliance/wasmtime/releases/download/v${WASMTIME_VERSION}/wasmtime-v${WASMTIME_VERSION}-${WASMTIME_ARCH}.tar.xz"
    WASMTIME_DIR="$HOME/.wasmtime"

    echo "   Downloading from: $WASMTIME_URL"
    mkdir -p "$WASMTIME_DIR/bin"
    curl -L "$WASMTIME_URL" | tar -xJ --strip-components=1 -C "$WASMTIME_DIR"
    export PATH="$WASMTIME_DIR/bin:$PATH"

    if command -v wasmtime &> /dev/null; then
        echo "✅ wasmtime installed successfully: $(wasmtime --version)"
    else
        echo "❌ Failed to install wasmtime"
        exit 1
    fi
    echo ""
}

# Build the project
build_project() {
    echo "🔨 Building project for WebAssembly..."
    echo "   Swift: $SWIFT_CMD"
    echo "   SDK: $SWIFT_SDK_NAME"
    $SWIFT_CMD build --swift-sdk "$SWIFT_SDK_NAME"
    echo "✅ Build completed successfully!"
    echo ""
}

# Build and run tests
run_tests() {
    echo "🧪 Building tests for WebAssembly..."
    $SWIFT_CMD build --build-tests --swift-sdk "$SWIFT_SDK_NAME"
    echo "✅ Test build completed!"
    echo ""

    echo "🚀 Running tests with wasmtime..."
    # Note: We use wasmtime instead of 'swift test' because swift test doesn't
    # work directly for WebAssembly targets. For WASM, we must build tests
    # separately and run them with a WASM runtime.
    # See: https://book.swiftwasm.org/getting-started/testing.html

    # Find the test binary in any wasm build directory
    TEST_BINARY=$(find .build -path "*/debug/MatftPackageTests.wasm" -o -path "*/debug/MatftPackageTests.xctest" 2>/dev/null | grep -E "wasm|wasi" | head -1)

    if [ -z "$TEST_BINARY" ]; then
        echo "❌ Error: Could not find test binary"
        echo "   Searched in .build/*/debug/ for MatftPackageTests.wasm or .xctest"
        exit 1
    fi

    echo "📍 Test binary: $TEST_BINARY"

    # Determine wasmtime flags based on SDK type
    # Note: We configure stack and memory limits to prevent crashes:
    # 1. max-wasm-stack (32MB): Maximum stack for wasm execution. Required for
    #    ICU/Foundation date formatting which uses significant stack space.
    # 2. async-stack-size (64MB): Stack for async operations. MUST be larger than
    #    max-wasm-stack. XCTest uses async/await extensively, and swift_task_switch
    #    operations during test execution and teardown require adequate async stack.
    # 3. memory-reservation-for-growth (256MB): Reserve space for memory growth
    #    without committing large amounts upfront. This allows the linear memory
    #    to grow on demand while having space available.
    # 4. memory-guard-size (64KB): Guard pages to catch out-of-bounds access.
    WASMTIME_FLAGS="--dir ."
    WASMTIME_FLAGS="$WASMTIME_FLAGS -W max-wasm-stack=33554432"
    WASMTIME_FLAGS="$WASMTIME_FLAGS -W async-stack-size=67108864"
    WASMTIME_FLAGS="$WASMTIME_FLAGS -O memory-reservation-for-growth=268435456"
    WASMTIME_FLAGS="$WASMTIME_FLAGS -O memory-guard-size=65536"
    if echo "$SWIFT_SDK_NAME" | grep -q "threads"; then
        WASMTIME_FLAGS="$WASMTIME_FLAGS --wasm threads=y --wasi threads=y"
    fi

    echo "🔧 Wasmtime flags: $WASMTIME_FLAGS"
    wasmtime run $WASMTIME_FLAGS "$TEST_BINARY"
    echo ""
}

# Main execution
detect_toolchain
install_swift_wasm_sdk
install_wasmtime
build_project
run_tests

echo "🎉 =========================================="
echo "🎉  All WASM tests passed successfully!"
echo "🎉 =========================================="
