#!/usr/bin/env python3
"""
ash Client - Fast client that connects to the model server
"""

import os
import sys
import json
import requests
import time

# Server configuration
SERVER_URL = os.environ.get('ash_SERVER_URL', 'http://localhost:8765')

def check_server():
    """Check if the server is running"""
    try:
        response = requests.get(f"{SERVER_URL}/health", timeout=1)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Connected to ash server (model: {data.get('model', 'unknown')})")
            return True
    except requests.exceptions.RequestException:
        pass
    return False

def generate_command(query, debug=False):
    """Generate command using the server"""
    try:
        response = requests.get(
            f"{SERVER_URL}/generate",
            params={'q': query},
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            return data.get('command', '')
        else:
            print(f"❌ Server error: {response.status_code}")
            return None
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out")
        return None
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to server")
        return None
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def interactive_shell():
    """Interactive shell mode"""
    print("ash Client - Interactive Shell. Type 'exit' or 'quit' to leave.")
    print("Make sure the server is running with: python ash_server.py")
    
    history_file = os.path.expanduser('~/.ashell/history')
    history_dir = os.path.dirname(history_file)
    os.makedirs(history_dir, exist_ok=True)
    
    try:
        while True:
            try:
                query = input("ash> ").strip()
            except (EOFError, KeyboardInterrupt):
                print("\nExiting ash client.")
                break
                
            if query.lower() in ("exit", "quit"):
                print("Exiting ash client.")
                break
                
            if not query:
                continue
                
            # Save to history
            try:
                with open(history_file, 'a', encoding='utf-8') as f:
                    f.write(query + '\n')
            except Exception as e:
                print(f"Error saving query to history: {e}")
            
            # Generate command
            start_time = time.time()
            response = generate_command(query)
            end_time = time.time()
            
            if response:
                print(f"{response} (generated in {end_time - start_time:.2f}s)")
            else:
                print("❌ Failed to generate command")
                
    except Exception as e:
        print(f"Shell error: {e}")

def main():
    start_total = time.time()
    # Check for quiet mode flag
    quiet_mode = '--quiet' in sys.argv
    if quiet_mode:
        sys.argv.remove('--quiet')
    
    # Check if server is running (skip in quiet mode)
    if not quiet_mode and not check_server():
        print("❌ ash server is not running!")
        print("Start the server with: python ash_server.py")
        print("Or run in background: nohup python ash_server.py > qsh_server.log 2>&1 &")
        sys.exit(1)
    
    if len(sys.argv) > 1:
        # Single command mode
        query = " ".join(sys.argv[1:])
        
        # Save query to history (skip in quiet mode)
        if not quiet_mode:
            history_file = os.path.expanduser('~/.ashell/history')
            history_dir = os.path.dirname(history_file)
            os.makedirs(history_dir, exist_ok=True)
            try:
                with open(history_file, 'a', encoding='utf-8') as f:
                    f.write(query + '\n')
            except Exception as e:
                print(f"Error saving query to history: {e}")
        
        # Generate command
        start_time = time.time()
        response = generate_command(query)
        end_time = time.time()
        
        if response:
            if quiet_mode:
                print(response)  # Only print the command
            else:
                print(f"{response} (generated in {end_time - start_time:.2f}s)")
        else:
            if not quiet_mode:
                print("❌ Failed to generate command")
    else:
        # Interactive mode
        interactive_shell()
    start_request = time.time()
    # (Assume the main client logic sends a request to the server here)
    # For example, if using requests.get/post:
    # response = requests.get(...)
    # ...
    end_request = time.time()
    print(f"[ash-client] Request time: {end_request - start_request:.2f}s")
    end_total = time.time()
    print(f"[ash-client] Total time: {end_total - start_total:.2f}s")

if __name__ == "__main__":
    main() 