class Ash < Formula
  desc "AI-powered shell assistant that translates natural language to commands"
  homepage "https://github.com/golark/ash"
  version "0.0.3"
  license "Apache-2.0"
  
  # GitHub release URL for v0.0.3
  url "https://github.com/golark/ash/releases/download/v0.0.3/ash-v0.0.3.tar.gz"
  sha256 "852c5def06573f3be0b2c0e9cddfdaf68dbe6f335053eb656b6785c845e601d8"
  
  depends_on :macos
  
  def install
    # Install binaries
    bin.install "ash-client"
    bin.install "ash-server"
    
    # Install shell integration
    pkgshare.install "ash.zsh"
    
    # Create installation script
    (bin/"ash-install").write <<~EOS
      #!/bin/bash
      echo "🚀 Installing Ash shell integration..."
      
      # Add to PATH if not present
      if ! grep -q 'export PATH="#{HOMEBREW_PREFIX}/bin:$PATH"' ~/.zshrc; then
        echo 'export PATH="#{HOMEBREW_PREFIX}/bin:$PATH"' >> ~/.zshrc
        echo "✅ Added Ash to PATH"
      fi
      
      # Source ash.zsh if not present
      if ! grep -q 'source #{pkgshare}/ash.zsh' ~/.zshrc; then
        echo 'source #{pkgshare}/ash.zsh' >> ~/.zshrc
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
      
      # Remove from PATH
      sed -i '' '/export PATH="#{HOMEBREW_PREFIX}\/bin:$PATH"/d' ~/.zshrc
      
      # Remove ash.zsh source
      sed -i '' '/source #{pkgshare}\/ash.zsh/d' ~/.zshrc
      
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
      1. Run: ash-install
      2. Restart your terminal or run: source ~/.zshrc
      3. Enable Ash mode with Ctrl+G
      
      To uninstall shell integration:
      Run: ash-uninstall
      
      For more information, visit: #{homepage}
    EOS
  end
end 