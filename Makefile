.PHONY: help venv run unittest quantize clean build download

VENV = . venv/bin/activate &&

# Show help
help:
	@echo "Available targets:"
	@echo "  venv      - Create virtual environment and install dependencies"
	@echo "  download  - Download Qwen2.5-Coder-3B-Instruct-Quantized model from Hugging Face"
	@echo "  build     - Build the application (includes download)"
	@echo "  install   - Install the built application"
	@echo "  run       - Run the main application"
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
run: venv
	$(VENV) python ash/server.py --debug

# Run unit tests
unittest:
	@echo "Running unit tests..."
	$(VENV) python -m pytest tests/ -v

quantize-model:
	@echo "Setting up model quantization..."
	@echo "1. Installing dependencies..."
	pip install llama-cpp-python transformers
	@echo "2. Building llama.cpp tools..."
	@if [ ! -d "llama.cpp" ]; then \
		git clone https://github.com/ggerganov/llama.cpp.git; \
	fi
	@cd llama.cpp && mkdir -p build && cd build && cmake .. && make -j4
	@echo "3. Running quantization summary..."
	python quantization_summary.py
	@echo "✅ Quantization setup complete! Follow the instructions above." 

clean:
	rm -rf dist build ash-client.spec ash-server.spec dist dist-package

download-model: venv
	$(VENV) python scripts/download_model.py Qwen/Qwen2.5-Coder-3B-Instruct-GGUF qwen2.5-coder-3b-instruct-q4_k_m.gguf

install: build
	./sciprts/install.sh

build: clean venv download-model
	@echo "Finding llama_cpp library paths..."
	@$(VENV) python -c "import llama_cpp; import os; print('llama_cpp_path:', os.path.dirname(llama_cpp.__file__))" > /tmp/llama_path.txt 2>/dev/null || echo "llama_cpp not found, building without binary dependencies"
	@if [ -f /tmp/llama_path.txt ]; then \
		LLAMA_PATH=$$(grep 'llama_cpp_path:' /tmp/llama_path.txt | cut -d' ' -f2); \
		echo "Found llama_cpp at: $$LLAMA_PATH"; \
		if [ -f "models/qwen2.5-coder-3b-instruct-q4_k_m.gguf" ]; then \
			echo "Building with model files..."; \
			$(VENV) pyinstaller --noconfirm --onefile ash/server.py --name ash-server \
			  --add-data 'models/qwen2.5-coder-3b-instruct-q4_k_m.gguf:models'; \
		else \
			echo "Building without model files (will be downloaded at runtime)..."; \
			$(VENV) pyinstaller --noconfirm --onefile ash/server.py --name ash-server; \
		fi; \
	else \
		echo "Building without llama_cpp binary dependencies..."; \
		if [ -f "models/qwen2.5-coder-3b-instruct-q4_k_m.gguf" ]; then \
			echo "Building with model files..."; \
			$(VENV) pyinstaller --noconfirm --onefile ash/server.py --name ash-server \
			  --add-data 'models/qwen2.5-coder-3b-instruct-q4_k_m.gguf:models'; \
		else \
			echo "Building without model files (will be downloaded at runtime)..."; \
			$(VENV) pyinstaller --noconfirm --onefile ash/server.py --name ash-server; \
		fi; \
	fi
	go build -o dist/ash-client ash/client.go

release:
	./package.sh