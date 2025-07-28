#!/usr/bin/env python3
"""
ash Model Server - Persistent model server to avoid reloading
"""

import os
import sys
import json
import time
import signal
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# Load CLI tools knowledge base
CLI_TOOLS_KB_PATH = os.path.join(os.path.dirname(__file__), 'cli_tools_kb.json')
try:
    with open(CLI_TOOLS_KB_PATH, 'r', encoding='utf-8') as f:
        CLI_TOOLS_KB = json.load(f)
except Exception as e:
    print(f"❌ Failed to load cli_tools_kb.json: {e}")
    CLI_TOOLS_KB = []

# Local model imports
try:
    from llama_cpp import Llama
    LOCAL_MODEL_AVAILABLE = True
except ImportError:
    LOCAL_MODEL_AVAILABLE = False
    # Don't exit immediately - let the main function handle this
    pass

# Local quantized model path
def get_model_path():
    """Get the model path, handling both regular and PyInstaller environments"""
    # First check environment variable
    env_path = os.environ.get('ash_MODEL_PATH')
    if env_path and os.path.exists(env_path):
        return env_path
    
    # Check if running as PyInstaller executable
    if getattr(sys, 'frozen', False):
        # Running as PyInstaller executable
        base_path = sys._MEIPASS
        embedded_path = os.path.join(base_path, 'models', 'qwen2.5-coder-3b-instruct-q4_k_m.gguf')
        if os.path.exists(embedded_path):
            return embedded_path
    
    # Fallback to default path
    default_path = 'models/qwen2.5-coder-3b-instruct-q4_k_m.gguf'
    return default_path

MODEL_PATH = get_model_path()

DEFAULT_PORT = 8765

class ASHModel:
    """
    ASH Model class for handling model loading and command generation.
    This class can be used independently of the HTTP server.
    """
    
    def __init__(self, model_path=None, n_ctx=4096, n_threads=4, verbose=False):
        """
        Initialize the ASH Model.
        
        Args:
            model_path (str): Path to the model file. If None, uses default path.
            n_ctx (int): Context window size
            n_threads (int): Number of threads to use
            verbose (bool): Whether to enable verbose output
        """
        self.model_path = model_path or get_model_path()
        self.n_ctx = n_ctx
        self.n_threads = n_threads
        self.verbose = verbose
        self.model = None
        self.cli_tools_kb = CLI_TOOLS_KB
        
    def load(self):
        """Load the model"""
        if not LOCAL_MODEL_AVAILABLE:
            raise Exception("llama-cpp-python not available. Install with: pip install llama-cpp-python")
        
        if not os.path.exists(self.model_path):
            raise Exception(f"Model not found at: {self.model_path}")
        
        print(f'🤖 Loading local model: {self.model_path}')
        start_time = time.time()
        try:
            self.model = Llama(
                model_path=self.model_path,
                n_ctx=self.n_ctx,
                n_threads=self.n_threads,
                verbose=self.verbose
            )
            end_time = time.time()
            print(f"✅ Local model loaded successfully in {end_time - start_time:.2f} seconds!")
            return self.model
        except Exception as e:
            raise Exception(f"Failed to load model: {e}")
    
    def is_loaded(self):
        """Check if the model is loaded"""
        return self.model is not None
    
    def generate_command(self, query):
        """
        Generate a command from a natural language query.
        
        Args:
            query (str): Natural language query
            
        Returns:
            str: Generated command
        """
        if not self.is_loaded():
            raise Exception("Model is not loaded. Call load() first.")
        
        # Build the prompt - keeping it short to fit within context window
        prompt = f"""You translate natural language to terminal commands. Return only the command, no explanations.

Examples:
User: Show hidden files
Command: ls -a

User: Find .txt files
Command: find . -name "*.txt"

User: {query}
Command:"""
        try:
            response = self.model(
                prompt,
                max_tokens=100,
                temperature=0.0,
                stop=["\n\n", "User:", "Command:"]
            )
            response_text = response['choices'][0]['text'].strip()
            # Only take the first line (in case model outputs extra text)
            response_text = response_text.split('\n')[0]
            return response_text
        except Exception as e:
            raise Exception(f"Model generation error: {e}")
    
    def get_model_info(self):
        """Get information about the loaded model"""
        if not self.is_loaded():
            return {"status": "not_loaded"}
        
        return {
            "status": "loaded",
            "model_path": self.model_path,
            "model_size_gb": os.path.getsize(self.model_path) / (1024**3),
            "n_ctx": self.n_ctx,
            "n_threads": self.n_threads,
            "kb_entries": len(self.cli_tools_kb)
        }

class ModelHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, ash_model=None, **kwargs):
        self.ash_model = ash_model
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        import time
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            model_info = self.ash_model.get_model_info() if self.ash_model else {"status": "no_model"}
            response = {'status': 'healthy', 'model': MODEL_PATH, 'model_info': model_info}
            self.wfile.write(json.dumps(response).encode())
            return
        
        if self.path == '/shutdown':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {'status': 'shutting down'}
            self.wfile.write(json.dumps(response).encode())
            # Shutdown the server in a new thread to avoid blocking
            threading.Thread(target=self.server.shutdown).start()
            return
        
        if self.path.startswith('/generate'):
            # Parse query parameter
            parsed_url = urlparse(self.path)
            params = parse_qs(parsed_url.query)
            query = params.get('q', [''])[0]
            
            if not query:
                self.send_response(400)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {'error': 'Missing query parameter "q"'}
                self.wfile.write(json.dumps(response).encode())
                return
            
            try:
                request_start = time.time()
                # Generate response
                inference_start = time.time()
                response_text = self.ash_model.generate_command(query)
                inference_end = time.time()
                # Send response
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {'command': response_text}
                self.wfile.write(json.dumps(response).encode())
                request_end = time.time()
                print(f"[ash-server] Inference time: {inference_end - inference_start:.2f}s | Total request time: {request_end - request_start:.2f}s")
                
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {'error': str(e)}
                self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Suppress HTTP server logs
        pass

def load_model():
    """Load the model once (legacy function for backward compatibility)"""
    ash_model = ASHModel()
    ash_model.load()
    return ash_model.model

def run_server(port=DEFAULT_PORT, model_path=None):
    """Run the model server"""
    ash_model = ASHModel(model_path=model_path)
    ash_model.load()
    
    # Create custom handler with model
    class HandlerWithModel(ModelHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, ash_model=ash_model, **kwargs)
    
    server = HTTPServer(('localhost', port), HandlerWithModel)
    
    print(f"🚀 ash Model Server running on http://localhost:{port}")
    print("📝 Endpoints:")
    print(f"   GET /health - Check server status")
    print(f"   GET /generate?q=<query> - Generate command")
    print("🛑 Press Ctrl+C to stop the server")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Shutting down server...")
        server.shutdown()

def main():
    import sys
    import argparse
    
    parser = argparse.ArgumentParser(description='ash Model Server')
    parser.add_argument('--port', '-p', type=int, default=DEFAULT_PORT, 
                       help=f'Port to run the server on (default: {DEFAULT_PORT})')
    parser.add_argument('--model-path', '-m', type=str, 
                       help='Path to the local model file (.gguf)')
    parser.add_argument('--stop', action='store_true',
                       help='Request the server to shut down')
    # Note: --help is automatically added by argparse
    
    # Handle legacy positional argument for port
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        # If first argument is a number, treat it as port
        port = int(sys.argv[1])
        sys.argv = [sys.argv[0], '--port', str(port)] + sys.argv[2:]
    
    args = parser.parse_args()
    
    if args.stop:
        import requests
        try:
            r = requests.get(f'http://localhost:{args.port}/shutdown')
            if r.status_code == 200:
                print('✅ Server shutdown requested.')
            else:
                print(f'❌ Failed to shutdown server: {r.status_code}')
        except Exception as e:
            print(f'❌ Error contacting server: {e}')
        return
    
    # Help is handled automatically by argparse
    
    # Check if model path is provided and file exists (do this first)
    if args.model_path and not os.path.exists(args.model_path):
        print(f"❌ Model file not found: {args.model_path}")
        sys.exit(1)
    
    # Check if llama-cpp-python is available for model operations
    if not LOCAL_MODEL_AVAILABLE:
        print("❌ llama-cpp-python not available. Install with: pip install llama-cpp-python")
        sys.exit(1)
    
    run_server(port=args.port, model_path=args.model_path)

if __name__ == "__main__":
    main() 