#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    print_error "Unsupported operating system: $OSTYPE"
    exit 1
fi

print_status "Installing Ash on $OS..."

# Create installation directory
INSTALL_DIR="$HOME/.ash"
print_status "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Copy binaries
print_status "Installing binaries..."
if [[ -f "dist/ash-client" ]]; then
    cp dist/ash-client "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/ash-client"
    print_success "Installed ash-client"
else
    print_error "ash-client binary not found. Please run 'make build' first."
    exit 1
fi

if [[ -f "dist/ash-server" ]]; then
    cp dist/ash-server "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/ash-server"
    print_success "Installed ash-server"
else
    print_error "ash-server binary not found. Please run 'make build' first."
    exit 1
fi

# Copy shell integration
print_status "Installing shell integration..."
if [[ -f "ash/ash.zsh" ]]; then
    cp ash/ash.zsh "$INSTALL_DIR/"
    print_success "Installed ash.zsh"
else
    print_error "ash.zsh not found."
    exit 1
fi

# Copy model if it exists
if [[ -f "models/qwen2.5-coder-3b-instruct-q4_k_m.gguf" ]]; then
    print_status "Copying model files..."
    cp models/qwen2.5-coder-3b-instruct-q4_k_m.gguf "$INSTALL_DIR/"
    print_success "Model files copied"
else
    print_warning "Model files not found. They will be downloaded on first run."
fi

# Create symlinks in /usr/local/bin (requires sudo on macOS)
print_status "Creating symlinks..."
if [[ "$OS" == "macos" ]]; then
    if [[ -w "/usr/local/bin" ]]; then
        ln -sf "$INSTALL_DIR/ash-client" /usr/local/bin/ash-client
        ln -sf "$INSTALL_DIR/ash-server" /usr/local/bin/ash-server
        print_success "Created symlinks in /usr/local/bin"
    else
        print_warning "Cannot write to /usr/local/bin. You may need to run with sudo or add to PATH manually."
        print_status "Add the following to your ~/.zshrc:"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
else
    # Linux - try /usr/local/bin first, then ~/.local/bin
    if [[ -w "/usr/local/bin" ]]; then
        ln -sf "$INSTALL_DIR/ash-client" /usr/local/bin/ash-client
        ln -sf "$INSTALL_DIR/ash-server" /usr/local/bin/ash-server
        print_success "Created symlinks in /usr/local/bin"
    elif [[ -w "$HOME/.local/bin" ]]; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$INSTALL_DIR/ash-client" "$HOME/.local/bin/ash-client"
        ln -sf "$INSTALL_DIR/ash-server" "$HOME/.local/bin/ash-server"
        print_success "Created symlinks in ~/.local/bin"
        print_status "Add the following to your ~/.zshrc if not already present:"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    else
        print_warning "Cannot create symlinks. Add the following to your ~/.zshrc:"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
fi

# Setup shell integration
print_status "Setting up shell integration..."

# Check if zsh is the current shell
if [[ "$SHELL" != *"zsh" ]]; then
    print_warning "You're not using zsh. Ash is designed for zsh. Consider switching to zsh."
fi

# Add to .zshrc if not already present
ZSHRC="$HOME/.zshrc"
if [[ ! -f "$ZSHRC" ]]; then
    touch "$ZSHRC"
    print_status "Created ~/.zshrc"
fi

# Check if ash is already sourced
if grep -q "source.*ash.zsh" "$ZSHRC"; then
    print_warning "Ash shell integration already configured in ~/.zshrc"
else
    echo "" >> "$ZSHRC"
    echo "# Ash shell integration" >> "$ZSHRC"
    echo "source $INSTALL_DIR/ash.zsh" >> "$ZSHRC"
    print_success "Added Ash shell integration to ~/.zshrc"
fi

# Create uninstall script
print_status "Creating uninstall script..."
cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

echo "🗑️  Uninstalling Ash..."

# Remove from .zshrc
if [[ -f "$HOME/.zshrc" ]]; then
    sed -i.bak '/# Ash shell integration/,+1d' "$HOME/.zshrc"
    echo "✅ Removed Ash from ~/.zshrc"
fi

# Remove symlinks
if [[ -L "/usr/local/bin/ash-client" ]]; then
    rm /usr/local/bin/ash-client
    echo "✅ Removed ash-client symlink"
fi

if [[ -L "/usr/local/bin/ash-server" ]]; then
    rm /usr/local/bin/ash-server
    echo "✅ Removed ash-server symlink"
fi

if [[ -L "$HOME/.local/bin/ash-client" ]]; then
    rm "$HOME/.local/bin/ash-client"
    echo "✅ Removed ash-client symlink"
fi

if [[ -L "$HOME/.local/bin/ash-server" ]]; then
    rm "$HOME/.local/bin/ash-server"
    echo "✅ Removed ash-server symlink"
fi

# Remove installation directory
if [[ -d "$HOME/.ash" ]]; then
    rm -rf "$HOME/.ash"
    echo "✅ Removed Ash installation directory"
fi

echo "✅ Ash uninstallation complete!"
echo "💡 Restart your terminal for changes to take effect"
EOF

chmod +x "$INSTALL_DIR/uninstall.sh"

print_success "Installation complete!"
echo ""
echo "🎉 Ash has been successfully installed!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Enable Ash mode with Ctrl+G"
echo "3. Try asking for a command like: 'find all Python files'"
echo ""
echo "📝 Custom Model Configuration:"
echo "To use a custom model file (.gguf), set the ASH_MODEL_PATH environment variable:"
echo "  export ASH_MODEL_PATH=\"/path/to/your/model.gguf\""
echo "Or start the server manually with:"
echo "  ash-server --model-path \"/path/to/your/model.gguf\""
echo ""
echo "To uninstall Ash, run: $INSTALL_DIR/uninstall.sh"
echo ""
echo "For more information, visit: https://github.com/cjan/ash" 