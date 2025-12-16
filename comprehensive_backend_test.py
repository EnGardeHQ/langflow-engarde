#!/usr/bin/env python3
"""
Comprehensive Backend API Testing Script
Tests backend connectivity, authentication endpoints, and generates detailed reports
"""

import requests
import json
import time
import os
from datetime import datetime
from typing import Dict, List, Any, Optional
import urllib3

# Disable SSL warnings for development
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class BackendTester:
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.verify = False
        self.session.timeout = 10
        self.results = []
        self.auth_token = None

        # Test credentials
        self.test_credentials = {
            "email": "test@example.com",
            "password": "password123"
        }

    def log_result(self, endpoint: str, method: str, status_code: int,
                   response_time: float, success: bool, error: str = None,
                   response_data: Any = None):
        """Log test result"""
        result = {
            "timestamp": datetime.now().isoformat(),
            "endpoint": endpoint,
            "method": method,
            "status_code": status_code,
            "response_time_ms": round(response_time * 1000, 2),
            "success": success,
            "error": error,
            "response_data": response_data
        }
        self.results.append(result)

        status_emoji = "✅" if success else "❌"
        print(f"{status_emoji} {method} {endpoint} - {status_code} ({result['response_time_ms']}ms)")
        if error:
            print(f"   Error: {error}")

    def test_endpoint(self, endpoint: str, method: str = "GET",
                     data: Dict = None, headers: Dict = None) -> Dict:
        """Test a single endpoint"""
        url = f"{self.base_url}{endpoint}"

        # Add authentication header if available
        if self.auth_token and headers:
            headers["Authorization"] = f"Bearer {self.auth_token}"
        elif self.auth_token:
            headers = {"Authorization": f"Bearer {self.auth_token}"}

        try:
            start_time = time.time()

            if method.upper() == "GET":
                response = self.session.get(url, headers=headers)
            elif method.upper() == "POST":
                response = self.session.post(url, json=data, headers=headers)
            elif method.upper() == "PUT":
                response = self.session.put(url, json=data, headers=headers)
            elif method.upper() == "DELETE":
                response = self.session.delete(url, headers=headers)
            elif method.upper() == "OPTIONS":
                response = self.session.options(url, headers=headers)
            else:
                raise ValueError(f"Unsupported method: {method}")

            response_time = time.time() - start_time

            # Try to parse JSON response
            try:
                response_data = response.json()
            except:
                response_data = response.text[:500] if response.text else None

            success = response.status_code < 500
            self.log_result(endpoint, method, response.status_code,
                          response_time, success, None, response_data)

            return {
                "status_code": response.status_code,
                "response_time": response_time,
                "success": success,
                "data": response_data,
                "headers": dict(response.headers)
            }

        except requests.exceptions.ConnectionError as e:
            response_time = time.time() - start_time
            self.log_result(endpoint, method, 0, response_time, False,
                          f"Connection error: {str(e)}")
            return {
                "status_code": 0,
                "response_time": response_time,
                "success": False,
                "error": f"Connection error: {str(e)}"
            }
        except Exception as e:
            response_time = time.time() - start_time
            self.log_result(endpoint, method, 0, response_time, False,
                          f"Error: {str(e)}")
            return {
                "status_code": 0,
                "response_time": response_time,
                "success": False,
                "error": str(e)
            }

    def test_health_endpoints(self):
        """Test health and status endpoints"""
        print("\n🏥 Testing health and status endpoints...")

        health_endpoints = [
            "/health",
            "/api/health",
            "/status",
            "/api/status",
            "/ping",
            "/api/ping",
            "/",
            "/api/",
            "/docs",
            "/api/docs",
            "/swagger",
            "/api/swagger"
        ]

        for endpoint in health_endpoints:
            self.test_endpoint(endpoint)

    def test_authentication_endpoints(self):
        """Test authentication-related endpoints"""
        print("\n🔐 Testing authentication endpoints...")

        auth_endpoints = [
            "/api/auth/login",
            "/api/auth/register",
            "/api/auth/check",
            "/api/auth/logout",
            "/api/auth/refresh",
            "/auth/login",
            "/auth/register",
            "/users/login",
            "/users/register",
            "/login",
            "/register"
        ]

        # Test endpoint availability first
        for endpoint in auth_endpoints:
            result = self.test_endpoint(endpoint, "POST", self.test_credentials)

            # Try to extract auth token from successful responses
            if result["success"] and result.get("data"):
                data = result["data"]
                if isinstance(data, dict):
                    token = (data.get("token") or
                           data.get("access_token") or
                           data.get("accessToken"))
                    if token and not self.auth_token:
                        self.auth_token = token
                        print(f"   🔑 Auth token obtained from {endpoint}")

        # Test check endpoints
        check_endpoints = [
            "/api/auth/check",
            "/api/auth/me",
            "/api/users/me",
            "/auth/check",
            "/users/me"
        ]

        for endpoint in check_endpoints:
            # Test without authentication
            self.test_endpoint(endpoint)

            # Test with authentication if token available
            if self.auth_token:
                self.test_endpoint(endpoint, headers={"Authorization": f"Bearer {self.auth_token}"})

    def test_cors_configuration(self):
        """Test CORS configuration"""
        print("\n🌐 Testing CORS configuration...")

        cors_headers = {
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "authorization,content-type"
        }

        cors_endpoints = [
            "/api/auth/check",
            "/api/users/me",
            "/api/campaigns",
            "/health"
        ]

        for endpoint in cors_endpoints:
            result = self.test_endpoint(endpoint, "OPTIONS", headers=cors_headers)

            if result["success"] and "headers" in result:
                cors_headers_found = {
                    "access-control-allow-origin": result["headers"].get("access-control-allow-origin"),
                    "access-control-allow-methods": result["headers"].get("access-control-allow-methods"),
                    "access-control-allow-headers": result["headers"].get("access-control-allow-headers")
                }
                if any(cors_headers_found.values()):
                    print(f"   CORS headers for {endpoint}: {cors_headers_found}")

    def test_common_endpoints(self):
        """Test common REST API endpoints"""
        print("\n🔍 Testing common API endpoints...")

        common_endpoints = [
            # User management
            "/api/users",
            "/api/user",
            "/users",

            # Campaign management
            "/api/campaigns",
            "/api/campaign",
            "/campaigns",

            # Integration management
            "/api/integrations",
            "/api/integration",
            "/integrations",

            # Dashboard and analytics
            "/api/dashboard",
            "/api/analytics",
            "/api/stats",
            "/dashboard",

            # Marketplace
            "/api/marketplace",
            "/marketplace",

            # Workflows
            "/api/workflows",
            "/workflows",

            # AI and automation
            "/api/ai/generate",
            "/api/ai/analyze",
            "/api/automation",

            # Webhooks
            "/api/webhooks",
            "/webhooks"
        ]

        for endpoint in common_endpoints:
            self.test_endpoint(endpoint)

    def test_database_connectivity(self):
        """Test database connectivity (indirect)"""
        print("\n🗄️ Testing database connectivity (indirect)...")

        db_dependent_endpoints = [
            "/api/users",
            "/api/campaigns",
            "/api/integrations",
            "/api/dashboard",
            "/api/stats"
        ]

        db_issues = []
        for endpoint in db_dependent_endpoints:
            result = self.test_endpoint(endpoint)

            if not result["success"] and result["status_code"] >= 500:
                db_issues.append(endpoint)

            # Check for database-specific errors
            if result.get("data") and isinstance(result["data"], (str, dict)):
                data_str = str(result["data"]).lower()
                if any(keyword in data_str for keyword in ["database", "connection", "sql", "postgres"]):
                    print(f"   🔍 Database-related message at {endpoint}")

        if db_issues:
            print(f"   ⚠️ Potential database issues at: {db_issues}")

    def test_error_handling(self):
        """Test error handling and validation"""
        print("\n🚨 Testing error handling...")

        # Find a working endpoint to test error handling
        working_endpoint = None
        for result in self.results:
            if result["success"] and result["method"] == "GET":
                working_endpoint = result["endpoint"]
                break

        if not working_endpoint:
            working_endpoint = "/health"

        print(f"   Using {working_endpoint} for error handling tests...")

        # Test malformed requests
        error_tests = [
            # Invalid JSON
            {"endpoint": working_endpoint, "method": "POST", "data": "invalid json"},

            # Large payload
            {"endpoint": working_endpoint, "method": "POST",
             "data": {"data": "x" * 10000}},

            # SQL injection attempt
            {"endpoint": working_endpoint, "method": "POST",
             "data": {"id": "1' OR '1'='1", "name": "'; DROP TABLE users; --"}},

            # XSS attempt
            {"endpoint": working_endpoint, "method": "POST",
             "data": {"content": "<script>alert('xss')</script>"}},

            # Path traversal
            {"endpoint": "/api/../../../etc/passwd", "method": "GET"}
        ]

        for test in error_tests:
            self.test_endpoint(test["endpoint"], test["method"], test.get("data"))

    def test_performance(self):
        """Test API performance"""
        print("\n⚡ Testing API performance...")

        # Find successful endpoints for performance testing
        successful_endpoints = []
        for result in self.results:
            if result["success"] and result["endpoint"] not in [r["endpoint"] for r in successful_endpoints]:
                successful_endpoints.append(result)

        performance_results = []

        for endpoint_result in successful_endpoints[:5]:  # Test top 5
            endpoint = endpoint_result["endpoint"]
            print(f"   📊 Performance testing: {endpoint}")

            times = []
            for i in range(3):  # 3 requests per endpoint
                result = self.test_endpoint(endpoint)
                if result["success"]:
                    times.append(result["response_time"] * 1000)  # Convert to ms
                time.sleep(0.1)  # Small delay

            if times:
                avg_time = sum(times) / len(times)
                min_time = min(times)
                max_time = max(times)

                performance_results.append({
                    "endpoint": endpoint,
                    "average_ms": round(avg_time, 2),
                    "min_ms": round(min_time, 2),
                    "max_ms": round(max_time, 2),
                    "samples": len(times)
                })

                print(f"   ⏱️ {endpoint}: avg {round(avg_time, 2)}ms ({round(min_time, 2)}-{round(max_time, 2)}ms)")

        return performance_results

    def generate_report(self):
        """Generate comprehensive test report"""
        print("\n📋 Generating comprehensive backend test report...")

        # Calculate summary statistics
        total_tests = len(self.results)
        successful_tests = len([r for r in self.results if r["success"]])
        failed_tests = total_tests - successful_tests

        unique_endpoints = len(set(r["endpoint"] for r in self.results))
        avg_response_time = sum(r["response_time_ms"] for r in self.results) / total_tests if total_tests > 0 else 0

        # Group by status code
        status_codes = {}
        for result in self.results:
            code = result["status_code"]
            if code not in status_codes:
                status_codes[code] = 0
            status_codes[code] += 1

        # Find working endpoints
        working_endpoints = list(set(r["endpoint"] for r in self.results if r["success"]))

        # Find problematic endpoints
        problematic_endpoints = list(set(r["endpoint"] for r in self.results
                                       if not r["success"] and r["status_code"] >= 500))

        report = {
            "test_summary": {
                "timestamp": datetime.now().isoformat(),
                "total_tests": total_tests,
                "successful_tests": successful_tests,
                "failed_tests": failed_tests,
                "success_rate": round(successful_tests / total_tests * 100, 2) if total_tests > 0 else 0,
                "unique_endpoints_tested": unique_endpoints,
                "average_response_time_ms": round(avg_response_time, 2),
                "base_url": self.base_url
            },
            "status_code_distribution": status_codes,
            "working_endpoints": working_endpoints,
            "problematic_endpoints": problematic_endpoints,
            "authentication": {
                "token_obtained": self.auth_token is not None,
                "token_length": len(self.auth_token) if self.auth_token else 0
            },
            "detailed_results": self.results
        }

        # Print summary
        print(f"\n📊 Backend API Test Summary:")
        print(f"   Total Tests: {total_tests}")
        print(f"   Successful: {successful_tests} ({report['test_summary']['success_rate']}%)")
        print(f"   Failed: {failed_tests}")
        print(f"   Unique Endpoints: {unique_endpoints}")
        print(f"   Average Response Time: {round(avg_response_time, 2)}ms")

        if working_endpoints:
            print(f"\n✅ Working Endpoints ({len(working_endpoints)}):")
            for endpoint in working_endpoints[:10]:  # Show first 10
                print(f"   {endpoint}")

        if problematic_endpoints:
            print(f"\n❌ Problematic Endpoints ({len(problematic_endpoints)}):")
            for endpoint in problematic_endpoints:
                print(f"   {endpoint}")

        print(f"\n🏆 Top Status Codes:")
        for code, count in sorted(status_codes.items(), key=lambda x: x[1], reverse=True)[:5]:
            print(f"   {code}: {count} requests")

        # Save report to file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_filename = f"backend_test_report_{timestamp}.json"

        with open(report_filename, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"\n💾 Detailed report saved to: {report_filename}")

        return report

def main():
    """Main function to run all tests"""
    print("🚀 Starting Comprehensive Backend API Testing...")
    print("=" * 60)

    # Initialize tester
    tester = BackendTester()

    # Run all test suites
    try:
        tester.test_health_endpoints()
        tester.test_authentication_endpoints()
        tester.test_cors_configuration()
        tester.test_common_endpoints()
        tester.test_database_connectivity()
        tester.test_error_handling()
        performance_results = tester.test_performance()

        # Generate final report
        report = tester.generate_report()

        print("\n✅ Comprehensive backend testing completed!")

        # Determine overall health
        success_rate = report["test_summary"]["success_rate"]
        if success_rate > 80:
            print("🎉 Backend API health: EXCELLENT")
        elif success_rate > 60:
            print("🔶 Backend API health: GOOD")
        elif success_rate > 40:
            print("⚠️ Backend API health: MODERATE")
        elif success_rate > 20:
            print("🔴 Backend API health: POOR")
        else:
            print("💀 Backend API health: CRITICAL")

        return report

    except KeyboardInterrupt:
        print("\n⚠️ Testing interrupted by user")
        return tester.generate_report()
    except Exception as e:
        print(f"\n❌ Testing failed with error: {e}")
        return tester.generate_report()

if __name__ == "__main__":
    main()