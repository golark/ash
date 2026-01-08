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
DIST_DIR = dist-package
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
	@mv $(DIST_DIR)/$(TARBALL) .
	@echo "Created $(TARBALL)"

.PHONY: homebrew
homebrew: release
	@echo "Homebrew package created: $(TARBALL)"
	@echo "To update the Homebrew formula, run: make release-homebrew"

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
	@echo "Creating GitHub release $(VERSION)..."
	@gh release create "$(VERSION)" \
		--title "Ash $(VERSION)" \
		--notes "$$(cat README.md)" \
		$(TARBALL) || true
	@echo "Release created! Update the Homebrew formula in your tap repository."
	@echo "Formula location: Formula/ash.rb"
	@echo "Update the URL and SHA256 in the formula:"
	@echo "  url \"https://github.com/golark/ash/releases/download/$(VERSION)/$(TARBALL)\""
	@if command -v shasum >/dev/null 2>&1; then \
		SHA256=$$(shasum -a 256 $(TARBALL) | cut -d' ' -f1); \
		echo "  sha256 \"$$SHA256\""; \
	elif command -v sha256sum >/dev/null 2>&1; then \
		SHA256=$$(sha256sum $(TARBALL) | cut -d' ' -f1); \
		echo "  sha256 \"$$SHA256\""; \
	else \
		echo "Warning: Neither shasum nor sha256sum found. Cannot compute sha256."; \
	fi
