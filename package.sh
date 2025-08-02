#!/bin/bash
set -e

# Configuration
VERSION="0.1.0"
PACKAGE_NAME="ash-cli-${VERSION}"
DIST_DIR="dist-package"

echo "🚀 Packaging ASH CLI v${VERSION}..."

# Clean and build
make clean
make build

# Create distribution directory
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/$PACKAGE_NAME"

# Copy binaries
cp dist/ash-client "$DIST_DIR/$PACKAGE_NAME/"
cp dist/ash-server "$DIST_DIR/$PACKAGE_NAME/"

# Copy shell integration
cp ./ash/ash.zsh "$DIST_DIR/$PACKAGE_NAME/"

# Copy installation script
cp scripts/install.sh "$DIST_DIR/$PACKAGE_NAME/"

# Copy documentation
cp README.md "$DIST_DIR/$PACKAGE_NAME/"

# Copy knowledge base
cp ash/cli_tools_kb.json "$DIST_DIR/$PACKAGE_NAME/"

# Create quick start script
cat > "$DIST_DIR/$PACKAGE_NAME/quick-start.sh" << 'EOF'
#!/bin/bash
echo "🚀 ASH CLI Quick Start"
echo "======================"
echo ""
echo "1. Install ASH:"
echo "   ./install.sh"
echo ""
echo "2. Restart your terminal or run:"
echo "   source ~/.zshrc"
echo ""
echo "3. Enable ASH mode:"
echo "   Press Ctrl+G in your terminal"
echo ""
echo "4. Try it out:"
echo "   Type: 'find all python files' and press Enter"
echo ""
echo "For more information, see README.md"
EOF
chmod +x "$DIST_DIR/$PACKAGE_NAME/quick-start.sh"

# Create archive
cd "$DIST_DIR"
tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME"

echo "✅ Package created:"
echo "   - $DIST_DIR/${PACKAGE_NAME}.tar.gz"
echo "   - $DIST_DIR/${PACKAGE_NAME}.zip"
echo ""
echo "📦 Package contents:"
echo "   - ash-client (Go binary)"
echo "   - ash-server (Python binary with embedded model)"
echo "   - ash.zsh (Shell integration)"
echo "   - install.sh (Installation script)"
echo "   - README.md (Documentation)"
echo "   - quick-start.sh (Quick start guide)" 