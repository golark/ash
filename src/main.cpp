#include "llama.h"
#include <curl/curl.h>
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
#include <cstring>
#include <iomanip>
#include <unistd.h>
#include <fstream>

// Write callback for CURL: write received data to FILE* userdata.
static size_t download_write_cb(char * ptr, size_t size, size_t nmemb, void * userdata) {
    return fwrite(ptr, size, nmemb, static_cast<FILE *>(userdata));
}

// Progress callback for CURL: draw progress bar. Throttle updates to ~10 Hz.
static int download_progress_cb(void * clientp, curl_off_t dltotal, curl_off_t dlnow,
                                curl_off_t /* ultotal */, curl_off_t /* ulnow */) {
    auto * last_update = static_cast<std::chrono::steady_clock::time_point *>(clientp);
    auto now = std::chrono::steady_clock::now();
    if (dltotal > 0 && dlnow < dltotal &&
        std::chrono::duration_cast<std::chrono::milliseconds>(now - *last_update).count() < 100) {
        return 0;
    }
    *last_update = now;

    const int bar_width = 40;
    double dl_mib = dlnow / (1024.0 * 1024.0);
    std::cerr << "\r  [";
    if (dltotal > 0) {
        double total_mib = dltotal / (1024.0 * 1024.0);
        int pct = static_cast<int>((100 * dlnow) / dltotal);
        int filled = (bar_width * dlnow) / dltotal;
        for (int i = 0; i < bar_width; i++) {
            std::cerr << (i < filled ? '#' : ' ');
        }
        std::cerr << "] " << pct << "% " << std::fixed << std::setprecision(1)
                  << dl_mib << " / " << total_mib << " MiB   " << std::flush;
    } else {
        std::cerr << std::string(bar_width, '.') << "] " << std::fixed << std::setprecision(1)
                  << dl_mib << " MiB   " << std::flush;
    }
    return 0;
}

// Download a file from url to path. Returns true on success.
static bool download_file(const std::string & url, const std::string & path) {
    const std::string path_tmp = path + ".tmp";
    FILE * fp = fopen(path_tmp.c_str(), "wb");
    if (!fp) {
        std::cerr << "Failed to open " << path_tmp << " for writing" << std::endl;
        return false;
    }

    CURL * curl = curl_easy_init();
    if (!curl) {
        fclose(fp);
        remove(path_tmp.c_str());
        return false;
    }

    std::chrono::steady_clock::time_point last_progress_update;
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, download_write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
    curl_easy_setopt(curl, CURLOPT_XFERINFOFUNCTION, download_progress_cb);
    curl_easy_setopt(curl, CURLOPT_XFERINFODATA, &last_progress_update);

    bool ok = curl_easy_perform(curl) == CURLE_OK;
    long http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);
    ok = ok && (http_code >= 200 && http_code < 300);

    curl_easy_cleanup(curl);
    fclose(fp);

    std::cerr << "\r" << std::string(60, ' ') << "\r" << std::flush;  // clear progress line
    if (!ok) {
        remove(path_tmp.c_str());
        return false;
    }
    if (rename(path_tmp.c_str(), path.c_str()) != 0) {
        std::cerr << "Failed to rename " << path_tmp << " to " << path << std::endl;
        remove(path_tmp.c_str());
        return false;
    }
    return true;
}

void print_usage(const char *prog_name) {
    std::cerr << "Usage: " << prog_name << " [-d] <prompt>" << std::endl;
    std::cerr << "  -d: Enable debug mode with timing information" << std::endl;
    std::cerr << "  <prompt>: The text prompt to generate from" << std::endl;
}

// Detect shell from $SHELL (e.g. /bin/zsh -> zsh, /usr/bin/bash -> bash). Defaults to zsh.
static std::string detect_shell() {
    const char *shell = getenv("SHELL");
    if (!shell || !shell[0]) return "zsh";
    std::string s(shell);
    size_t slash = s.rfind('/');
    if (slash != std::string::npos && slash + 1 < s.size()) {
        s = s.substr(slash + 1);
    }
    if (s.empty()) return "zsh";
    return s;
}

// Guardrails: only allow output that looks like a single shell command.
static const size_t MAX_COMMAND_LENGTH = 4096;

// Returns true if the string looks like natural language / explanation rather than a shell command.
static bool is_prose_prefix(const std::string& s) {
    const char* prefixes[] = {
        "sure", "here", "the command", "the following", "i would", "i'll ", "you can",
        "you could", "to do", "to run", "try ", "use ", "for example", "for instance",
        "this command", "type ", "enter ", "input ", "result:", "command:", "answer:",
        "solution:", "here's", "here is", "that would be", "i think", "i believe",
        "perhaps", "maybe", "sorry", "cannot", "can't", "unable"
    };
    const size_t n = sizeof(prefixes) / sizeof(prefixes[0]);
    std::string lower;
    lower.reserve(s.size());
    for (size_t i = 0; i < s.size() && i < 64; i++) {
        lower += (char)std::tolower((unsigned char)s[i]);
    }
    for (size_t i = 0; i < n; i++) {
        if (lower.size() >= strlen(prefixes[i]) &&
            lower.compare(0, strlen(prefixes[i]), prefixes[i]) == 0) {
            return true;
        }
    }
    return false;
}

// Returns true if the string looks like a valid shell command (single line, not prose).
static bool looks_like_shell_command(const std::string& s) {
    if (s.empty() || s.size() > MAX_COMMAND_LENGTH) return false;
    if (is_prose_prefix(s)) return false;
    // Must contain at least one character that could start a command: letter, digit, or shell metachar.
    size_t start = s.find_first_not_of(" \t");
    if (start == std::string::npos) return false;
    char c = s[start];
    bool valid_start = std::isalnum((unsigned char)c) || c == '$' || c == '#' || c == '.' ||
                       c == '/' || c == '~' || c == '(' || c == '[' || c == '{' || c == ';' ||
                       c == '|' || c == '&' || c == '`' || c == '\'' || c == '"' || c == '=';
    if (!valid_start) return false;
    // Reject if it looks like a sentence (ends with period and no shell chars)
    if (s.size() > 2 && s.back() == '.' && s.find('$') == std::string::npos &&
        s.find('|') == std::string::npos && s.find(';') == std::string::npos &&
        s.find('`') == std::string::npos && s.find('/') == std::string::npos) {
        return false;
    }
    return true;
}

// Extract exactly the first line (single command); trim and validate.
static std::string first_command_line(const std::string& s) {
    size_t end = s.find('\n');
    if (end != std::string::npos) {
        return s.substr(0, end);
    }
    return s;
}

std::string clean_response(const std::string& response) {
    std::string cleaned = response;
    
    // Remove markdown code blocks (``` at start/end, possibly with language identifier)
    if (cleaned.size() >= 3 && cleaned.substr(0, 3) == "```") {
        size_t newline_pos = cleaned.find('\n', 3);
        if (newline_pos != std::string::npos) {
            cleaned = cleaned.substr(newline_pos + 1);
        } else {
            cleaned = cleaned.substr(3);
        }
    }
    
    // Remove trailing ``` (possibly on its own line or after content)
    size_t last_backtick = cleaned.rfind("```");
    if (last_backtick != std::string::npos) {
        std::string after_backticks = cleaned.substr(last_backtick + 3);
        bool only_whitespace = true;
        for (char c : after_backticks) {
            if (c != ' ' && c != '\t' && c != '\n' && c != '\r') {
                only_whitespace = false;
                break;
            }
        }
        if (only_whitespace) {
            cleaned = cleaned.substr(0, last_backtick);
        }
    }
    
    // Remove inline backticks
    std::string result;
    for (size_t i = 0; i < cleaned.size(); i++) {
        if (cleaned[i] != '`') {
            result += cleaned[i];
        }
    }
    cleaned = result;
    
    // Trim leading whitespace
    size_t start = cleaned.find_first_not_of(" \t\n\r");
    if (start != std::string::npos) {
        cleaned = cleaned.substr(start);
    } else {
        cleaned.clear();
    }
    
    // Trim trailing whitespace
    size_t end = cleaned.find_last_not_of(" \t\n\r");
    if (end != std::string::npos) {
        cleaned = cleaned.substr(0, end + 1);
    } else {
        cleaned.clear();
    }
    
    // Guardrail: only the first line (single command)
    cleaned = first_command_line(cleaned);
    
    // Trim again after taking first line
    start = cleaned.find_first_not_of(" \t");
    if (start != std::string::npos) {
        cleaned = cleaned.substr(start);
    }
    end = cleaned.find_last_not_of(" \t");
    if (end != std::string::npos) {
        cleaned = cleaned.substr(0, end + 1);
    } else {
        cleaned.clear();
    }
    
    return cleaned;
}

int main(int argc, char **argv) {
    // Parse command line arguments
    bool debug_mode = false;
    std::string user_prompt;
    
    for (int i = 1; i < argc; i++) {
        if (std::string(argv[i]) == "-d") {
            debug_mode = true;
        } else {
            if (!user_prompt.empty()) user_prompt += " ";
            user_prompt += argv[i];
        }
    }
    
    // Check for user prompt
    if (user_prompt.empty()) {
        print_usage(argv[0]);
        return 1;
    }

    // Detect shell and format the prompt so the model outputs the right syntax
    std::string shell_name = detect_shell();
    std::string prompt = "<|im_start|>system\nYou are a terminal assistant. Output EXACTLY ONE valid " +
        shell_name + " command. No explanations. No markdown.\n<|im_end|>\n<|im_start|>user\n" +
        user_prompt + "\n<|im_end|>\n<|im_start|>assistant\n";

    llama_log_set([](enum ggml_log_level level, const char * text, void * /* user_data */) {
        if (level >= GGML_LOG_LEVEL_ERROR) {
            std::cerr << text;
        }
    }, nullptr);
    llama_backend_init();

    // Get home directory and construct model paths
    const char *home_dir = getenv("HOME");
    if (home_dir == nullptr) {
        std::cerr << "Failed to get home directory" << std::endl;
        llama_backend_free();
        return 1;
    }
    
    std::string models_dir = std::string(home_dir) + "/.ash/models";
    std::string model_path_dest = models_dir + "/qwen2.5-coder-3b-instruct-q4_k_m.gguf";
    
    // Create models directory if it doesn't exist
    struct stat info;
    if (stat(models_dir.c_str(), &info) != 0) {
        // Create directory with permissions 0755
        if (mkdir(models_dir.c_str(), 0755) != 0) {
            std::cerr << "Failed to create models directory: " << models_dir << std::endl;
            llama_backend_free();
            return 1;
        }
    }

    // Download model from Hugging Face if it doesn't exist
    if (stat(model_path_dest.c_str(), &info) != 0) {
        std::cerr << "First time usage, downloading model (this may take a couple of minutes)..." << std::endl;
        const std::string model_url =
            "https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf";
        if (!download_file(model_url, model_path_dest)) {
            std::cerr << "Failed to download model from " << model_url << std::endl;
            llama_backend_free();
            return 1;
        }
    }

    const char *model_path = model_path_dest.c_str();

    // Model parameters (adjust as needed)
    llama_model_params model_params = llama_model_default_params();
    // Suppress progress dots during model loading
    model_params.progress_callback = [](float /* progress */, void * /* ctx */) {
        return true;
    };

    // Load base model
    auto model_load_start = std::chrono::high_resolution_clock::now();
    llama_model *model = llama_model_load_from_file(model_path, model_params);
    auto model_load_end = std::chrono::high_resolution_clock::now();
    if (model == nullptr) {
        std::cerr << "Failed to load base model: " << model_path << std::endl;
        llama_backend_free();
        return 1;
    }
    long long model_load_duration = 0;
    if (debug_mode) {
        model_load_duration = std::chrono::duration_cast<std::chrono::milliseconds>(
            model_load_end - model_load_start).count();
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
        llama_model_free(model);
        llama_backend_free();
        return 1;
    }

    // Initialize the sampler
    llama_sampler *smpl = llama_sampler_chain_init(
        llama_sampler_chain_default_params()
    );
    
    // Deterministic first
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(0.25f));
    
    // Strong probability mass pruning
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(0.85f, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(20));
    
    // Safety net against rare garbage
    llama_sampler_chain_add(smpl, llama_sampler_init_min_p(0.08f, 1));
    
    // Stable randomness (or fixed seed if you want reproducibility)
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    
    // Tokenize the prompt
    const bool is_first = llama_memory_seq_pos_max(llama_get_memory(ctx), 0) == -1;
    const int n_prompt_tokens = -llama_tokenize(vocab, prompt.c_str(), prompt.size(), NULL, 0, is_first, true);
    
    if (n_prompt_tokens <= 0) {
        std::cerr << "Failed to tokenize prompt" << std::endl;
        llama_sampler_free(smpl);
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return 1;
    }

    std::vector<llama_token> prompt_tokens(n_prompt_tokens);
    if (llama_tokenize(vocab, prompt.c_str(), prompt.size(), prompt_tokens.data(), prompt_tokens.size(), is_first, true) < 0) {
        std::cerr << "Failed to tokenize the prompt" << std::endl;
        llama_sampler_free(smpl);
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return 1;
    }

    // Prepare a batch for the prompt
    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), prompt_tokens.size());
    llama_token new_token_id;
    
    // Generate response
    auto generation_start = std::chrono::high_resolution_clock::now();
    std::string response;
    int tokens_generated = 0;
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
        response += piece;
        tokens_generated++;

        // Prepare the next batch with the sampled token
        batch = llama_batch_get_one(&new_token_id, 1);
    }
    auto generation_end = std::chrono::high_resolution_clock::now();
    
    // Clean the response and apply guardrails: only output if it looks like a shell command
    std::string cleaned_response = clean_response(response);
    if (!looks_like_shell_command(cleaned_response)) {
        std::cerr << "ash: model output did not look like a shell command (guardrail)" << std::endl;
        llama_sampler_free(smpl);
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return 1;
    }
    std::cout << cleaned_response;
    std::cout << std::endl;
    
    if (debug_mode) {
        auto generation_duration_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            generation_end - generation_start).count();
        double generation_duration_sec = generation_duration_ms / 1000.0;
        double tokens_per_sec = tokens_generated > 0 ? tokens_generated / generation_duration_sec : 0.0;
        
        // Format tokens_per_sec to 2 decimal places (round to nearest)
        int tokens_per_sec_int = (int)(tokens_per_sec * 100.0 + 0.5);
        int whole_part = tokens_per_sec_int / 100;
        int decimal_part = tokens_per_sec_int % 100;
        std::stringstream ss;
        ss << whole_part << "." << (decimal_part < 10 ? "0" : "") << decimal_part;
        std::string tokens_per_sec_str = ss.str();
        
        std::cerr << "[DEBUG] Model Load " << model_load_duration << " | Total: " << generation_duration_ms 
                  << " ms | " << tokens_per_sec_str << " tokens/sec" << std::endl;
    }

    // Cleanup
    llama_sampler_free(smpl);
    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();

    return 0;
}
