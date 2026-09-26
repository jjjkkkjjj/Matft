#!/usr/bin/env bash
# Builds the Swift-DocC API reference of Matft into website/static/api,
# so that the Docusaurus site serves it at /Matft/api/documentation/matft/.
#
# Usage:
#   ./scripts/build-docs.sh                # build the API reference
#   ./scripts/build-docs.sh --preview      # preview it with `docc preview` (http://localhost:8080)
#   DOCC_WARNINGS_AS_ERRORS=1 ./scripts/build-docs.sh
#
# swift-docc-plugin is not used so that Matft does not add a dependency to its users.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYMBOL_DIR="$ROOT/.build/docc/symbol-graphs"
MATFT_SYMBOL_DIR="$ROOT/.build/docc/matft-symbol-graphs"
CATALOG="$ROOT/Sources/Matft/Matft.docc"
OUTPUT="$ROOT/website/static/api"
HOSTING_BASE_PATH="${HOSTING_BASE_PATH:-Matft/api}"

SCRATCH="$ROOT/.build/docc/build"

emit_symbol_graphs() {
    swift build --target Matft --scratch-path "$SCRATCH" \
        -Xswiftc -emit-symbol-graph \
        -Xswiftc -emit-symbol-graph-dir -Xswiftc "$SYMBOL_DIR" \
        -Xswiftc -symbol-graph-minimum-access-level -Xswiftc public
}

echo "==> Emitting symbol graphs"
mkdir -p "$SYMBOL_DIR"
emit_symbol_graphs
# An up-to-date incremental build does not emit the symbol graphs again, so rebuild if they are missing.
if [[ ! -f "$SYMBOL_DIR/Matft.symbols.json" ]]; then
    rm -rf "$SCRATCH"
    emit_symbol_graphs
fi
rm -rf "$MATFT_SYMBOL_DIR"
mkdir -p "$MATFT_SYMBOL_DIR"

# Only Matft's symbols (and its extensions to Swift / Accelerate / CoreML), not its dependencies'.
cp "$SYMBOL_DIR"/Matft.symbols.json "$SYMBOL_DIR"/Matft@*.symbols.json "$MATFT_SYMBOL_DIR"/

DOCC="$(xcrun --find docc 2>/dev/null || command -v docc)"
DOCC_ARGS=(
    "$CATALOG"
    --additional-symbol-graph-dir "$MATFT_SYMBOL_DIR"
    --fallback-display-name Matft
    --fallback-bundle-identifier com.github.jjjkkkjjj.Matft
)
if [[ "${DOCC_WARNINGS_AS_ERRORS:-0}" == "1" ]]; then
    DOCC_ARGS+=(--warnings-as-errors)
fi

if [[ "${1:-}" == "--preview" ]]; then
    exec "$DOCC" preview "${DOCC_ARGS[@]}"
fi

echo "==> Converting with DocC"
rm -rf "$OUTPUT"
"$DOCC" convert "${DOCC_ARGS[@]}" \
    --transform-for-static-hosting \
    --hosting-base-path "$HOSTING_BASE_PATH" \
    --output-path "$OUTPUT"

echo "==> API reference: $OUTPUT (served at /$HOSTING_BASE_PATH/documentation/matft/)"
