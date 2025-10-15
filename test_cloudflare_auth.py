#!/usr/bin/env python3
"""Test Cloudflare API Authentication"""

import asyncio
import httpx
import os
from dotenv import load_dotenv

load_dotenv()

async def test_auth():
    api_token = os.getenv("CLOUDFLARE_API_TOKEN")
    account_id = os.getenv("CLOUDFLARE_ACCOUNT_ID")
    
    print("=" * 80)
    print("🔐 Cloudflare API Authentication Test")
    print("=" * 80)
    print()
    print(f"API Token: {api_token[:20]}...{api_token[-6:]}" if api_token else "None")
    print(f"Account ID: {account_id}")
    print()
    
    if not api_token or not account_id:
        print("❌ Missing credentials")
        return
    
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    
    # Test 1: Verify token
    print("🧪 Test 1: Verifying token...")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://api.cloudflare.com/client/v4/user/tokens/verify",
                headers=headers,
                timeout=30
            )
            print(f"   Status: {response.status_code}")
            data = response.json()
            if response.status_code == 200:
                print(f"   ✅ Token is valid!")
                print(f"   Status: {data.get('result', {}).get('status', 'unknown')}")
            else:
                print(f"   ❌ Token verification failed")
                print(f"   Response: {data}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    print()
    
    # Test 2: Get account info
    print(f"🧪 Test 2: Getting account info...")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://api.cloudflare.com/client/v4/accounts/{account_id}",
                headers=headers,
                timeout=30
            )
            print(f"   Status: {response.status_code}")
            data = response.json()
            if response.status_code == 200:
                account = data.get('result', {})
                print(f"   ✅ Account found!")
                print(f"   Name: {account.get('name', 'unknown')}")
                print(f"   ID: {account.get('id', 'unknown')}")
            else:
                print(f"   ❌ Account not found")
                print(f"   Response: {data}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    print()
    
    # Test 3: Check Workers permissions
    print(f"🧪 Test 3: Checking Workers permissions...")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/scripts",
                headers=headers,
                timeout=30
            )
            print(f"   Status: {response.status_code}")
            data = response.json()
            if response.status_code == 200:
                scripts = data.get('result', [])
                print(f"   ✅ Can access Workers!")
                print(f"   Existing scripts: {len(scripts)}")
            else:
                print(f"   ❌ Cannot access Workers")
                print(f"   Errors: {data.get('errors', [])}")
                print(f"   Messages: {data.get('messages', [])}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    print()
    
    print("=" * 80)

if __name__ == "__main__":
    asyncio.run(test_auth())
