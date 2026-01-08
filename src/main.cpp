#include "llama.h"
#include "common.h"
#include <iostream>
#include <string>
#include <vector>
#include <sstream>
#include <sys/stat.h>
#include <dirent.h>
#include <cstdlib>
#include <map>
#include <algorithm>
#include <chrono>
#include <unistd.h>
#include <fstream>

void print_usage(const char *prog_name) {
    std::cerr << "Usage: " << prog_name << " <prompt>" << std::endl;
    std::cerr << "  <prompt>: The text prompt to generate from" << std::endl;
}

int main(int argc, char **argv) {
    // Check for user argument
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    // Get the user prompt from command line arguments
    std::string user_prompt;
    for (int i = 1; i < argc; i++) {
        if (i > 1) user_prompt += " ";
        user_prompt += argv[i];
    }

    // Format the prompt using the template
    std::string prompt = "<s>[INST] You are a terminal assistant. Output EXACTLY ONE valid zsh command. No explanations. No markdown.  User request: " + user_prompt + " [/INST]";
    std::cout << prompt << std::endl;

    llama_log_set([](enum ggml_log_level level, const char * text, void * /* user_data */) {
        if (level >= GGML_LOG_LEVEL_ERROR) {
            std::cerr << text;
        }
    }, nullptr);
    llama_backend_init();

    const char *model_path = "./model/mistral-7b-instruct-v0.2.Q4_0.gguf";
    const char *lora_adapter_path = "./model/lora_mistral-7b-instruct-v0.2.gguf"; // Using itself as LoRA, per instruction

    // Model parameters (adjust as needed)
    llama_model_params model_params = llama_model_default_params();
    // Optionally configure model_params here

    // Load base model
    llama_model *model = llama_model_load_from_file(model_path, model_params);
    if (model == nullptr) {
        std::cerr << "Failed to load base model: " << model_path << std::endl;
        llama_backend_free();
        return 1;
    }

    // Load LoRA adapter (will be applied to context later)
    llama_adapter_lora *lora_adapter = llama_adapter_lora_init(model, lora_adapter_path);
    if (lora_adapter == nullptr) {
        std::cerr << "Failed to load LoRA adapter: " << lora_adapter_path << std::endl;
        llama_model_free(model);
        llama_backend_free();
        return 1;
    } else {
        std::cout << "Loaded LoRA adapter: " << lora_adapter_path << std::endl;
    }

    // Get vocabulary for tokenization
    const llama_vocab *vocab = llama_model_get_vocab(model);

    // Initialize the context
    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 2048;  // Context size
    ctx_params.n_batch = 512; // Batch size

    llama_context *ctx = llama_init_from_model(model, ctx_params);
    if (ctx == nullptr) {
        std::cerr << "Failed to create llama context" << std::endl;
        llama_adapter_lora_free(lora_adapter);
        llama_model_free(model);
        llama_backend_free();
        return 1;
    }

    // Apply LoRA adapter to the context
    int lora_ret = llama_set_adapter_lora(ctx, lora_adapter, 1.0f);
    if (lora_ret != 0) {
        std::cerr << "Failed to apply LoRA adapter to context" << std::endl;
        llama_free(ctx);
        llama_adapter_lora_free(lora_adapter);
        llama_model_free(model);
        llama_backend_free();
        return 1;
    } else {
        std::cout << "Applied LoRA adapter to context" << std::endl;
    }

    // Initialize the sampler
    llama_sampler *smpl = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(smpl, llama_sampler_init_min_p(0.05f, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(0.8f));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    // Tokenize the prompt
    const bool is_first = llama_memory_seq_pos_max(llama_get_memory(ctx), 0) == -1;
    const int n_prompt_tokens = -llama_tokenize(vocab, prompt.c_str(), prompt.size(), NULL, 0, is_first, true);
    
    if (n_prompt_tokens <= 0) {
        std::cerr << "Failed to tokenize prompt" << std::endl;
        llama_sampler_free(smpl);
        llama_free(ctx);
        llama_adapter_lora_free(lora_adapter);
        llama_model_free(model);
        llama_backend_free();
        return 1;
    }

    std::vector<llama_token> prompt_tokens(n_prompt_tokens);
    if (llama_tokenize(vocab, prompt.c_str(), prompt.size(), prompt_tokens.data(), prompt_tokens.size(), is_first, true) < 0) {
        std::cerr << "Failed to tokenize the prompt" << std::endl;
        llama_sampler_free(smpl);
        llama_free(ctx);
        llama_adapter_lora_free(lora_adapter);
        llama_model_free(model);
        llama_backend_free();
        return 1;
    }

    // Prepare a batch for the prompt
    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), prompt_tokens.size());
    llama_token new_token_id;
    
    // Generate response
    std::string response;
    while (true) {
        // Check if we have enough space in the context
        int n_ctx = llama_n_ctx(ctx);
        int n_ctx_used = llama_memory_seq_pos_max(llama_get_memory(ctx), 0) + 1;
        if (n_ctx_used + batch.n_tokens > n_ctx) {
            std::cerr << "\nContext size exceeded" << std::endl;
            break;
        }

        // Decode the batch
        int ret = llama_decode(ctx, batch);
        if (ret != 0) {
            std::cerr << "Failed to decode, ret = " << ret << std::endl;
            break;
        }

        // Sample the next token
        new_token_id = llama_sampler_sample(smpl, ctx, -1);

        // Check if it's an end of generation token
        if (llama_vocab_is_eog(vocab, new_token_id)) {
            break;
        }

        // Convert the token to a string and print it
        char buf[256];
        int n = llama_token_to_piece(vocab, new_token_id, buf, sizeof(buf), 0, true);
        if (n < 0) {
            std::cerr << "Failed to convert token to piece" << std::endl;
            break;
        }
        std::string piece(buf, n);
        std::cout << piece;
        std::cout.flush();
        response += piece;

        // Prepare the next batch with the sampled token
        batch = llama_batch_get_one(&new_token_id, 1);
    }

    std::cout << std::endl;

    // Cleanup
    llama_sampler_free(smpl);
    llama_free(ctx);
    llama_adapter_lora_free(lora_adapter);
    llama_model_free(model);
    llama_backend_free();

    return 0;
}
