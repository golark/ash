#!/usr/bin/env python3
"""
Unit tests for the query classification functionality in ash.py
"""

import unittest
import sys
import os
import tempfile
import json
from unittest.mock import patch, Mock

# Add the parent directory to the path so we can import ash
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from ash import ZshUI


class TestQueryClassification(unittest.TestCase):
    """Test cases for the classify_query static method"""

    def test_shell_commands(self):
        """Test that shell commands are correctly classified as shell (True)"""
        shell_commands = [
            "ls -la",
            "cd /home/user",
            "pwd",
            "cat file.txt",
            "echo 'hello world'",
            "rm -rf directory",
            "cp source dest",
            "mv old new",
            "mkdir newdir",
            "find . -name '*.py'",
            "grep -r 'pattern' .",
            "head -n 10 file.txt",
            "tail -f log.txt",
            "wc -l file.txt",
            "chmod +x script.sh",
            "ps aux",
            "kill 1234",
            "top",
            "man ls",
            "which python",
            "whoami",
            "date",
            "uptime",
            "df -h",
            "du -sh .",
            "tar -czf archive.tar.gz .",
            "awk '{print $1}' file.txt",
            "sed 's/old/new/g' file.txt",
            "cut -d: -f1 /etc/passwd",
            "sort file.txt",
            "uniq file.txt",
            "export PATH=/usr/local/bin:$PATH",
            "clear",
            "exit",
            "history",
            "python script.py",
            "pip install package",
            "npm install",
            "git status",
            "ssh user@host",
            "curl http://example.com",
            "wget http://example.com",
            "make build",
            "sudo apt update",
            "env | grep PATH",
            "source ~/.bashrc",
            "alias ll='ls -la'",
            "jobs",
            "bg %1",
            "fg %1",
            "killall process",
            "open file.txt",
            "less file.txt",
            "more file.txt",
            "nano file.txt",
            "vim file.txt",
            "nvim file.txt",
            "zsh",
            "bash",
            "fish",
            "tmux",
            "screen",
            "psql database",
            "mysql database",
            "sqlite3 database.db",
            "docker ps",
            "kubectl get pods",
            "osascript -e 'display dialog \"Hello\"'"
        ]
        
        for command in shell_commands:
            with self.subTest(command=command):
                result = ZshUI.is_shell_command(command)
                self.assertTrue(result, f"Expected True for '{command}', got '{result}'")

    def test_shell_operators(self):
        """Test that commands with shell operators are classified as shell (True)"""
        shell_operator_commands = [
            "ls | grep .py",
            "cd /tmp && ls",
            "mkdir test || echo 'failed'",
            "echo 'hello'; echo 'world'",
            "cat file.txt > output.txt",
            "echo 'hello' >> log.txt",
            "ls 2> error.log",
            "ls &> all.log",
            "find . -name '*.py' | xargs grep 'import'",
            "ps aux | grep python | head -5",
            "cat file.txt | sort | uniq",
            "ls -la | grep '^d' | wc -l"
        ]
        
        for command in shell_operator_commands:
            with self.subTest(command=command):
                result = ZshUI.is_shell_command(command)
                self.assertTrue(result, f"Expected True for '{command}', got '{result}'")

    def test_path_commands(self):
        """Test that commands starting with paths are classified as shell (True)"""
        path_commands = [
            "./script.sh",
            "/usr/bin/python",
            "/bin/ls",
            "./my_script.py",
            "/home/user/script.sh",
            "/opt/homebrew/bin/brew",
            "./build.sh && ./run.sh"
        ]
        
        for command in path_commands:
            with self.subTest(command=command):
                result = ZshUI.is_shell_command(command)
                self.assertTrue(result, f"Expected True for '{command}', got '{result}'")

    def test_ai_queries(self):
        """Test that natural language queries are classified as not shell (False)"""
        ai_queries = [
            "show me all files in the current directory",
            "change to the home directory",
            "list all Python files",
            # "find files containing the word 'hello'",
            "create a new directory called projects",
            "remove all temporary files",
            "copy all text files to the backup folder",
            "move the old files to the archive",
            "search for TODO comments in the code",
            "count how many lines are in all Python files",
            "check the disk usage",
            "show running processes",
            "install the required packages",
            "update the system",
            "backup the database",
            "restart the service",
            "check the network connectivity",
            "compress the log files",
            "extract the archive",
            "set up the development environment",
            "deploy the application",
            "monitor the system resources",
            "clean up old files",
            "organize the documents",
            "find duplicate files",
            "check the file permissions",
            "analyze the log files",
            "generate a report",
            "send the files via email",
            "download the latest version"
        ]
        
        for query in ai_queries:
            with self.subTest(query=query):
                result = ZshUI.is_shell_command(query)
                self.assertFalse(result, f"Expected False for '{query}', got '{result}'")

    def test_edge_cases(self):
        """Test edge cases and boundary conditions"""
        edge_cases = [
            ("\n\t", False),  # Newlines and tabs
            ("ls", True),  # Single command
            ("ls -la -h --color=auto", True),  # Long command with flags
            ("echo 'hello world' && echo 'goodbye'", True),  # Multiple commands
            ("python -c \"print('hello')\"", True),  # Python one-liner
            ("find . -type f -name '*.py' -exec grep -l 'import' {} \\;", True),  # Complex find command
        ]
        
        for query, expected in edge_cases:
            with self.subTest(query=query):
                result = ZshUI.is_shell_command(query)
                self.assertEqual(result, expected, f"Expected '{expected}' for '{query}', got '{result}'")

    def test_mixed_queries(self):
        """Test queries that might be ambiguous (should be False for natural language)"""
        mixed_queries = [
            "list files",
            "show directory",
            "print working directory",
            "display files",
            "current directory",
            "file list",
            "directory contents",
            "process list",
            "system info",
            "network status",
        ]
        
        for query in mixed_queries:
            with self.subTest(query=query):
                result = ZshUI.is_shell_command(query)
                self.assertFalse(result, f"Expected False for '{query}', got '{result}'")

    def test_performance(self):
        """Test that the function performs reasonably fast for common cases"""
        import time
        
        # Test a simple shell command (should be fast due to heuristics)
        start_time = time.time()
        result = ZshUI.is_shell_command("ls -la")
        end_time = time.time()
        
        self.assertTrue(result)
        self.assertLess(end_time - start_time, 0.1, "Shell command classification should be fast (< 0.1s)")

    def test_consistency(self):
        """Test that the function gives consistent results for the same input"""
        query = "ls -la"
        result1 = ZshUI.is_shell_command(query)
        result2 = ZshUI.is_shell_command(query)
        result3 = ZshUI.is_shell_command(query)
        
        self.assertEqual(result1, result2, "Results should be consistent")
        self.assertEqual(result2, result3, "Results should be consistent")


class TestQueryClassificationIntegration(unittest.TestCase):
    """Integration tests for query classification with the full AshUI class"""

    def setUp(self):
        """Set up test environment"""
        self.app = AshUI(debug=True)

    def tearDown(self):
        """Clean up after tests"""
        pass

    def test_classify_query_integration(self):
        """Test that classify_query works within the ZshUI context"""
        # Test that the static method works when called from an instance
        result = self.app.is_shell_command("ls -la")
        self.assertTrue(result)
        
        result = self.app.is_shell_command("show me all files")
        self.assertFalse(result)

    def test_classify_query_with_debug(self):
        """Test that classify_query works with debug mode enabled"""
        # The debug mode shouldn't affect the static method
        result = AshUI.is_shell_command("ls -la")
        self.assertTrue(result)


if __name__ == '__main__':
    # Create a test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test cases
    suite.addTests(loader.loadTestsFromTestCase(TestQueryClassification))
    suite.addTests(loader.loadTestsFromTestCase(TestQueryClassificationIntegration))
    
    # Run tests with verbose output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Exit with appropriate code
    sys.exit(not result.wasSuccessful()) 