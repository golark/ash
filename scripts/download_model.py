#!/usr/bin/env python3
"""
Simple script to download models from Hugging Face
"""

import sys
import os
from transformers import AutoTokenizer, AutoModel
from huggingface_hub import hf_hub_download, list_repo_files


def download_model(model_name, file_name=None):
    """Download a model from Hugging Face"""
    try:
        print(f"Downloading {model_name}...")
        
        # Check if it's a GGUF model (contains GGUF in the name)
        if "GGUF" in model_name.upper():
            # For GGUF models, download the specific file
            if file_name:
                # Use provided file name
                pass
            else:
                # Try to find a GGUF file in the repository
                try:
                    files = list_repo_files(model_name)
                    gguf_files = [f for f in files if f.endswith('.gguf')]
                    if gguf_files:
                        file_name = gguf_files[0]  # Use the first GGUF file found
                        print(f"Found GGUF file: {file_name}")
                    else:
                        print("No GGUF files found in repository. Please specify a file name.")
                        return
                except Exception as e:
                    print(f"Error listing repository files: {e}")
                    return
            
            model_path = hf_hub_download(
                repo_id=model_name,
                filename=file_name,
                local_dir="models"
            )
            print(f"GGUF model downloaded successfully to: {model_path}")
            
        else:
            # For regular transformer models
            tokenizer = AutoTokenizer.from_pretrained(model_name)
            model = AutoModel.from_pretrained(model_name)
            
            # Save to models directory
            model_path = os.path.join("models", model_name.split("/")[-1])
            os.makedirs("models", exist_ok=True)
            
            tokenizer.save_pretrained(model_path)
            model.save_pretrained(model_path)
            
            print(f"Model downloaded successfully to: {model_path}")
        
    except Exception as e:
        print(f"Error downloading model: {e}")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python download_model.py <model_name> [file_name]")
        print("Example: python download_model.py gpt2")
        print("Example: python download_model.py Qwen/Qwen2.5-Coder-3B-Instruct-GGUF")
        print("Example: python download_model.py Qwen/Qwen2.5-Coder-3B-Instruct-GGUF qwen2.5-coder-3b-instruct-q4_k_m.gguf")
        sys.exit(1)
    
    model_name = sys.argv[1]
    file_name = sys.argv[2] if len(sys.argv) > 2 else None
    
    download_model(model_name, file_name) 