#!/usr/bin/env python3
"""
FlareProx Manager for ZAI-API
Dynamically creates and manages Cloudflare Worker proxies with load balancing
"""

import asyncio
import json
import random
import time
from typing import Dict, List, Optional
import httpx

# Support both relative and absolute imports
try:
    from .config import settings
    from .helpers import info_log, error_log, debug_log
except ImportError:
    from config import settings
    from helpers import info_log, error_log, debug_log


class FlareProxWorker:
    """Represents a single Cloudflare Worker proxy endpoint."""
    
    def __init__(self, name: str, url: str, created_at: str):
        self.name = name
        self.url = url
        self.created_at = created_at
        self.failures = 0
        self.last_used = 0
        self.total_requests = 0
        self.is_healthy = True
    
    def mark_success(self):
        """Mark a successful request."""
        self.failures = 0
        self.last_used = time.time()
        self.total_requests += 1
        self.is_healthy = True
    
    def mark_failure(self):
        """Mark a failed request."""
        self.failures += 1
        self.last_used = time.time()
        if self.failures >= 3:
            self.is_healthy = False
            error_log(f"[FLAREPROX] Worker {self.name} marked unhealthy after {self.failures} failures")
    
    def reset_health(self):
        """Reset health status."""
        self.failures = 0
        self.is_healthy = True
        info_log(f"[FLAREPROX] Worker {self.name} health reset")


class FlareProxManager:
    """Manages Cloudflare Worker proxies with dynamic scaling and load balancing."""
    
    def __init__(self):
        self.api_token = settings.CLOUDFLARE_API_TOKEN
        self.account_id = settings.CLOUDFLARE_ACCOUNT_ID
        self.enabled = bool(self.api_token and self.account_id)
        
        self.workers: List[FlareProxWorker] = []
        self.min_workers = 2  # Minimum number of workers to maintain
        self.max_workers = 10  # Maximum number of workers
        self.target_workers = 3  # Target number of workers
        
        self.base_url = "https://api.cloudflare.com/client/v4"
        self.headers = {
            "Authorization": f"Bearer {self.api_token}",
            "Content-Type": "application/json"
        }
        
        self._account_subdomain = None
        self._init_lock = asyncio.Lock()
        self._initialized = False
        
        if self.enabled:
            info_log("[FLAREPROX] Manager initialized", 
                    account_id=self.account_id[:8] + "...",
                    min_workers=self.min_workers,
                    target_workers=self.target_workers)
        else:
            debug_log("[FLAREPROX] Manager disabled (no credentials)")
    
    async def initialize(self):
        """Initialize the FlareProx manager by syncing existing workers."""
        if not self.enabled:
            return
        
        async with self._init_lock:
            if self._initialized:
                return
            
            info_log("[FLAREPROX] Initializing manager...")
            
            # Sync existing workers
            await self._sync_workers()
            
            # Ensure we have minimum workers
            if len(self.workers) < self.min_workers:
                needed = self.min_workers - len(self.workers)
                info_log(f"[FLAREPROX] Creating {needed} initial workers...")
                await self._create_workers(needed)
            
            self._initialized = True
            info_log(f"[FLAREPROX] Manager ready with {len(self.workers)} workers")
    
    @property
    async def worker_subdomain(self) -> str:
        """Get the worker subdomain for workers.dev URLs."""
        if self._account_subdomain:
            return self._account_subdomain
        
        url = f"{self.base_url}/accounts/{self.account_id}/workers/subdomain"
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, headers=self.headers, timeout=30)
                if response.status_code == 200:
                    data = response.json()
                    subdomain = data.get("result", {}).get("subdomain")
                    if subdomain:
                        self._account_subdomain = subdomain
                        return subdomain
        except Exception as e:
            debug_log(f"[FLAREPROX] Could not get subdomain: {e}")
        
        # Fallback
        self._account_subdomain = self.account_id.lower()
        return self._account_subdomain
    
    def _generate_worker_name(self) -> str:
        """Generate a unique worker name."""
        import string
        timestamp = str(int(time.time()))
        random_suffix = ''.join(random.choices(string.ascii_lowercase, k=6))
        return f"zai-proxy-{timestamp}-{random_suffix}"
    
    def _get_worker_script(self) -> str:
        """Return the Cloudflare Worker script."""
        return '''addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  try {
    const url = new URL(request.url)
    const targetUrl = getTargetUrl(url, request.headers)

    if (!targetUrl) {
      return new Response(JSON.stringify({error: 'No target URL specified'}), {
        status: 400,
        headers: {'Content-Type': 'application/json'}
      })
    }

    const targetURL = new URL(targetUrl)
    const targetParams = new URLSearchParams()
    for (const [key, value] of url.searchParams) {
      if (!['url', '_cb', '_t'].includes(key)) {
        targetParams.append(key, value)
      }
    }
    if (targetParams.toString()) {
      targetURL.search = targetParams.toString()
    }

    const proxyHeaders = new Headers()
    const allowedHeaders = [
      'accept', 'accept-language', 'accept-encoding', 'authorization',
      'cache-control', 'content-type', 'origin', 'referer', 'user-agent',
      'x-fe-version', 'sec-fetch-dest', 'sec-fetch-mode', 'sec-fetch-site'
    ]

    for (const [key, value] of request.headers) {
      if (allowedHeaders.includes(key.toLowerCase())) {
        proxyHeaders.set(key, value)
      }
    }

    proxyHeaders.set('Host', targetURL.hostname)
    const customXForwardedFor = request.headers.get('X-My-X-Forwarded-For')
    if (customXForwardedFor) {
      proxyHeaders.set('X-Forwarded-For', customXForwardedFor)
    } else {
      proxyHeaders.set('X-Forwarded-For', generateRandomIP())
    }

    const proxyRequest = new Request(targetURL.toString(), {
      method: request.method,
      headers: proxyHeaders,
      body: ['GET', 'HEAD'].includes(request.method) ? null : request.body
    })

    const response = await fetch(proxyRequest)
    const responseHeaders = new Headers()

    for (const [key, value] of response.headers) {
      if (!['content-encoding', 'content-length', 'transfer-encoding'].includes(key.toLowerCase())) {
        responseHeaders.set(key, value)
      }
    }

    responseHeaders.set('Access-Control-Allow-Origin', '*')
    responseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD')
    responseHeaders.set('Access-Control-Allow-Headers', '*')

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: responseHeaders })
    }

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: responseHeaders
    })

  } catch (error) {
    return new Response(JSON.stringify({error: error.message}), {
      status: 500,
      headers: {'Content-Type': 'application/json'}
    })
  }
}

function getTargetUrl(url, headers) {
  let targetUrl = url.searchParams.get('url')
  if (!targetUrl) targetUrl = headers.get('X-Target-URL')
  if (!targetUrl && url.pathname !== '/') {
    const pathUrl = url.pathname.slice(1)
    if (pathUrl.startsWith('http')) targetUrl = pathUrl
  }
  return targetUrl
}

function generateRandomIP() {
  return [1,2,3,4].map(() => Math.floor(Math.random() * 255) + 1).join('.')
}'''
    
    async def _create_worker(self, name: Optional[str] = None) -> Optional[FlareProxWorker]:
        """Create a single Cloudflare Worker."""
        if not name:
            name = self._generate_worker_name()
        
        script_content = self._get_worker_script()
        url = f"{self.base_url}/accounts/{self.account_id}/workers/scripts/{name}"
        
        files = {
            'metadata': (None, json.dumps({
                "body_part": "script",
                "main_module": "worker.js"
            })),
            'script': ('worker.js', script_content, 'application/javascript')
        }
        
        headers = {"Authorization": f"Bearer {self.api_token}"}
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.put(url, headers=headers, files=files, timeout=60)
                response.raise_for_status()
            
            # Enable subdomain
            subdomain = await self.worker_subdomain
            subdomain_url = f"{self.base_url}/accounts/{self.account_id}/workers/scripts/{name}/subdomain"
            try:
                async with httpx.AsyncClient() as client:
                    await client.post(subdomain_url, headers=self.headers, json={"enabled": True}, timeout=30)
            except:
                pass
            
            worker_url = f"https://{name}.{subdomain}.workers.dev"
            worker = FlareProxWorker(name, worker_url, time.strftime('%Y-%m-%d %H:%M:%S'))
            
            info_log(f"[FLAREPROX] Created worker", name=name, url=worker_url)
            return worker
            
        except Exception as e:
            error_log(f"[FLAREPROX] Failed to create worker: {e}")
            return None
    
    async def _create_workers(self, count: int) -> List[FlareProxWorker]:
        """Create multiple workers concurrently."""
        tasks = [self._create_worker() for _ in range(count)]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        workers = []
        for result in results:
            if isinstance(result, FlareProxWorker):
                workers.append(result)
                self.workers.append(result)
        
        return workers
    
    async def _sync_workers(self):
        """Sync workers from Cloudflare."""
        url = f"{self.base_url}/accounts/{self.account_id}/workers/scripts"
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, headers=self.headers, timeout=30)
                response.raise_for_status()
            
            data = response.json()
            subdomain = await self.worker_subdomain
            synced_count = 0
            
            for script in data.get("result", []):
                name = script.get("id", "")
                if name.startswith("zai-proxy-"):
                    url = f"https://{name}.{subdomain}.workers.dev"
                    created_at = script.get("created_on", "unknown")
                    
                    # Check if already in list
                    if not any(w.name == name for w in self.workers):
                        worker = FlareProxWorker(name, url, created_at)
                        self.workers.append(worker)
                        synced_count += 1
            
            if synced_count > 0:
                info_log(f"[FLAREPROX] Synced {synced_count} existing workers")
                
        except Exception as e:
            error_log(f"[FLAREPROX] Failed to sync workers: {e}")
    
    def get_worker(self) -> Optional[FlareProxWorker]:
        """Get a healthy worker using weighted random selection (less used = higher chance)."""
        if not self.workers:
            return None
        
        # Filter healthy workers
        healthy_workers = [w for w in self.workers if w.is_healthy]
        
        if not healthy_workers:
            # All workers unhealthy, reset and try again
            info_log("[FLAREPROX] All workers unhealthy, resetting health status")
            for worker in self.workers:
                worker.reset_health()
            healthy_workers = self.workers
        
        # Weighted random selection (less used = higher weight)
        max_requests = max(w.total_requests for w in healthy_workers) + 1
        weights = [max_requests - w.total_requests + 1 for w in healthy_workers]
        
        return random.choices(healthy_workers, weights=weights)[0]
    
    async def get_proxy_url(self, target_url: str) -> Optional[str]:
        """Get a proxied URL for the target."""
        if not self.enabled:
            return None
        
        # Ensure initialized
        if not self._initialized:
            await self.initialize()
        
        worker = self.get_worker()
        if not worker:
            # Try to create emergency worker
            info_log("[FLAREPROX] No workers available, creating emergency worker")
            worker = await self._create_worker()
            if worker:
                self.workers.append(worker)
        
        if not worker:
            return None
        
        # Return proxy URL
        proxy_url = f"{worker.url}?url={target_url}"
        debug_log(f"[FLAREPROX] Selected worker", worker=worker.name, total_requests=worker.total_requests)
        return proxy_url
    
    def mark_worker_success(self, worker_url: str):
        """Mark a worker as successful."""
        for worker in self.workers:
            if worker.url in worker_url:
                worker.mark_success()
                break
    
    def mark_worker_failure(self, worker_url: str):
        """Mark a worker as failed."""
        for worker in self.workers:
            if worker.url in worker_url:
                worker.mark_failure()
                break
    
    async def scale_workers(self):
        """Scale workers based on load and health."""
        if not self.enabled or not self._initialized:
            return
        
        healthy_count = sum(1 for w in self.workers if w.is_healthy)
        
        # Scale up if below target
        if healthy_count < self.target_workers and len(self.workers) < self.max_workers:
            needed = min(self.target_workers - healthy_count, self.max_workers - len(self.workers))
            info_log(f"[FLAREPROX] Scaling up: creating {needed} workers")
            await self._create_workers(needed)
        
        # Scale down if too many unhealthy
        unhealthy_count = len(self.workers) - healthy_count
        if unhealthy_count > 3 and len(self.workers) > self.min_workers:
            # Remove oldest unhealthy workers
            unhealthy_workers = sorted(
                [w for w in self.workers if not w.is_healthy],
                key=lambda w: w.last_used
            )
            
            to_remove = unhealthy_workers[:unhealthy_count - 1]
            for worker in to_remove:
                info_log(f"[FLAREPROX] Removing unhealthy worker: {worker.name}")
                await self._delete_worker(worker)
                self.workers.remove(worker)
    
    async def _delete_worker(self, worker: FlareProxWorker):
        """Delete a worker from Cloudflare."""
        url = f"{self.base_url}/accounts/{self.account_id}/workers/scripts/{worker.name}"
        try:
            async with httpx.AsyncClient() as client:
                await client.delete(url, headers=self.headers, timeout=30)
            debug_log(f"[FLAREPROX] Deleted worker: {worker.name}")
        except Exception as e:
            debug_log(f"[FLAREPROX] Failed to delete worker {worker.name}: {e}")
    
    def get_stats(self) -> Dict:
        """Get worker statistics."""
        if not self.enabled:
            return {"enabled": False}
        
        healthy = [w for w in self.workers if w.is_healthy]
        return {
            "enabled": True,
            "total_workers": len(self.workers),
            "healthy_workers": len(healthy),
            "unhealthy_workers": len(self.workers) - len(healthy),
            "total_requests": sum(w.total_requests for w in self.workers),
            "workers": [
                {
                    "name": w.name,
                    "url": w.url,
                    "healthy": w.is_healthy,
                    "failures": w.failures,
                    "total_requests": w.total_requests
                }
                for w in self.workers
            ]
        }


# Global instance
_flareprox_manager: Optional[FlareProxManager] = None


async def get_flareprox_manager() -> FlareProxManager:
    """Get or create the global FlareProx manager."""
    global _flareprox_manager
    
    if _flareprox_manager is None:
        _flareprox_manager = FlareProxManager()
        await _flareprox_manager.initialize()
    
    return _flareprox_manager
