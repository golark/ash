# Homebrew Tap for Ash

This repository contains the Homebrew formula for [Ash](https://github.com/golark/ash), an AI-powered shell assistant that translates natural language to commands.

## Installation

```bash
# Tap this repository
brew tap golark/ash

# Install Ash
brew install ash

# Run the installer
ash-install
```

## Usage

After installation:

1. Restart your terminal or run: `source ~/.zshrc`
2. Press `Ctrl+G` to toggle Ash mode
3. Type natural language commands like "find all python files"

## Features

- Local AI model (Qwen2.5-Coder-3B-Quantized)
- Natural language to shell commands
- Zsh integration with Ctrl+G toggle
- Self-contained installation

## Uninstallation

```bash
# Remove shell integration
ash-uninstall

# Uninstall the package
brew uninstall ash
```

## Formula Details

- **Version**: 0.0.8-homebrew
- **SHA256**: `21a26225be48e7afd1ad228b6fceeb3b17d700d43d196f09e1899ef06dc70105`
- **License**: Apache-2.0
- **Homepage**: https://github.com/golark/ash

## Manual Installation

If you prefer manual installation:

```bash
curl -L https://github.com/golark/ash/releases/download/v0.0.8-homebrew/ash-v0.0.8-homebrew.tar.gz | tar -xz
cd ash-v0.0.8-homebrew
./install.sh
```

