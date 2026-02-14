#!/bin/bash
# Installation script for ash shell widgets
# Supports both bash and zsh on macOS and Linux

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIDGET_BASH="$SCRIPT_DIR/widget.bash"
WIDGET_ZSH="$SCRIPT_DIR/widget.zsh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Ash Shell Widget Installer ==="
echo ""

# Detect available shells
SHELLS_TO_INSTALL=()

if command -v bash >/dev/null 2>&1; then
    SHELLS_TO_INSTALL+=("bash")
fi

if command -v zsh >/dev/null 2>&1; then
    SHELLS_TO_INSTALL+=("zsh")
fi

if [ ${#SHELLS_TO_INSTALL[@]} -eq 0 ]; then
    echo -e "${RED}Error: No supported shells found (bash or zsh)${NC}"
    exit 1
fi

echo "Detected shells: ${SHELLS_TO_INSTALL[*]}"
echo ""

# Function to install bash widget
install_bash_widget() {
    local rcfile="$HOME/.bashrc"

    # Check if already installed
    if grep -q "source.*widget.bash" "$rcfile" 2>/dev/null; then
        echo -e "${YELLOW}Bash widget already installed in $rcfile${NC}"
        return 0
    fi

    echo "Installing bash widget..."

    # Add to .bashrc
    cat >> "$rcfile" << EOF

# Ash shell widget (Ctrl+G)
if [ -f "$WIDGET_BASH" ]; then
    source "$WIDGET_BASH"
fi
EOF

    echo -e "${GREEN}✓ Bash widget installed to $rcfile${NC}"
    echo "  Run: source $rcfile"
    echo "  Or start a new bash session"
}

# Function to install zsh widget
install_zsh_widget() {
    local rcfile="$HOME/.zshrc"

    # Check if already installed
    if grep -q "source.*widget.zsh" "$rcfile" 2>/dev/null; then
        echo -e "${YELLOW}Zsh widget already installed in $rcfile${NC}"
        return 0
    fi

    echo "Installing zsh widget..."

    # Add to .zshrc
    cat >> "$rcfile" << EOF

# Ash shell widget (Ctrl+G)
if [ -f "$WIDGET_ZSH" ]; then
    source "$WIDGET_ZSH"
fi
EOF

    echo -e "${GREEN}✓ Zsh widget installed to $rcfile${NC}"
    echo "  Run: source $rcfile"
    echo "  Or start a new zsh session"
}

# Ask user which shells to install for
if [ ${#SHELLS_TO_INSTALL[@]} -eq 1 ]; then
    # Only one shell available, install automatically
    echo "Installing widget for ${SHELLS_TO_INSTALL[0]}..."
    echo ""
    if [ "${SHELLS_TO_INSTALL[0]}" = "bash" ]; then
        install_bash_widget
    else
        install_zsh_widget
    fi
else
    # Multiple shells available, ask user
    echo "Which shell(s) would you like to install the widget for?"
    echo "1) Bash only"
    echo "2) Zsh only"
    echo "3) Both"
    echo ""
    read -p "Enter choice [1-3]: " choice

    case $choice in
        1)
            install_bash_widget
            ;;
        2)
            install_zsh_widget
            ;;
        3)
            install_bash_widget
            echo ""
            install_zsh_widget
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Usage:"
echo "  1. Reload your shell or run: source ~/.bashrc (or ~/.zshrc)"
echo "  2. Type a natural language command"
echo "  3. Press Ctrl+G to convert it to a shell command"
echo ""
echo "Example:"
echo "  list files in current directory <Ctrl+G>"
echo "  → ls -la"
echo ""
echo "Note: On first use, ash will download a ~2GB model"
echo "      The widget disables animation during download for a clean progress bar"
