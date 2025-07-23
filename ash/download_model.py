import os
import requests
from huggingface_hub import hf_hub_download

def download_gguf_model(model_name, save_directory):
    """
    Downloads a GGUF model from Hugging Face if it doesn't already exist in the specified directory.

    Args:
        model_name (str): The name of the Hugging Face model to download.
        save_directory (str): The directory where the model should be saved.
    """
    # Ensure the save directory exists
    os.makedirs(save_directory, exist_ok=True)
    
    model_path = os.path.join(save_directory, "Qwen2.5-Coder-3B-Quantized")
    
    if not os.path.exists(model_path):
        os.makedirs(model_path)
        print(f"Downloading GGUF model '{model_name}' to '{model_path}'...")
        
        # Download the GGUF file from the Qwen2.5-Coder-3B-Quantized subdirectory
        gguf_file = hf_hub_download(
            repo_id=model_name,
            filename="Qwen2.5-Coder-3B-Quantized/qwen2.5-coder-3b-q4_0.gguf",
            local_dir=model_path
        )
        print(f"Model downloaded to: {gguf_file}")
    else:
        print(f"Model directory already exists at '{model_path}'")
        
        # Check if the GGUF file exists
        gguf_file = os.path.join(model_path, "qwen2.5-coder-3b-q4_0.gguf")
        if not os.path.exists(gguf_file):
            print("GGUF file missing, downloading...")
            gguf_file = hf_hub_download(
                repo_id=model_name,
                filename="Qwen2.5-Coder-3B-Quantized/qwen2.5-coder-3b-q4_0.gguf",
                local_dir=model_path
            )
            print(f"Model downloaded to: {gguf_file}")
        else:
            print(f"GGUF file already exists at: {gguf_file}")

# Example usage
if __name__ == "__main__":
    model_name = "cjan/Qwen2.5-Coder-3B-Quantized"
    # Use absolute path to ensure it works in CI
    save_directory = os.path.join(os.getcwd(), "models")
    download_gguf_model(model_name, save_directory) 