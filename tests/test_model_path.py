#!/usr/bin/env python3
"""
Test custom model path functionality
"""

import os
import sys
import tempfile
import unittest
from unittest.mock import patch, MagicMock

# Add the ash directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'ash'))

# Mock the llama_cpp import to avoid sys.exit()
import sys
from unittest.mock import patch

# Mock llama_cpp before importing server
with patch.dict('sys.modules', {'llama_cpp': MagicMock()}):
    try:
        from server import ASHModel, get_model_path
        LLAMA_AVAILABLE = True
    except SystemExit:
        # Handle the case where server.py calls sys.exit()
        LLAMA_AVAILABLE = False
        print("Warning: llama-cpp-python not available, skipping model loading tests")

class TestModelPath(unittest.TestCase):
    
    def test_get_model_path_environment_variable(self):
        """Test that ASH_MODEL_PATH environment variable is respected"""
        test_path = "/test/path/to/model.gguf"
        
        with patch.dict(os.environ, {'ASH_MODEL_PATH': test_path}):
            with patch('os.path.exists', return_value=True):
                result = get_model_path()
                self.assertEqual(result, test_path)
    
    def test_get_model_path_fallback(self):
        """Test fallback to default path when env var is not set"""
        with patch.dict(os.environ, {}, clear=True):
            with patch('os.path.exists', return_value=False):
                result = get_model_path()
                self.assertEqual(result, 'models/qwen2.5-coder-3b-instruct-q4_k_m.gguf')
    
    def test_ash_model_custom_path(self):
        """Test ASHModel initialization with custom path"""
        custom_path = "/custom/path/model.gguf"
        model = ASHModel(model_path=custom_path)
        self.assertEqual(model.model_path, custom_path)
    
    def test_ash_model_default_path(self):
        """Test ASHModel initialization with default path"""
        with patch('server.get_model_path', return_value="/default/path/model.gguf"):
            model = ASHModel()
            self.assertEqual(model.model_path, "/default/path/model.gguf")
    
    def test_model_path_validation(self):
        """Test that model path validation works"""
        with tempfile.NamedTemporaryFile(suffix='.gguf') as temp_file:
            # Should not raise an exception when file exists
            model = ASHModel(model_path=temp_file.name)
            self.assertEqual(model.model_path, temp_file.name)
    
    @unittest.skipUnless(LLAMA_AVAILABLE, "llama-cpp-python not available")
    def test_model_path_nonexistent(self):
        """Test that non-existent model path raises appropriate error"""
        nonexistent_path = "/nonexistent/path/model.gguf"
        model = ASHModel(model_path=nonexistent_path)
        
        with self.assertRaises(Exception) as context:
            model.load()
        
        self.assertIn("Model not found at:", str(context.exception))

if __name__ == '__main__':
    unittest.main() 