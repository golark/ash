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

echo "🗑️  Uninstalling Ash..."

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    print_error "Unsupported operating system: $OSTYPE"
    exit 1
fi

print_status "Uninstalling Ash from $OS..."

# Remove from .zshrc
if [[ -f "$HOME/.zshrc" ]]; then
    # Create backup
    cp "$HOME/.zshrc" "$HOME/.zshrc.ash-backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Created backup: ~/.zshrc.ash-backup.*"
    
    # Remove Ash shell integration lines
    if [[ "$OS" == "macos" ]]; then
        # macOS sed requires different syntax
        sed -i.bak '/# Ash shell integration/,+1d' "$HOME/.zshrc"
    else
        # Linux sed
        sed -i '/# Ash shell integration/,+1d' "$HOME/.zshrc"
    fi
    print_success "Removed Ash from ~/.zshrc"
else
    print_warning "~/.zshrc not found"
fi

# Remove symlinks
print_status "Removing symlinks..."

# Check and remove /usr/local/bin symlinks
if [[ -L "/usr/local/bin/ash-client" ]]; then
    rm /usr/local/bin/ash-client
    print_success "Removed ash-client symlink from /usr/local/bin"
fi

if [[ -L "/usr/local/bin/ash-server" ]]; then
    rm /usr/local/bin/ash-server
    print_success "Removed ash-server symlink from /usr/local/bin"
fi

# Check and remove ~/.local/bin symlinks
if [[ -L "$HOME/.local/bin/ash-client" ]]; then
    rm "$HOME/.local/bin/ash-client"
    print_success "Removed ash-client symlink from ~/.local/bin"
fi

if [[ -L "$HOME/.local/bin/ash-server" ]]; then
    rm "$HOME/.local/bin/ash-server"
    print_success "Removed ash-server symlink from ~/.local/bin"
fi

# Remove installation directory
INSTALL_DIR="$HOME/.ash"
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    print_success "Removed Ash installation directory: $INSTALL_DIR"
else
    print_warning "Ash installation directory not found: $INSTALL_DIR"
fi

# Stop any running ash servers
print_status "Stopping any running Ash servers..."
pkill -f "ash-server" || true
pkill -f "python.*ash/server.py" || true
print_success "Stopped any running Ash servers"

print_success "Ash uninstallation complete!"
echo ""
echo "💡 Next steps:"
echo "1. Restart your terminal for changes to take effect"
echo "2. If you want to restore your original ~/.zshrc, check the backup files:"
echo "   ls -la ~/.zshrc.ash-backup.*"
echo ""
echo "To reinstall Ash, run: make install" 