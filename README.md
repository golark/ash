<p align="center">
  Converts natural language into shell commands
  Local, private, and free —no API keys, no Ollama setup, just install and start using
  <br><br>
  🚀 Fast 🏠 Local & 🆓 Free
</p>
<p align="center">
  <img src="https://github.com/golark/ash/actions/workflows/ci.yml/badge.svg" alt="Build status" />
  <img src="https://img.shields.io/github/v/release/golark/ash" />
  <img src="https://img.shields.io/github/license/golark/ash" />
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue" />

</p>

![Demo](./demo/demo.gif#autoplay)

🧩 Installation

**macOS (Homebrew):**
```bash
brew tap golark/ash
brew install ash

# Enable shell widget (Ctrl+G) - add to your shell config:
# For Zsh (~/.zshrc):
echo 'source $(brew --prefix)/opt/ash/widget.zsh' >> ~/.zshrc

# For Bash (~/.bashrc or ~/.bash_profile):
echo 'source $(brew --prefix)/opt/ash/widget.bash' >> ~/.bashrc

# Reload your shell
source ~/.zshrc  # or source ~/.bashrc
```

**Linux:** Download the latest `ash-*-linux-amd64.tar.gz` from [Releases](https://github.com/golark/ash/releases), then:
```bash
tar -xzf ash-*-linux-amd64.tar.gz
cd ash-*
sudo cp ash /usr/local/bin/
# Or for your user only: cp ash ~/.local/bin/

# Install widget using the install script
./install-widget.sh

# Or manually add to ~/.bashrc or ~/.zshrc:
# source /path/to/ash/widget.bash  # for bash
# source /path/to/ash/widget.zsh   # for zsh
```

**Usage:** Type a natural language command, then press **Ctrl+G** to convert it.

See [WIDGET_INSTALL.md](WIDGET_INSTALL.md) for detailed installation instructions. 


## 🤔 Why ash?
You don’t need massive AI models, API calls just to convert natural language to shell commands — ash uses a small, efficient model that runs locally.

| Feature / Tool        | ash | ChatGPT | ShellGPT | Ollama-based tools |
|----------------------|:---:|:-------:|:--------:|:-----------------:|
| Runs fully local     | ✅  | ❌      | ❌       | ✅                |
| No API key required  | ✅  | ❌      | ❌       | ✅                |
| No large model setup | ✅  | ✅      | ❌       | ❌                |
| Works offline        | ✅  | ❌      | ❌       | ✅                |
| Privacy-first        | ✅  | ❌      | ❌       | ✅                |
| Single binary        | ✅  | ❌      | ❌       | ❌                |

## 🤝 Contributing

Contributions are welcome and appreciated!

Whether it’s:
- bug reports
- feature ideas
- documentation improvements
- code contributions

Feel free to open an issue or submit a pull request.

If you’re planning a larger change, please open an issue first so we can discuss the approach.

By contributing, you agree that your contributions will be licensed under the Apache-2.0 License.

