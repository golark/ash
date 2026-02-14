<p align="center">
  CLI Tool simply converts natural language to shell commands
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
```

**Linux:** Download the latest `ash-*-linux-amd64.tar.gz` from [Releases](https://github.com/golark/ash/releases), then:
```bash
tar -xzf ash-*-linux-amd64.tar.gz
cd ash-* && sudo cp ash widget.zsh /usr/local/bin/
# Or for your user only: cp ash widget.zsh ~/.local/bin/
```

**Widget (zsh):** Source in your `.zshrc`:
```bash
source /path/to/ash/widget.zsh
```
Restart your terminal, type your command followed by CTRL + G 


## 🤔 Why ash?
Because your terminal doesn’t need a cloud connection or a 10GB model.

| Feature / Tool        | ash | ChatGPT | ShellGPT | Ollama-based tools |
|----------------------|:---:|:-------:|:--------:|:-----------------:|
| Runs fully local     | ✅  | ❌      | ❌       | ✅                |
| No API key required  | ✅  | ❌      | ❌       | ✅                |
| No large model setup | ✅  | ✅      | ❌       | ❌                |
| Works offline        | ✅  | ❌      | ❌       | ✅                |
| Shell-native UX      | ✅  | ❌      | ⚠️       | ⚠️                |
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

