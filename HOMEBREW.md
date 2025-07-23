# Homebrew Setup for Ash

This guide explains how to set up the Homebrew tap for Ash distribution.

## For Users

Once the tap is set up, users can install Ash with:

```bash
# Add the tap
brew tap cjan/ash

# Install ash
brew install ash

# Complete the installation
ash-install
```

## For Developers

### Setting up the Homebrew Tap

1. **Create a new repository** for the Homebrew tap:
   ```bash
   # Create a new repository named "homebrew-ash" on GitHub
   # This will be accessible as "cjan/ash" in Homebrew
   ```

2. **Add the formula** to your tap repository:
   ```bash
   # Copy the ash.rb formula to your tap repository
   # Update the URL and SHA256 when you release new versions
   ```

3. **Update the formula** for each release:
   - Update the `version` field
   - Update the `url` field to point to the new release
   - Update the `sha256` field with the new file's checksum

### Release Process

1. **Build and package** the release:
   ```bash
   make build
   make release
   ```

2. **Create a GitHub release** with the packaged files

3. **Update the Homebrew formula**:
   ```bash
   # Calculate the new SHA256
   shasum -a 256 ash-1.0.0.tar.gz
   
   # Update ash.rb with the new version, URL, and SHA256
   ```

4. **Commit and push** the updated formula to your tap repository

### Formula Structure

The `ash.rb` formula includes:

- **Binary installation**: Installs `ash-client` and `ash-server`
- **Shell integration**: Installs `ash.zsh` for zsh integration
- **Installation script**: Creates `ash-install` for easy setup
- **Uninstall script**: Creates `ash-uninstall` for cleanup
- **Post-install instructions**: Shows users what to do next

### Testing the Formula

```bash
# Test the formula locally
brew install --build-from-source ./ash.rb

# Test the installation
ash-install
```

### Troubleshooting

- **SHA256 mismatch**: Recalculate the checksum of your release file
- **URL not found**: Ensure the GitHub release URL is correct
- **Installation fails**: Check that all required files are included in the package

## Example Tap Repository Structure

```
homebrew-ash/
├── README.md
├── ash.rb
└── .github/
    └── workflows/
        └── update-formula.yml
```

## Automated Updates

You can set up GitHub Actions to automatically update the formula when you create a new release. See the `.github/workflows/homebrew-release.yml` file for an example workflow. 