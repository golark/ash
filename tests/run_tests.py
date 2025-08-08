#!/usr/bin/env python3
"""
Ash Model Test Runner
Runs all test cases and provides PASS/FAIL statistics and inference time metrics.
"""

import json
import os
import sys
import time
import requests
from pathlib import Path
from typing import Dict, List, Tuple, Any
from dataclasses import dataclass
from datetime import datetime

@dataclass
class TestResult:
    """Represents the result of a single test case."""
    query: str
    expected: List[str]
    actual: str
    passed: bool
    inference_time: float
    points: int
    file_name: str

@dataclass
class TestStats:
    """Aggregated test statistics."""
    total_tests: int
    passed_tests: int
    failed_tests: int
    pass_rate: float
    total_points: int
    earned_points: int
    average_inference_time: float
    total_inference_time: float
    min_inference_time: float
    max_inference_time: float

class AshTestRunner:
    def __init__(self, server_url: str = "http://localhost:8765"):
        self.server_url = server_url
        self.results: List[TestResult] = []
        
    def check_server(self) -> bool:
        """Check if the Ash server is running."""
        try:
            response = requests.get(f"{self.server_url}/ping", timeout=5)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def generate_command(self, query: str) -> Tuple[str, float]:
        """Generate a command using the Ash model and measure inference time."""
        try:
            start_time = time.time()
            response = requests.get(
                f"{self.server_url}/generate",
                params={"q": query},
                timeout=30
            )
            end_time = time.time()
            
            if response.status_code == 200:
                data = response.json()
                return data.get("command", ""), end_time - start_time
            else:
                return "", end_time - start_time
        except requests.exceptions.RequestException as e:
            print(f"Error generating command for '{query}': {e}")
            return "", 0.0
    
    def normalize_command(self, command: str) -> str:
        """Normalize command for comparison (remove extra spaces, etc.)."""
        if not command:
            return ""
        # Remove extra whitespace and normalize
        return " ".join(command.split())
    
    def command_matches(self, actual: str, expected: List[str]) -> bool:
        """Check if the actual command matches any of the expected commands."""
        actual_normalized = self.normalize_command(actual)
        
        for expected_cmd in expected:
            expected_normalized = self.normalize_command(expected_cmd)
            if actual_normalized == expected_normalized:
                return True
            
            # Also check if actual command contains the expected command
            # (useful for cases where the model adds extra flags)
            if expected_normalized in actual_normalized:
                return True
                
        return False
    
    def load_test_cases(self, test_data_dir: str = "test_data") -> List[Dict[str, Any]]:
        """Load all test cases from JSON files."""
        test_cases = []
        test_data_path = Path(__file__).parent / test_data_dir
        
        for json_file in test_data_path.glob("*.json"):
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    cases = json.load(f)
                    # Add file name to each test case
                    for case in cases:
                        case['file_name'] = json_file.stem
                    test_cases.extend(cases)
                print(f"Loaded {len(cases)} test cases from {json_file.name}")
            except Exception as e:
                print(f"Error loading {json_file}: {e}")
        
        return test_cases
    
    def run_single_test(self, test_case: Dict[str, Any]) -> TestResult:
        """Run a single test case."""
        query = test_case["query"]
        expected = test_case["expected"]
        points = test_case.get("points", 3)
        file_name = test_case.get("file_name", "unknown")
        
        # Handle both string and list expected values
        if isinstance(expected, str):
            expected = [expected]
        
        actual_command, inference_time = self.generate_command(query)
        passed = self.command_matches(actual_command, expected)
        
        return TestResult(
            query=query,
            expected=expected,
            actual=actual_command,
            passed=passed,
            inference_time=inference_time,
            points=points,
            file_name=file_name
        )
    
    def run_all_tests(self) -> TestStats:
        """Run all test cases and return statistics."""
        print("Loading test cases...")
        test_cases = self.load_test_cases()
        print(f"Loaded {len(test_cases)} total test cases")
        
        print(f"\nRunning tests against server: {self.server_url}")
        print("=" * 60)
        
        for i, test_case in enumerate(test_cases, 1):
            result = self.run_single_test(test_case)
            self.results.append(result)
            
            status = "✅ PASS" if result.passed else "❌ FAIL"
            print(f"{i:3d}. {status} | {result.file_name:12s} | {result.query[:40]:40s} | {result.inference_time:.3f}s")
            
            if not result.passed:
                print(f"     Expected: {result.expected}")
                print(f"     Actual:   {result.actual}")
        
        return self.calculate_stats()
    
    def calculate_stats(self) -> TestStats:
        """Calculate comprehensive test statistics."""
        if not self.results:
            return TestStats(0, 0, 0, 0.0, 0, 0, 0.0, 0.0, 0.0, 0.0)
        
        total_tests = len(self.results)
        passed_tests = sum(1 for r in self.results if r.passed)
        failed_tests = total_tests - passed_tests
        pass_rate = (passed_tests / total_tests) * 100
        
        total_points = sum(r.points for r in self.results)
        earned_points = sum(r.points for r in self.results if r.passed)
        
        inference_times = [r.inference_time for r in self.results]
        avg_inference_time = sum(inference_times) / len(inference_times)
        total_inference_time = sum(inference_times)
        min_inference_time = min(inference_times)
        max_inference_time = max(inference_times)
        
        return TestStats(
            total_tests=total_tests,
            passed_tests=passed_tests,
            failed_tests=failed_tests,
            pass_rate=pass_rate,
            total_points=total_points,
            earned_points=earned_points,
            average_inference_time=avg_inference_time,
            total_inference_time=total_inference_time,
            min_inference_time=min_inference_time,
            max_inference_time=max_inference_time
        )
    
    def print_detailed_stats(self, stats: TestStats):
        """Print detailed test statistics."""
        print("\n" + "=" * 60)
        print("📊 TEST RESULTS SUMMARY")
        print("=" * 60)
        
        print(f"Total Tests:     {stats.total_tests}")
        print(f"Passed:          {stats.passed_tests} ✅")
        print(f"Failed:          {stats.failed_tests} ❌")
        print(f"Pass Rate:       {stats.pass_rate:.1f}%")
        print(f"Points Earned:   {stats.earned_points}/{stats.total_points}")
        print(f"Score:           {(stats.earned_points/stats.total_points)*100:.1f}%")
        
        print(f"\n⏱️  INFERENCE TIME STATISTICS")
        print(f"Average Time:    {stats.average_inference_time:.3f}s")
        print(f"Total Time:      {stats.total_inference_time:.3f}s")
        print(f"Min Time:        {stats.min_inference_time:.3f}s")
        print(f"Max Time:        {stats.max_inference_time:.3f}s")
        
        # Per-file breakdown
        print(f"\n📁 RESULTS BY FILE")
        file_stats = {}
        for result in self.results:
            if result.file_name not in file_stats:
                file_stats[result.file_name] = {"total": 0, "passed": 0}
            file_stats[result.file_name]["total"] += 1
            if result.passed:
                file_stats[result.file_name]["passed"] += 1
        
        for file_name, stats_data in sorted(file_stats.items()):
            pass_rate = (stats_data["passed"] / stats_data["total"]) * 100
            print(f"{file_name:15s}: {stats_data['passed']:2d}/{stats_data['total']:2d} ({pass_rate:5.1f}%)")
    
    def save_results(self, stats: TestStats, output_file: str = "test_results.json"):
        """Save detailed results to JSON file."""
        results_data = {
            "timestamp": datetime.now().isoformat(),
            "summary": {
                "total_tests": stats.total_tests,
                "passed_tests": stats.passed_tests,
                "failed_tests": stats.failed_tests,
                "pass_rate": stats.pass_rate,
                "total_points": stats.total_points,
                "earned_points": stats.earned_points,
                "score_percentage": (stats.earned_points/stats.total_points)*100,
                "average_inference_time": stats.average_inference_time,
                "total_inference_time": stats.total_inference_time,
                "min_inference_time": stats.min_inference_time,
                "max_inference_time": stats.max_inference_time
            },
            "detailed_results": [
                {
                    "query": r.query,
                    "expected": r.expected,
                    "actual": r.actual,
                    "passed": r.passed,
                    "inference_time": r.inference_time,
                    "points": r.points,
                    "file_name": r.file_name
                }
                for r in self.results
            ]
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(results_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Results saved to: {output_file}")

def main():
    """Main function to run the test suite."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Run Ash model test suite")
    parser.add_argument("--server", default="http://localhost:8765", 
                       help="Ash server URL (default: http://localhost:8765)")
    parser.add_argument("--output", default="test_results.json",
                       help="Output file for detailed results (default: test_results.json)")
    parser.add_argument("--test-data-dir", default="test_data",
                       help="Directory containing test JSON files (default: test_data)")
    
    args = parser.parse_args()
    
    runner = AshTestRunner(args.server)
    
    print("🔍 Checking Ash server...")
    if not runner.check_server():
        print(f"❌ Ash server is not running at {args.server}")
        print("Please start the server with: python ash_server.py")
        sys.exit(1)
    
    print("✅ Ash server is running")
    
    # Run all tests
    stats = runner.run_all_tests()
    
    # Print results
    runner.print_detailed_stats(stats)
    
    # Save results
    runner.save_results(stats, args.output)
    
    # Exit with appropriate code
    if stats.pass_rate >= 80:
        print("\n🎉 Test suite completed successfully!")
        sys.exit(0)
    else:
        print(f"\n⚠️  Test suite completed with {stats.pass_rate:.1f}% pass rate")
        sys.exit(1)

if __name__ == "__main__":
    main()
