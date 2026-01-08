# Ash

AI-powered shell assistant that translates natural language to zsh commands.
- **Local AI model** - Runs entirely offline, so no API keys

## Installation

### Homebrew (macOS)

```bash
brew tap cjan/ash/ash
brew install ash
```

### From Source

```bash
make build
```

## Usage

### Standalone

```bash
./build/ash "list all files in current directory"
```

### Zsh Integration

Source the widget in your `.zshrc`:

```bash
source /path/to/ash/widget.zsh
```

Then press `Ctrl+G` while typing to generate a command from your input.

