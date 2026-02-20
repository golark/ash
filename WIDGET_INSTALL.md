# Ash Shell Widget Installation Guide

The ash shell widget allows you to convert natural language to shell commands by pressing **Ctrl+G**.

## Supported Shells

- **Bash** (Linux, macOS)
- **Zsh** (Linux, macOS)

## Quick Install

### Homebrew (macOS)

If you installed ash via Homebrew:

#### For Zsh
```bash
echo 'source $(brew --prefix)/opt/ash/widget.zsh' >> ~/.zshrc
source ~/.zshrc
```

#### For Bash
```bash
echo 'source $(brew --prefix)/opt/ash/widget.bash' >> ~/.bashrc
source ~/.bashrc
```

The widgets are automatically installed to `$(brew --prefix)/opt/ash/` by Homebrew.

### Linux / Manual Installation

#### Automatic Installation (Recommended)

```bash
./install-widget.sh
```

This will:
1. Detect your available shells (bash and/or zsh)
2. Ask which shell(s) to install for
3. Add the widget to your shell configuration
4. Provide instructions to activate it

#### Manual Installation

**For Bash** - Add to your `~/.bashrc`:

```bash
# Ash shell widget (Ctrl+G)
if [ -f "/path/to/ash/widget.bash" ]; then
    source "/path/to/ash/widget.bash"
fi
```

Then reload:
```bash
source ~/.bashrc
```

**For Zsh** - Add to your `~/.zshrc`:

```bash
# Ash shell widget (Ctrl+G)
if [ -f "/path/to/ash/widget.zsh" ]; then
    source "/path/to/ash/widget.zsh"
fi
```

Then reload:
```bash
source ~/.zshrc
```

## Usage

1. Type a natural language command:
   ```
   list files in current directory
   ```

2. Press **Ctrl+G**

3. The text is replaced with the shell command:
   ```
   ls -la
   ```

4. Press Enter to execute, or edit first

## Features

### Smart Animation

The widget includes an intelligent animation system:

- **Normal operation**: Shows a bouncing bar animation while ash is thinking
  ```
  find large files |
  find large files ||
  find large files |||
  ```

- **Model download**: Automatically disables animation to show a clean progress bar
  ```
  First time usage, downloading model...
    [#####################         ] 45% 900.5 / 2007.4 MiB
  ```

### First Run

On first use, ash will download a ~2GB model file:
- The download happens automatically
- Progress bar shows download status
- Animation is disabled during download for clarity
- Subsequent runs are fast (no download needed)

## Examples

```bash
# File operations
show disk usage <Ctrl+G> → df -h

# Process management
kill process on port 8080 <Ctrl+G> → lsof -ti:8080 | xargs kill -9

# Git operations
show git status <Ctrl+G> → git status

# Find files
find python files modified today <Ctrl+G> → find . -name "*.py" -mtime 0

# System info
show memory usage <Ctrl+G> → free -h
```

## Troubleshooting

### Widget not working

1. Check if widget is sourced:
   ```bash
   # For bash
   grep widget.bash ~/.bashrc

   # For zsh
   grep widget.zsh ~/.zshrc
   ```

2. Reload your shell:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

3. Verify ash is in PATH:
   ```bash
   which ash
   ```

### Animation issues

If you see garbled output during model download:
- Make sure you're using the latest widget files
- The widget should automatically disable animation during downloads
- Check that the model path is correct in the widget file

### Key binding conflicts

If Ctrl+G doesn't work:
- It might conflict with another binding
- For bash, check: `bind -P | grep "\\C-g"`
- For zsh, check: `bindkey | grep '\^G'`

You can change the key binding by editing the widget file:

**Bash** (widget.bash, last line):
```bash
bind -x '"\C-g": ash_widget'  # Change \C-g to another key
```

**Zsh** (widget.zsh, last line):
```bash
bindkey '^G' insert-semicolon  # Change ^G to another key
```

## Linux-Specific Notes

### Dependencies

The widget should work on any Linux distribution with bash or zsh installed.

### Installation Paths

On Linux, you may want to install ash system-wide:

```bash
# Copy ash to /usr/local/bin
sudo cp build/ash /usr/local/bin/

# Install widget for all users (in /etc/bash.bashrc or /etc/zsh/zshrc)
# Or per-user in ~/.bashrc or ~/.zshrc (recommended)
```

### Bash on Debian/Ubuntu

On Debian/Ubuntu, bash may not read `~/.bashrc` in login shells. Add to `~/.bash_profile`:

```bash
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
```

## Uninstalling

Remove these lines from your shell config file:

```bash
# Ash shell widget (Ctrl+G)
if [ -f "/path/to/ash/widget.bash" ]; then
    source "/path/to/ash/widget.bash"
fi
```

Then reload your shell:
```bash
source ~/.bashrc  # or ~/.zshrc
```

## See Also

- [Main README](README.md) - Building and using ash
- [widget.bash](widget.bash) - Bash widget source code
- [widget.zsh](widget.zsh) - Zsh widget source code
