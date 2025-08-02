.PHONY: help venv run unittest quantize clean build download stop

VENV = . venv/bin/activate &&

# Show help
help:
	@echo "Available targets:"
	@echo "  venv      - Create virtual environment and install dependencies"
	@echo "  download  - Download Qwen2.5-Coder-3B-Instruct-Quantized model from Hugging Face"
	@echo "  build     - Build the application (includes download)"
	@echo "  install   - Install the built application"
	@echo "  run       - Run the main application"
	@echo "  stop      - Stop the ash server"
	@echo "  unittest  - Run unit tests"
	@echo "  quantize  - Set up model quantization"
	@echo "  clean     - Clean build artifacts"
	@echo "  release   - Create release package"
	@echo ""
	@echo "Custom Model Usage:"
	@echo "  ash-server --model-path /path/to/model.gguf"
	@echo "  export ASH_MODEL_PATH=/path/to/model.gguf"

# Default target
venv:
	python3 -m venv venv
	$(VENV) pip install -r requirements.txt

# Run the main application
run: venv stop
	$(VENV) python ash/server.py --port 8765

# Stop the ash server
stop:
	@echo "Stopping ash server..."
	@$(VENV) python ash/server.py --stop || echo "No ash server running or failed to stop"
	@echo "✅ ash server stop requested"

# Run unit tests
unittest:
	@echo "Running unit tests..."
	$(VENV) python -m pytest tests/ -v

clean:
	rm -rf dist build ash-client.spec ash-server.spec dist dist-package

download-model: venv
	$(VENV) python scripts/download_model.py Qwen/Qwen2.5-Coder-3B-Instruct-GGUF qwen2.5-coder-3b-instruct-q4_k_m.gguf

install: build
	./sciprts/install.sh

build: clean venv download-model build-client build-server
	@echo "✅ Build complete! Using Python server with wrapper."
	@echo "📁 Built files:"
	@echo "   - dist/ash-server (wrapper script)"
	@echo "   - dist/ash-client (Go binary)"
	@echo "   - models/qwen2.5-coder-3b-instruct-q4_k_m.gguf (model file)"

build-client:
	go build -o dist/ash-client ash/client.go

build-server:
	@echo "Building ash-server wrapper..."
	@mkdir -p dist
	@echo '#!/bin/bash' > dist/ash-server
	@echo '# Wrapper script for ash-server that runs the Python version' >> dist/ash-server
	@echo '# This provides a "released" interface while using the working Python implementation' >> dist/ash-server
	@echo '' >> dist/ash-server
	@echo '# Get the directory where this script is located' >> dist/ash-server
	@echo 'SCRIPT_DIR="$$(cd "$$(dirname "$${BASH_SOURCE[0]}")" && pwd)"' >> dist/ash-server
	@echo 'PROJECT_DIR="$$(dirname "$$SCRIPT_DIR")"' >> dist/ash-server
	@echo '' >> dist/ash-server
	@echo '# Activate virtual environment and run the Python server' >> dist/ash-server
	@echo 'cd "$$PROJECT_DIR"' >> dist/ash-server
	@echo 'source venv/bin/activate' >> dist/ash-server
	@echo 'exec python3 ash/server.py "$$@"' >> dist/ash-server
	@chmod +x dist/ash-server
	@echo "✅ ash-server wrapper built"

release:
	./package.sh
