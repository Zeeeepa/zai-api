#!/usr/bin/env python3
"""Test FlareProx with Real Z.AI Requests"""

import asyncio
import sys
import os
import json

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

import config
import flareprox_manager
import httpx

async def test_direct_request():
    """Test direct request to Z.AI"""
    print("=" * 80)
    print("🎯 Test 1: Direct Request to Z.AI (No Proxy)")
    print("=" * 80)
    print()
    
    url = "https://chat.z.ai/api/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }
    
    payload = {
        "model": "glm-4.5",
        "messages": [
            {
                "role": "user",
                "content": "Hello, what is 2+2?"
            }
        ],
        "stream": False
    }
    
    try:
        print(f"📤 Sending request to: {url}")
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(url, json=payload, headers=headers)
            print(f"📥 Status: {response.status_code}")
            print(f"📥 Headers: {dict(response.headers)}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Success!")
                print(f"📝 Response: {json.dumps(data, indent=2)}")
            else:
                print(f"❌ Failed!")
                print(f"📝 Response: {response.text[:500]}")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
    
    print()

async def test_proxy_request(manager):
    """Test request through FlareProx"""
    print("=" * 80)
    print("🔄 Test 2: Request Through FlareProx")
    print("=" * 80)
    print()
    
    target_url = "https://chat.z.ai/api/chat/completions"
    
    # Get proxy URL
    proxy_url = await manager.get_proxy_url(target_url)
    if not proxy_url:
        print("❌ Could not get proxy URL")
        return
    
    print(f"🔗 Proxy URL: {proxy_url}")
    print()
    
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }
    
    payload = {
        "model": "glm-4.5",
        "messages": [
            {
                "role": "user",
                "content": "What is the capital of France?"
            }
        ],
        "stream": False
    }
    
    try:
        print(f"📤 Sending request through proxy...")
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(proxy_url, json=payload, headers=headers)
            print(f"📥 Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Success! Request routed through Cloudflare Worker")
                print(f"📝 Response: {json.dumps(data, indent=2)}")
                manager.mark_worker_success(proxy_url)
            else:
                print(f"❌ Failed!")
                print(f"📝 Response: {response.text[:500]}")
                manager.mark_worker_failure(proxy_url)
    except Exception as e:
        print(f"❌ Error: {e}")
        manager.mark_worker_failure(proxy_url)
        import traceback
        traceback.print_exc()
    
    print()

async def test_multiple_requests(manager):
    """Test multiple requests to verify IP rotation"""
    print("=" * 80)
    print("🔄 Test 3: Multiple Requests (IP Rotation Test)")
    print("=" * 80)
    print()
    
    target_url = "https://httpbin.org/ip"
    
    ips_seen = []
    
    for i in range(5):
        print(f"📤 Request {i+1}/5...")
        
        proxy_url = await manager.get_proxy_url(target_url)
        if not proxy_url:
            print("   ❌ Could not get proxy URL")
            continue
        
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.get(proxy_url)
                
                if response.status_code == 200:
                    data = response.json()
                    origin_ip = data.get('origin', 'unknown')
                    print(f"   ✅ Origin IP: {origin_ip}")
                    print(f"   🔗 Worker: {proxy_url.split('?')[0].split('//')[1].split('.')[0]}")
                    ips_seen.append(origin_ip)
                    manager.mark_worker_success(proxy_url)
                else:
                    print(f"   ❌ Status: {response.status_code}")
                    manager.mark_worker_failure(proxy_url)
        except Exception as e:
            print(f"   ❌ Error: {e}")
            manager.mark_worker_failure(proxy_url)
        
        await asyncio.sleep(1)  # Brief delay between requests
    
    print()
    print(f"📊 Results:")
    print(f"   Unique IPs seen: {len(set(ips_seen))}")
    print(f"   Total requests: {len(ips_seen)}")
    if ips_seen:
        print(f"   IPs: {', '.join(set(ips_seen))}")
    print()

async def main():
    print("=" * 80)
    print("🧪 FlareProx Real Request Tests")
    print("=" * 80)
    print()
    
    # Initialize FlareProx Manager
    settings = config.settings
    if not settings.ENABLE_FLAREPROX:
        print("❌ FlareProx is disabled")
        return
    
    print("🚀 Initializing FlareProx Manager...")
    manager = flareprox_manager.FlareProxManager()
    
    if not manager.enabled:
        print("❌ Manager not enabled")
        return
    
    await manager.initialize()
    print(f"✅ Manager ready with {len(manager.workers)} workers")
    print()
    
    # Run tests
    await test_direct_request()
    await test_proxy_request(manager)
    await test_multiple_requests(manager)
    
    # Final stats
    print("=" * 80)
    print("📊 Final Statistics")
    print("=" * 80)
    stats = manager.get_stats()
    print(f"Total Workers: {stats['total_workers']}")
    print(f"Healthy Workers: {stats['healthy_workers']}")
    print(f"Total Requests: {stats['total_requests']}")
    print()
    
    for worker in stats['workers']:
        status = "✅" if worker['healthy'] else "❌"
        print(f"{status} {worker['name']}")
        print(f"   Requests: {worker['total_requests']}")
        print(f"   Failures: {worker['failures']}")
    
    print()
    print("=" * 80)
    print("✅ All Tests Complete!")
    print("=" * 80)

if __name__ == "__main__":
    asyncio.run(main())
