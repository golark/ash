#!/usr/bin/env python3
"""
Test script for using ASHModel directly without running the server.
"""

import sys
import os
import time

# Add the parent directory to the path
sys.path.append('..')

from ash.server import ASHModel

def test_model_direct():
    """Test the ASHModel class directly"""
    print("🚀 Testing ASHModel directly...")
    
    # Create and load the model
    print("\n1. Creating ASHModel instance...")
    ash_model = ASHModel()
    
    print("\n2. Loading the model...")
    try:
        ash_model.load()
        print("✅ Model loaded successfully!")
    except Exception as e:
        print(f"❌ Failed to load model: {e}")
        return
    
    # Get model information
    print("\n3. Model information:")
    info = ash_model.get_model_info()
    for key, value in info.items():
        print(f"   {key}: {value}")
    
    # Test some queries
    print("\n4. Testing queries:")
    test_queries = [
        "Show hidden files in the current directory",
        "Find all Python files in the current directory and subdirectories",
        "List all running processes",
        "Check disk usage",
        "Search for TODO comments in Python files"
    ]
    
    for i, query in enumerate(test_queries, 1):
        print(f"\n   Test {i}: {query}")
        try:
            start_time = time.time()
            result = ash_model.generate_command(query)
            end_time = time.time()
            print(f"   ✅ Generated: {result}")
            print(f"   ⏱️  Time: {end_time - start_time:.2f}s")
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    print("\n✅ All tests completed!")

def interactive_mode():
    """Run in interactive mode for manual testing"""
    print("🚀 Starting interactive mode...")
    
    # Create and load the model
    ash_model = ASHModel()
    try:
        ash_model.load()
        print("✅ Model loaded successfully!")
    except Exception as e:
        print(f"❌ Failed to load model: {e}")
        return
    
    print("\n💡 Enter your queries (type 'quit' to exit):")
    
    while True:
        try:
            query = input("\n🔍 Query: ").strip()
            if query.lower() in ['quit', 'exit', 'q']:
                break
            
            if not query:
                continue
            
            start_time = time.time()
            result = ash_model.generate_command(query)
            end_time = time.time()
            
            print(f"✅ Generated: {result}")
            print(f"⏱️  Time: {end_time - start_time:.2f}s")
            
        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            break
        except Exception as e:
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--interactive":
        interactive_mode()
    else:
        test_model_direct() 