#!/bin/bash
set -e

echo "🌐 =========================================="
echo "🌐  Building and Testing Matft for WebAssembly"
echo "🌐 =========================================="
echo ""

# SDK info for different Swift versions (SDK must match Swift compiler version)
get_sdk_info() {
    local SWIFT_VER="$1"
    case "$SWIFT_VER" in
        6.0.3*)
            SDK_VERSION="6.0.3-RELEASE"
            SDK_CHECKSUM="31d3585b06dd92de390bacc18527801480163188cd7473f492956b5e213a8618"
            ;;
        6.1*)
            SDK_VERSION="6.1-RELEASE"
            SDK_CHECKSUM="7550b4c77a55f4b637c376f5d192f297fe185607003a6212ad608276928db992"
            ;;
        *)
            echo "❌ No WASM SDK available for Swift $SWIFT_VER"
            echo "   Supported versions: 6.0.3, 6.1"
            return 1
            ;;
    esac
    SDK_URL="https://github.com/swiftwasm/swift/releases/download/swift-wasm-${SDK_VERSION}/swift-wasm-${SDK_VERSION}-wasm32-unknown-wasi.artifactbundle.zip"
    return 0
}

SWIFT_CMD=""
SWIFT_SDK_NAME=""
SWIFT_VERSION=""

# Setup Swift command and detect version
setup_swift() {
    echo "📦 Setting up Swift..."

    # Check for local SwiftWasm toolchain first (macOS development with newer SDK)
    TOOLCHAIN_DIR="$HOME/Library/Developer/Toolchains"
    if [ -d "$TOOLCHAIN_DIR" ]; then
        # Look for development snapshot toolchain (needed for newer macOS SDKs)
        local WASM_TOOLCHAIN=$(ls -1 "$TOOLCHAIN_DIR" 2>/dev/null | grep -E "swift-DEVELOPMENT-SNAPSHOT.*\.xctoolchain" | sort -r | head -1)

        if [ -n "$WASM_TOOLCHAIN" ]; then
            local TOOLCHAIN_SWIFT="$TOOLCHAIN_DIR/$WASM_TOOLCHAIN/usr/bin/swift"
            if [ -x "$TOOLCHAIN_SWIFT" ]; then
                SWIFT_CMD="$TOOLCHAIN_SWIFT"
                echo "✅ Using local development toolchain: $WASM_TOOLCHAIN"
                local VERSION_OUTPUT=$($SWIFT_CMD --version 2>/dev/null | head -1)
                echo "   Version: $VERSION_OUTPUT"
                # Dev toolchain - will use dev SDK
                SWIFT_VERSION="dev"
                echo ""
                return 0
            fi
        fi
    fi

    # Use system Swift (CI environment)
    if command -v swift &> /dev/null; then
        SWIFT_CMD="swift"
        local VERSION_OUTPUT=$($SWIFT_CMD --version 2>/dev/null)
        # Extract version number (e.g., "6.1.3" from "Swift version 6.1.3")
        SWIFT_VERSION=$(echo "$VERSION_OUTPUT" | grep -oE "Swift version [0-9]+\.[0-9]+(\.[0-9]+)?" | head -1 | sed 's/Swift version //')
        echo "✅ Using system Swift"
        echo "   Version: $SWIFT_VERSION"
        echo ""
        return 0
    fi

    echo "❌ No Swift installation found"
    exit 1
}

# Find or install the WASM SDK
setup_wasm_sdk() {
    echo "📦 Setting up WASM SDK..."

    local INSTALLED_SDKS=$($SWIFT_CMD sdk list 2>/dev/null || echo "")

    # For development toolchain, try to find matching development SDK first
    if [ "$SWIFT_VERSION" = "dev" ]; then
        local TOOLCHAIN_DATE=$(echo "$SWIFT_CMD" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}")
        if [ -n "$TOOLCHAIN_DATE" ]; then
            SWIFT_SDK_NAME=$(echo "$INSTALLED_SDKS" | grep "DEVELOPMENT-SNAPSHOT-${TOOLCHAIN_DATE}" | grep -E "wasm32-unknown-wasi" | grep -v "embedded" | head -1)
            if [ -n "$SWIFT_SDK_NAME" ]; then
                echo "✅ Found matching development SDK: $SWIFT_SDK_NAME"
                echo ""
                return 0
            fi
        fi

        # Fallback to any development snapshot SDK
        SWIFT_SDK_NAME=$(echo "$INSTALLED_SDKS" | grep "DEVELOPMENT-SNAPSHOT" | grep "wasm32-unknown-wasip1-threads$" | grep -v "embedded" | sort -r | head -1)
        if [ -n "$SWIFT_SDK_NAME" ]; then
            echo "✅ Found development SDK: $SWIFT_SDK_NAME"
            echo ""
            return 0
        fi

        echo "❌ No development SDK found for development toolchain"
        exit 1
    fi

    # Get SDK info for the detected Swift version
    if ! get_sdk_info "$SWIFT_VERSION"; then
        exit 1
    fi

    echo "   Swift version: $SWIFT_VERSION"
    echo "   Required SDK: $SDK_VERSION"

    # Check if SDK is already installed
    if echo "$INSTALLED_SDKS" | grep -qE "(^|swift-wasm-)${SDK_VERSION}[_-]wasm32-unknown-wasi"; then
        SWIFT_SDK_NAME=$(echo "$INSTALLED_SDKS" | grep -E "(^|swift-wasm-)${SDK_VERSION}[_-]wasm32-unknown-wasi" | head -1)
        echo "✅ Found SDK: $SWIFT_SDK_NAME"
        echo ""
        return 0
    fi

    # Install the SDK
    echo "⬇️  Installing WASM SDK ${SDK_VERSION}..."
    $SWIFT_CMD sdk install "$SDK_URL" --checksum "$SDK_CHECKSUM"

    # Verify installation
    INSTALLED_SDKS=$($SWIFT_CMD sdk list 2>/dev/null || echo "")
    SWIFT_SDK_NAME=$(echo "$INSTALLED_SDKS" | grep -E "(^|swift-wasm-)${SDK_VERSION}[_-]wasm32-unknown-wasi" | head -1)

    if [ -z "$SWIFT_SDK_NAME" ]; then
        echo "❌ Failed to install SDK"
        exit 1
    fi

    echo "✅ SDK installed: $SWIFT_SDK_NAME"
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
    WASMTIME_VERSION="40.0.2"

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
    # 5. shared-memory (when threads enabled): Required for threads proposal - enables
    #    shared linear memory between threads.
    WASMTIME_FLAGS="--dir ."
    WASMTIME_FLAGS="$WASMTIME_FLAGS -W max-wasm-stack=33554432"
    WASMTIME_FLAGS="$WASMTIME_FLAGS -W async-stack-size=67108864"
    WASMTIME_FLAGS="$WASMTIME_FLAGS -O memory-reservation-for-growth=268435456"
    WASMTIME_FLAGS="$WASMTIME_FLAGS -O memory-guard-size=65536"
    if echo "$SWIFT_SDK_NAME" | grep -q "threads"; then
        WASMTIME_FLAGS="$WASMTIME_FLAGS --wasm threads=y --wasm shared-memory=y --wasi threads=y"
    fi

    echo "🔧 Wasmtime flags: $WASMTIME_FLAGS"
    wasmtime run $WASMTIME_FLAGS "$TEST_BINARY"
    echo ""
}

# Main execution
setup_swift
setup_wasm_sdk
install_wasmtime
build_project
run_tests

echo "🎉 =========================================="
echo "🎉  All WASM tests passed successfully!"
echo "🎉 =========================================="
