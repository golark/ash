class Ash < Formula
  desc "AI-powered shell assistant that translates natural language to commands"
  homepage "https://github.com/golark/ash"
  version "0.1.3"
  license "Apache-2.0"
  
  # GitHub release URL for v0.1.2
  url "https://github.com/golark/ash/releases/download/v0.1.3/ash-0.1.3.tar.gz"
  sha256 "2698c24539d692fa75cf335d908e88b79e91bfd9c385ddc1d6ca2c03bf8fab45"
  
  depends_on :macos
  
  def install
    # Install binaries
    bin.install "ash-client"
    bin.install "ash-server"
    
    # Install shell integration
    pkgshare.install "ash.zsh"
    
    # Install _internal directory (required for ash-server)
    bin.install "_internal"
    
    # Create installation script
    (bin/"ash-install").write <<~EOS
      #!/bin/bash
      echo "🚀 Installing Ash shell integration..."
      
      # Create .ash directory
      ASH_DIR="$HOME/.ash"
      mkdir -p "$ASH_DIR"
      echo "✅ Created Ash directory: $ASH_DIR"
      
      # Copy shell integration to .ash directory
      cp #{pkgshare}/ash.zsh "$ASH_DIR/"
      echo "✅ Copied shell integration to $ASH_DIR"
      
      # Download the AI model if not already present
      MODEL_DIR="$ASH_DIR/models"
      MODEL_FILE="$MODEL_DIR/qwen2.5-coder-3b-instruct-q4_k_m.gguf"
      
      if [[ ! -f "$MODEL_FILE" ]]; then
        echo "📥 Downloading AI model (this may take a few minutes)..."
        mkdir -p "$MODEL_DIR"
        curl -L -o "$MODEL_FILE" "https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf"
        echo "✅ Model downloaded successfully"
      else
        echo "✅ AI model already exists"
      fi
      
      # Add to PATH if not present
      if ! grep -q 'export PATH="#{HOMEBREW_PREFIX}/bin:$PATH"' ~/.zshrc; then
        echo 'export PATH="#{HOMEBREW_PREFIX}/bin:$PATH"' >> ~/.zshrc
        echo "✅ Added Ash to PATH"
      fi
      
      # Source ash.zsh if not present
      if ! grep -q 'source $HOME/.ash/ash.zsh' ~/.zshrc; then
        echo 'source $HOME/.ash/ash.zsh' >> ~/.zshrc
        echo "✅ Added Ash shell integration"
      fi
      
      echo ""
      echo "✅ Ash installation complete!"
      echo "💡 Restart your terminal or run: source ~/.zshrc"
      echo "🎯 Enable Ash mode with Ctrl+G"
      echo "📖 For help, run: ash-client --help"
    EOS
    chmod 0755, bin/"ash-install"
    
    # Create uninstall script
    (bin/"ash-uninstall").write <<~EOS
      #!/bin/bash
      echo "🗑️  Uninstalling Ash shell integration..."
      
      # Remove from PATH and source lines using a more reliable method
      # Create a temporary file without the Ash-related lines
      grep -v 'export PATH="#{HOMEBREW_PREFIX}/bin:$PATH"' ~/.zshrc | \
      grep -v 'source.*ash.zsh' > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
      echo "✅ Removed Ash configuration from ~/.zshrc"
      
      # Remove .ash directory
      if [[ -d "$HOME/.ash" ]]; then
        rm -rf "$HOME/.ash"
        echo "✅ Removed Ash directory: $HOME/.ash"
      fi
      
      echo "✅ Ash shell integration removed"
      echo "💡 Restart your terminal for changes to take effect"
    EOS
    chmod 0755, bin/"ash-uninstall"
  end
  
  test do
    # Test that the binaries work
    system "#{bin}/ash-client", "--help"
    system "#{bin}/ash-server", "--help"
  end
  
  def caveats
    <<~EOS
      🎉 Ash has been installed!
      
      To complete the installation:
      1. Run: ash-install (this will create ~/.ash directory and configure your shell)
      2. Restart your terminal or run: source ~/.zshrc
      3. Enable Ash mode with Ctrl+G
      
      To uninstall shell integration:
      Run: ash-uninstall
      
      Note: When uninstalling with 'brew uninstall ash', 
      you may need to manually remove ~/.ash directory:
      rm -rf ~/.ash
      
      For more information, visit: #{homepage}
    EOS
  end
  

end 