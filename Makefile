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
	./build/cli

clean:
	rm -rf build

$(LLAMA_CPP_SENTINEL):
	git submodule add https://github.com/ggerganov/llama.cpp $(LLAMA_CPP_DIR) || true
	git submodule update --init --recursive
	git -C $(LLAMA_CPP_DIR) checkout $(LLAMA_CPP_COMMIT)

.PHONY: submodule
submodule: $(LLAMA_CPP_SENTINEL)
