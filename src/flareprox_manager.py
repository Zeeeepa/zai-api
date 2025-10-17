#!/usr/bin/env python3
"""
FlareProx Manager for ZAI-API
Dynamically creates and manages Cloudflare Worker proxies with load balancing
"""

import asyncio
import json
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


class FlareProxManager:
    """Manages Cloudflare Worker proxies with dynamic scaling and load balancing."""
    
    def __init__(self):
        self.api_token = settings.CLOUDFLARE_API_TOKEN
        self.account_id = settings.CLOUDFLARE_ACCOUNT_ID
        self.enabled = bool(self.api_token and self.account_id)
        
        self.workers: List[FlareProxWorker] = []
        self.max_workers = settings.FLAREPROX_MAX_WORKERS  # Default: 4 workers max
        self._current_index = 0  # For round-robin selection
        
        self.base_url = "https://api.cloudflare.com/client/v4"
        self.headers = {
            "Authorization": f"Bearer {self.api_token}",
            "Content-Type": "application/json"
        }
        
        self._account_subdomain = None
        self._last_worker_creation = 0  # Throttling: track last worker creation time
        
        if self.enabled:
            info_log("[FLAREPROX] ✅ FlareProx enabled - Workers will be created on-demand", 
                    max_workers=self.max_workers,
                    account_id=self.account_id[:8] + "...")
        else:
            info_log("[FLAREPROX] ℹ️  FlareProx disabled - using direct connection")
    
    async def initialize(self):
        """Initialize is now a no-op - workers created on-demand."""
        pass
    
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
    responseHeaders.set('X-FlareProx-Worker', 'WORKER_NAME_PLACEHOLDER')  // Will be replaced during deployment

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
        """Create a single Cloudflare Worker with throttling."""
        # Throttling: prevent creating workers too quickly (max 1 per 5 seconds)
        current_time = time.time()
        time_since_last = current_time - self._last_worker_creation
        if time_since_last < 5.0:
            wait_time = 5.0 - time_since_last
            debug_log(f"[FLAREPROX] Throttling worker creation - waiting {wait_time:.1f}s")
            await asyncio.sleep(wait_time)
        
        self._last_worker_creation = time.time()
        
        if not name:
            name = self._generate_worker_name()
        
        # Replace placeholder with actual worker name in script
        script_content = self._get_worker_script().replace('WORKER_NAME_PLACEHOLDER', name)
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
    

    
    async def get_worker(self) -> Optional[FlareProxWorker]:
        """Get next worker using simple round-robin. Creates workers on-demand."""
        if not self.enabled:
            return None
        
        # Create first worker if none exist (on-demand)
        if not self.workers:
            # Check throttling - don't spam worker creation
            current_time = time.time()
            if current_time - self._last_worker_creation < 5:
                debug_log("[FLAREPROX] Throttling worker creation (5s cooldown)")
                return None
            
            info_log("[FLAREPROX] Creating first worker on-demand...")
            self._last_worker_creation = current_time
            worker = await self._create_worker()
            if worker:
                self.workers.append(worker)
                info_log(f"[FLAREPROX] ✅ First worker created: {worker.name}")
            else:
                return None
        
        # Create additional workers if under max (on-demand scaling)
        elif len(self.workers) < self.max_workers:
            current_time = time.time()
            if current_time - self._last_worker_creation >= 5:  # 5-second throttle
                info_log(f"[FLAREPROX] Creating worker #{len(self.workers) + 1} (max: {self.max_workers})...")
                self._last_worker_creation = current_time
                worker = await self._create_worker()
                if worker:
                    self.workers.append(worker)
                    info_log(f"[FLAREPROX] ✅ Worker created: {worker.name} (total: {len(self.workers)})")
        
        # Simple round-robin selection
        worker = self.workers[self._current_index % len(self.workers)]
        self._current_index += 1
        
        return worker
    
    async def get_proxy_url(self, target_url: str) -> Optional[str]:
        """Get a proxied URL for the target. Creates workers on-demand."""
        if not self.enabled:
            return None
        
        # Create first worker if none exist
        if not self.workers:
            info_log("[FLAREPROX] Creating first worker on-demand...")
            worker = await self._create_worker()
            if worker:
                self.workers.append(worker)
                info_log(f"[FLAREPROX] ✅ First worker created: {worker.name}")
        
        # Create additional workers if under max (on-demand scaling)
        elif len(self.workers) < self.max_workers:
            # Create new worker for load distribution
            info_log(f"[FLAREPROX] Creating worker #{len(self.workers) + 1} (max: {self.max_workers})...")
            worker = await self._create_worker()
            if worker:
                self.workers.append(worker)
                info_log(f"[FLAREPROX] ✅ Worker created: {worker.name} (total: {len(self.workers)})")
        
        # Get next worker (round-robin)
        worker = self.get_worker()
        if not worker:
            return None
        
        # Return proxy URL
        proxy_url = f"{worker.url}?url={target_url}"
        info_log(f"[FLAREPROX] Using worker: {worker.name}")
        return proxy_url
    

    
    def get_stats(self) -> Dict:
        """Get simple worker statistics."""
        if not self.enabled:
            return {"enabled": False}
        
        return {
            "enabled": True,
            "worker_count": len(self.workers),
            "max_workers": self.max_workers,
            "workers": [w.name for w in self.workers]
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
