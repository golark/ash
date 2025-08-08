#!/bin/bash
set -e

# Configuration
VERSION="${VERSION:-0.1.0}"
PACKAGE_NAME="ash-${VERSION}"
DIST_DIR="dist-package"

echo "🍺 Creating Homebrew package for Ash v${VERSION}..."

# Verify build artifacts exist
if [[ ! -f "dist/ash-client" ]]; then
    echo "❌ Error: ash-client not found. Please run 'make build' first."
    exit 1
fi

if [[ ! -f "dist/server/ash-server" ]]; then
    echo "❌ Error: ash-server not found. Please run 'make build' first."
    exit 1
fi

# Create distribution directory
rm -rf "$DIST_DIR/$PACKAGE_NAME"
mkdir -p "$DIST_DIR/$PACKAGE_NAME"

echo "📦 Copying files to package..."

# Copy binaries
cp dist/ash-client "$DIST_DIR/$PACKAGE_NAME/"
cp dist/server/ash-server "$DIST_DIR/$PACKAGE_NAME/"

# Copy _internal directory (required for ash-server to run) but exclude the model file
cp -r dist/server/_internal "$DIST_DIR/$PACKAGE_NAME/"
# Remove the model file from the package (it will be downloaded separately)
rm -f "$DIST_DIR/$PACKAGE_NAME/_internal/models/qwen2.5-coder-3b-instruct-q4_k_m.gguf"

# Copy shell integration files
cp ash/ash.zsh "$DIST_DIR/$PACKAGE_NAME/"
cp ash/cli_tools_kb.json "$DIST_DIR/$PACKAGE_NAME/"

# Copy installation files
cp scripts/install.sh "$DIST_DIR/$PACKAGE_NAME/"
cp scripts/uninstall.sh "$DIST_DIR/$PACKAGE_NAME/"

# Copy documentation
cp README.md "$DIST_DIR/$PACKAGE_NAME/"

# Verify all required files are present
echo "🔍 Verifying package contents..."
ls -la "$DIST_DIR/$PACKAGE_NAME/"

# Create Homebrew package
cd "$DIST_DIR"
tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"

# Calculate SHA256 for Homebrew formula
SHA256=$(shasum -a 256 "${PACKAGE_NAME}.tar.gz" | cut -d' ' -f1)

echo "✅ Homebrew package created successfully!"
echo "📦 Package: ${PACKAGE_NAME}.tar.gz"
echo "🔐 SHA256: $SHA256"
echo "📏 Size: $(ls -lh "${PACKAGE_NAME}.tar.gz" | awk '{print $5}')"

# Output SHA256 for GitHub Actions (only if running in CI)
if [[ -n "$GITHUB_ENV" ]]; then
    echo "SHA256=$SHA256" >> $GITHUB_ENV
fi
