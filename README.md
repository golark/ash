![Ash Banner](media/banner.png)


Ash is a terminal assistant that translates natural language into efficient shell commands using a local AI model. It works on top of zsh - simply hit `Ctrl+G` to enable ash mode.

## Installation

```bash
# Add the tap
brew tap golark/ash

# Install ash
brew install ash

# Complete the installation
ash-install
```

## Features

- Local AI model (Qwen2.5-Coder-3B-Quantized)
- Natural language to shell commands
- Zsh integration with Ctrl+G toggle
- Self-contained installation

## Usage

1. Enable Ash mode by pressing `Ctrl+G` in your terminal
2. Type natural language queries like "find all Python files" or "show disk usage"
3. Ash will translate them into shell commands

## Requirements

- macOS
- zsh shell
- ~2GB free disk space (for the model)

## License

This project is licensed under the Apache 2.0 License.

