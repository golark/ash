#!/usr/bin/env python3
"""
Ash Model Test Runner - Simplified
Runs all test cases and provides PASS/FAIL statistics.
"""

import json
import os
import sys
import time
import requests
from pathlib import Path

def check_server(server_url):
    """Check if the Ash server is running."""
    try:
        response = requests.get(f"{server_url}/ping", timeout=5)
        return response.status_code == 200
    except:
        return False

def generate_command(server_url, query):
    """Generate a command using the Ash model."""
    try:
        start_time = time.time()
        response = requests.get(
            f"{server_url}/generate",
            params={"q": query},
            timeout=30
        )
        end_time = time.time()
        
        if response.status_code == 200:
            data = response.json()
            return data.get("command", ""), end_time - start_time
        return "", end_time - start_time
    except Exception as e:
        print(f"Error: {e}")
        return "", 0.0

def normalize_command(command):
    """Normalize command for comparison."""
    if not command:
        return ""
    return " ".join(command.split())

def command_matches(actual, expected):
    """Check if actual command matches any expected command."""
    actual_norm = normalize_command(actual)
    
    for expected_cmd in expected:
        expected_norm = normalize_command(expected_cmd)
        if actual_norm == expected_norm or expected_norm in actual_norm:
            return True
    return False

def load_test_cases(test_data_dir="test_data"):
    """Load all test cases from JSON files."""
    test_cases = []
    test_data_path = Path(__file__).parent / test_data_dir
    
    for json_file in test_data_path.glob("*.json"):
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                cases = json.load(f)
                for case in cases:
                    case['file_name'] = json_file.stem
                test_cases.extend(cases)
            print(f"Loaded {len(cases)} tests from {json_file.name}")
        except Exception as e:
            print(f"Error loading {json_file}: {e}")
    
    return test_cases

def run_tests(server_url):
    """Run all test cases."""
    print("Loading test cases...")
    test_cases = load_test_cases()
    print(f"Total test cases: {len(test_cases)}")
    
    print(f"\nRunning tests against: {server_url}")
    print("-" * 60)
    
    results = []
    total_points = 0
    earned_points = 0
    inference_times = []
    
    for i, test_case in enumerate(test_cases, 1):
        query = test_case["query"]
        expected = test_case["expected"]
        points = test_case.get("points", 3)
        file_name = test_case.get("file_name", "unknown")
        
        if isinstance(expected, str):
            expected = [expected]
        
        actual_command, inference_time = generate_command(server_url, query)
        passed = command_matches(actual_command, expected)
        
        total_points += points
        if passed:
            earned_points += points
        inference_times.append(inference_time)
        
        status = "✅" if passed else "❌"
        print(f"{i:3d}. {status} {file_name:12s} | {query[:40]:40s} | {inference_time:.3f}s")
        
        if not passed:
            print(f"     Expected: {expected}")
            print(f"     Actual:   {actual_command}")
    
    return {
        'total_tests': len(test_cases),
        'passed_tests': sum(1 for r in results if r.get('passed', False)),
        'total_points': total_points,
        'earned_points': earned_points,
        'inference_times': inference_times
    }

def print_stats(stats):
    """Print test statistics."""
    print("\n" + "=" * 60)
    print("📊 TEST RESULTS")
    print("=" * 60)
    
    pass_rate = (stats['earned_points'] / stats['total_points']) * 100 if stats['total_points'] > 0 else 0
    avg_time = sum(stats['inference_times']) / len(stats['inference_times']) if stats['inference_times'] else 0
    
    print(f"Tests:           {stats['total_tests']}")
    print(f"Points Earned:   {stats['earned_points']}/{stats['total_points']}")
    print(f"Score:           {pass_rate:.1f}%")
    print(f"Avg Time:        {avg_time:.3f}s")
    
    if pass_rate >= 80:
        print("\n🎉 Test suite passed!")
        return 0
    else:
        print(f"\n⚠️  Test suite failed ({pass_rate:.1f}%)")
        return 1

def main():
    """Main function."""
    server_url = "http://localhost:8765"
    
    stats = run_tests(server_url)
    exit_code = print_stats(stats)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
