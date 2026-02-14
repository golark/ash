.PHONY: build run clean

# Note: This project depends on the llama.cpp submodule.
# The 'build' target will automatically initialize it.

LLAMA_CPP_DIR = llama.cpp
LLAMA_CPP_COMMIT = 85c40c9b02941ebf1add1469af75f1796d513ef4
LLAMA_CPP_SENTINEL = $(LLAMA_CPP_DIR)/.git

build: $(LLAMA_CPP_SENTINEL)
	mkdir -p build
	cd build && cmake .. && cmake --build .

run: build
	./build/ash $(ARGS)

clean:
	rm -rf build

$(LLAMA_CPP_SENTINEL):
	git submodule add https://github.com/ggerganov/llama.cpp $(LLAMA_CPP_DIR) || true
	git submodule update --init --recursive
	git -C $(LLAMA_CPP_DIR) checkout $(LLAMA_CPP_COMMIT)

.PHONY: submodule
submodule: $(LLAMA_CPP_SENTINEL)

# Release targets
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
PLATFORM ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH ?= $(shell uname -m)
DIST_DIR = dist
TARBALL = ash-$(VERSION)-$(PLATFORM)-$(ARCH).tar.gz

.PHONY: release
release: build
	@echo "Creating release package for $(VERSION) on $(PLATFORM)-$(ARCH)..."
	@mkdir -p $(DIST_DIR)/ash-$(VERSION)
	@cp build/ash $(DIST_DIR)/ash-$(VERSION)/
	@cp widget.zsh $(DIST_DIR)/ash-$(VERSION)/
	@cp LICENSE $(DIST_DIR)/ash-$(VERSION)/
	@cp README.md $(DIST_DIR)/ash-$(VERSION)/
	@cd $(DIST_DIR) && tar -czf $(TARBALL) ash-$(VERSION)
	@echo "Created $(DIST_DIR)/$(TARBALL)"

.PHONY: release-homebrew
release-homebrew: release
	@echo "Releasing $(VERSION) to Homebrew..."
	@if [ -z "$(VERSION)" ] || [ "$(VERSION)" = "dev" ]; then \
		echo "Error: VERSION must be set (e.g., VERSION=v1.0.0)"; \
		exit 1; \
	fi
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "Error: GitHub CLI (gh) is required. Install it with: brew install gh"; \
		exit 1; \
	fi
	@if [ ! -d "../homebrew-ash" ]; then \
		echo "Error: ../homebrew-ash repository not found"; \
		exit 1; \
	fi
	@echo "Creating GitHub release $(VERSION)..."
	@if gh release view "$(VERSION)" >/dev/null 2>&1; then \
		echo "Release $(VERSION) already exists, updating it..."; \
		gh release upload "$(VERSION)" $(DIST_DIR)/$(TARBALL) --clobber || true; \
		gh release edit "$(VERSION)" --title "Ash $(VERSION)" --notes "$$(cat README.md)" || true; \
	else \
		gh release create "$(VERSION)" \
			--title "Ash $(VERSION)" \
			--notes "$$(cat README.md)" \
			$(DIST_DIR)/$(TARBALL); \
	fi
	@echo "Updating Homebrew formula..."
	@if command -v shasum >/dev/null 2>&1; then \
		SHA256=$$(shasum -a 256 $(DIST_DIR)/$(TARBALL) | cut -d' ' -f1); \
	elif command -v sha256sum >/dev/null 2>&1; then \
		SHA256=$$(sha256sum $(DIST_DIR)/$(TARBALL) | cut -d' ' -f1); \
	else \
		echo "Error: Neither shasum nor sha256sum found. Cannot compute sha256."; \
		exit 1; \
	fi; \
	VERSION_NUM=$$(echo $(VERSION) | sed 's/^v//'); \
	sed -i.bak "s/version \".*\"/version \"$$VERSION_NUM\"/" ../homebrew-ash/ash.rb && \
	sed -i.bak "s/sha256 \".*\"/sha256 \"$$SHA256\"/" ../homebrew-ash/ash.rb && \
	rm ../homebrew-ash/ash.rb.bak
	@echo "Committing and pushing to homebrew-ash..."
	@cd ../homebrew-ash && \
		git add ash.rb && \
		git commit -m "ash: update to $(VERSION)" && \
		git push
	@echo "✓ Release $(VERSION) complete!"
	@echo "  - GitHub release: https://github.com/golark/ash/releases/tag/$(VERSION)"
	@echo "  - Homebrew formula updated and pushed"

# Install the local build via Homebrew (no upload). Creates tarball, temporarily
# points the tap formula at it, runs brew install, then restores the formula.
# Requires: brew tap golark/ash (so the tap is installed).
.PHONY: brew-install-local
brew-install-local: release
	@TARBALL_PATH="$(shell cd $(CURDIR) && pwd)/$(DIST_DIR)/$(TARBALL)"; \
	TAP_REPO=$$(brew --repo golark/ash 2>/dev/null); \
	if [ -z "$$TAP_REPO" ] || [ ! -d "$$TAP_REPO" ]; then \
		echo "Error: Tap golark/ash not found. Run: brew tap golark/ash"; exit 1; \
	fi; \
	FORMULA="$$TAP_REPO/ash.rb"; \
	if [ ! -f "$$FORMULA" ]; then echo "Error: $$FORMULA not found"; exit 1; fi; \
	SHA256=$$(shasum -a 256 "$$TARBALL_PATH" 2>/dev/null | cut -d' ' -f1 || sha256sum "$$TARBALL_PATH" | cut -d' ' -f1); \
	TARBALL_ESC=$$(echo "$$TARBALL_PATH" | sed 's/&/\\&/g'); \
	cp "$$FORMULA" "$$FORMULA.bak"; \
	trap 'mv "$$FORMULA.bak" "$$FORMULA"' EXIT; \
	sed -e 's|url ".*"|url "file://'"$$TARBALL_ESC"'"|' -e 's|sha256 ".*"|sha256 "'$$SHA256'"|' "$$FORMULA.bak" > "$$FORMULA"; \
	echo "Installing from $$TARBALL_PATH ..."; \
	brew reinstall golark/ash/ash
