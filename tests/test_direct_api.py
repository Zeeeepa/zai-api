#!/usr/bin/env python3
"""
Standalone test script to directly test the chat.z.ai API
This helps isolate whether issues are in the gateway code or the API itself
"""

import os
import sys
import asyncio
import httpx
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.config import settings
from src.helpers import info_log, error_log, log_http_request, log_http_response
from browserforge.headers import HeaderGenerator


async def test_minimal_request():
    """Test with absolutely minimal headers"""
    print("\n" + "="*80)
    print("TEST 1: Minimal Request (just Content-Type and Authorization)")
    print("="*80)
    
    url = "https://chat.z.ai/api/chat/completions"
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {settings.ZAI_TOKEN}"
    }
    
    body = {
        "model": "GLM-4.5",
        "messages": [{"role": "user", "content": "Hello"}],
        "stream": False
    }
    
    log_http_request("POST", url, headers, body, "test1")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json=body, headers=headers, timeout=30.0)
            log_http_response(response.status_code, dict(response.headers), 
                            response.text, "test1", error=(response.status_code != 200))
            
            if response.status_code == 200:
                print("✅ TEST 1 PASSED: Minimal headers work!")
                return True
            else:
                print(f"❌ TEST 1 FAILED: Status {response.status_code}")
                return False
        except Exception as e:
            error_log(f"❌ TEST 1 EXCEPTION: {e}")
            return False


async def test_with_browser_headers():
    """Test with full browser-like headers"""
    print("\n" + "="*80)
    print("TEST 2: Full Browser Headers (using browserforge)")
    print("="*80)
    
    url = "https://chat.z.ai/api/chat/completions"
    
    # Generate browser-like headers
    header_gen = HeaderGenerator(
        browser=('chrome', 'edge'),
        os='windows',
        device='desktop',
        locale=('zh-CN', 'en-US'),
        http_version=2
    )
    
    headers = header_gen.generate()
    headers.update({
        "Content-Type": "application/json",
        "Accept": "*/*",
        "Origin": "https://chat.z.ai",
        "Referer": "https://chat.z.ai/",
        "Authorization": f"Bearer {settings.ZAI_TOKEN}",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
    })
    
    body = {
        "model": "GLM-4.5",
        "messages": [{"role": "user", "content": "Hello"}],
        "stream": False
    }
    
    log_http_request("POST", url, headers, body, "test2")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json=body, headers=headers, timeout=30.0)
            log_http_response(response.status_code, dict(response.headers), 
                            response.text, "test2", error=(response.status_code != 200))
            
            if response.status_code == 200:
                print("✅ TEST 2 PASSED: Browser headers work!")
                return True
            else:
                print(f"❌ TEST 2 FAILED: Status {response.status_code}")
                return False
        except Exception as e:
            error_log(f"❌ TEST 2 EXCEPTION: {e}")
            return False


async def test_with_curl_equivalent():
    """Test with headers that would work in curl"""
    print("\n" + "="*80)
    print("TEST 3: cURL Equivalent Headers")
    print("="*80)
    
    url = "https://chat.z.ai/api/chat/completions"
    
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Authorization": f"Bearer {settings.ZAI_TOKEN}"
    }
    
    body = {
        "model": "GLM-4.5",
        "messages": [{"role": "user", "content": "Hello"}],
        "stream": False
    }
    
    log_http_request("POST", url, headers, body, "test3")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json=body, headers=headers, timeout=30.0)
            log_http_response(response.status_code, dict(response.headers), 
                            response.text, "test3", error=(response.status_code != 200))
            
            if response.status_code == 200:
                print("✅ TEST 3 PASSED: cURL-style headers work!")
                return True
            else:
                print(f"❌ TEST 3 FAILED: Status {response.status_code}")
                return False
        except Exception as e:
            error_log(f"❌ TEST 3 EXCEPTION: {e}")
            return False


async def test_with_origin_referer():
    """Test with Origin and Referer headers specifically"""
    print("\n" + "="*80)
    print("TEST 4: With Origin and Referer Headers")
    print("="*80)
    
    url = "https://chat.z.ai/api/chat/completions"
    
    headers = {
        "Content-Type": "application/json",
        "Accept": "*/*",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Origin": "https://chat.z.ai",
        "Referer": "https://chat.z.ai/",
        "Authorization": f"Bearer {settings.ZAI_TOKEN}"
    }
    
    body = {
        "model": "GLM-4.5",
        "messages": [{"role": "user", "content": "Hello"}],
        "stream": False
    }
    
    log_http_request("POST", url, headers, body, "test4")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json=body, headers=headers, timeout=30.0)
            log_http_response(response.status_code, dict(response.headers), 
                            response.text, "test4", error=(response.status_code != 200))
            
            if response.status_code == 200:
                print("✅ TEST 4 PASSED: Origin/Referer headers work!")
                return True
            else:
                print(f"❌ TEST 4 FAILED: Status {response.status_code}")
                return False
        except Exception as e:
            error_log(f"❌ TEST 4 EXCEPTION: {e}")
            return False


async def main():
    """Run all tests"""
    print("\n" + "="*80)
    print("DIRECT API TEST SUITE")
    print("Testing chat.z.ai API directly (bypassing gateway)")
    print("="*80)
    
    # Check for token
    if not settings.ZAI_TOKEN:
        error_log("❌ ZAI_TOKEN not configured in .env")
        print("\nPlease set ZAI_TOKEN in your .env file")
        return False
    
    info_log("🔑 Using token", token_preview=settings.ZAI_TOKEN[:20] + "...")
    
    # Run all tests
    results = []
    
    test1 = await test_minimal_request()
    results.append(("Minimal Headers", test1))
    
    test2 = await test_with_browser_headers()
    results.append(("Browser Headers", test2))
    
    test3 = await test_with_curl_equivalent()
    results.append(("cURL Headers", test3))
    
    test4 = await test_with_origin_referer()
    results.append(("Origin/Referer Headers", test4))
    
    # Summary
    print("\n" + "="*80)
    print("TEST SUMMARY")
    print("="*80)
    
    for test_name, passed in results:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{test_name:30s} {status}")
    
    print("="*80)
    
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    if passed_count == total_count:
        print(f"\n🎉 All tests passed! ({passed_count}/{total_count})")
        return True
    elif passed_count > 0:
        print(f"\n⚠️  Some tests passed ({passed_count}/{total_count})")
        print("The passing tests show which headers work with the API")
        return False
    else:
        print(f"\n❌ All tests failed (0/{total_count})")
        print("This suggests a token issue or API availability problem")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)

