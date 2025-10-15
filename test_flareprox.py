#!/usr/bin/env python3
"""Test FlareProx Manager"""

import asyncio
import sys
import os

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

# Import after path is set
import config
import flareprox_manager

async def main():
    print("=" * 80)
    print("🌩️  FlareProx Manager Test")
    print("=" * 80)
    print()
    
    # Check configuration
    settings = config.settings
    print("📋 Configuration:")
    print(f"   ENABLE_FLAREPROX: {settings.ENABLE_FLAREPROX}")
    print(f"   API Token: {settings.CLOUDFLARE_API_TOKEN[:20]}..." if settings.CLOUDFLARE_API_TOKEN else "   API Token: None")
    print(f"   Account ID: {settings.CLOUDFLARE_ACCOUNT_ID[:8]}..." if settings.CLOUDFLARE_ACCOUNT_ID else "   Account ID: None")
    print()
    
    if not settings.ENABLE_FLAREPROX:
        print("❌ FlareProx is disabled. Set ENABLE_FLAREPROX=true in .env")
        return
    
    if not settings.CLOUDFLARE_API_TOKEN or not settings.CLOUDFLARE_ACCOUNT_ID:
        print("❌ Cloudflare credentials missing in .env")
        return
    
    print("🚀 Initializing FlareProx Manager...")
    manager = flareprox_manager.FlareProxManager()
    
    if not manager.enabled:
        print("❌ Manager not enabled (check credentials)")
        return
    
    print("✅ Manager created")
    print()
    
    print("🔧 Initializing (creating workers)...")
    try:
        await manager.initialize()
        print("✅ Initialization complete!")
        print()
    except Exception as e:
        print(f"❌ Initialization failed: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Get stats
    print("📊 Worker Statistics:")
    stats = manager.get_stats()
    print(f"   Total Workers: {stats['total_workers']}")
    print(f"   Healthy Workers: {stats['healthy_workers']}")
    print(f"   Unhealthy Workers: {stats['unhealthy_workers']}")
    print(f"   Total Requests: {stats['total_requests']}")
    print()
    
    if stats['workers']:
        print("👷 Worker Details:")
        for worker in stats['workers']:
            status = "✅" if worker['healthy'] else "❌"
            print(f"   {status} {worker['name']}")
            print(f"      URL: {worker['url']}")
            print(f"      Requests: {worker['total_requests']}")
            print(f"      Failures: {worker['failures']}")
        print()
    
    # Test getting a proxy URL
    print("🧪 Testing proxy URL generation...")
    target = "https://chat.z.ai/api/chat/completions"
    proxy_url = await manager.get_proxy_url(target)
    
    if proxy_url:
        print(f"✅ Got proxy URL:")
        print(f"   {proxy_url}")
        print()
        
        # Test the actual proxy
        print("🌐 Testing proxy request...")
        try:
            import httpx
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.get(proxy_url.replace(target, "https://httpbin.org/ip"))
                if response.status_code == 200:
                    data = response.json()
                    print(f"✅ Proxy works! Origin IP: {data.get('origin', 'unknown')}")
                    manager.mark_worker_success(proxy_url)
                else:
                    print(f"⚠️  Proxy returned status {response.status_code}")
                    manager.mark_worker_failure(proxy_url)
        except Exception as e:
            print(f"❌ Proxy test failed: {e}")
            manager.mark_worker_failure(proxy_url)
    else:
        print("❌ Could not get proxy URL")
    
    print()
    print("=" * 80)
    print("✅ Test Complete!")
    print("=" * 80)

if __name__ == "__main__":
    asyncio.run(main())
