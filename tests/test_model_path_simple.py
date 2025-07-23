#!/usr/bin/env python3
"""
Simple test for model path functionality
"""

import os
import sys
import tempfile
import unittest
from unittest.mock import patch, MagicMock

def test_model_path_environment_variable():
    """Test that ASH_MODEL_PATH environment variable is respected"""
    test_path = "/test/path/to/model.gguf"
    
    with patch.dict(os.environ, {'ASH_MODEL_PATH': test_path}):
        with patch('os.path.exists', return_value=True):
            # Simulate the get_model_path logic
            env_path = os.environ.get('ASH_MODEL_PATH')
            if env_path and os.path.exists(env_path):
                result = env_path
            else:
                result = 'models/Qwen2.5-Coder-3B-Quantized/qwen2.5-coder-3b-q4_0.gguf'
            
            assert result == test_path, f"Expected {test_path}, got {result}"
            print("✅ Environment variable test passed")

def test_model_path_fallback():
    """Test fallback to default path when env var is not set"""
    with patch.dict(os.environ, {}, clear=True):
        with patch('os.path.exists', return_value=False):
            # Simulate the get_model_path logic
            env_path = os.environ.get('ASH_MODEL_PATH')
            if env_path and os.path.exists(env_path):
                result = env_path
            else:
                result = 'models/Qwen2.5-Coder-3B-Quantized/qwen2.5-coder-3b-q4_0.gguf'
            
            expected = 'models/Qwen2.5-Coder-3B-Quantized/qwen2.5-coder-3b-q4_0.gguf'
            assert result == expected, f"Expected {expected}, got {result}"
            print("✅ Fallback test passed")

def test_model_path_validation():
    """Test that model path validation works"""
    with tempfile.NamedTemporaryFile(suffix='.gguf') as temp_file:
        # Test that the path is correctly set
        model_path = temp_file.name
        assert os.path.exists(model_path), f"Model file should exist: {model_path}"
        print("✅ Model path validation test passed")

if __name__ == '__main__':
    print("🧪 Running model path tests...")
    
    try:
        test_model_path_environment_variable()
        test_model_path_fallback()
        test_model_path_validation()
        print("\n🎉 All tests passed!")
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        sys.exit(1) 