#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Main application entry point - OpenAI format conversion with FlareProx
"""

from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from src.config import settings
from src.openai_api import router as openai_router
from src.flareprox_manager import flareprox_manager
from src.helpers import info_log, debug_log

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    info_log("=" * 80)
    info_log("🚀 Starting OpenAI Compatible API Server")
    info_log("=" * 80)
    info_log("")
    
    # Show configuration
    info_log("📋 Configuration:")
    info_log(f"   Listen Port: {settings.LISTEN_PORT}")
    info_log(f"   API Endpoint: {settings.API_ENDPOINT}")
    info_log(f"   Auth Required: {'No (Accepts any key)' if not settings.SKIP_AUTH_TOKEN else 'Skipped'}")
    info_log(f"   Tool Calling: {'Enabled' if settings.ENABLE_TOOLIFY else 'Disabled'}")
    info_log(f"   Guest Token: {'Enabled' if settings.ENABLE_GUEST_TOKEN else 'Disabled'}")
    
    # Initialize FlareProx if enabled
    if settings.ENABLE_FLAREPROX:
        info_log("")
        info_log("🔄 Initializing FlareProx...")
        try:
            if flareprox_manager.enabled:
                await flareprox_manager.initialize()
                stats = flareprox_manager.get_stats()
                info_log(f"   ✅ FlareProx Ready: {stats['healthy_workers']}/{stats['total_workers']} workers")
            else:
                info_log("   ⚠️  FlareProx disabled (missing credentials)")
        except Exception as e:
            info_log(f"   ❌ FlareProx initialization failed: {e}")
    else:
        info_log(f"   FlareProx: Disabled")
    
    info_log("")
    info_log("=" * 80)
    info_log("✅ Server Ready!")
    info_log("=" * 80)
    
    yield
    
    # Shutdown
    info_log("🛑 Shutting down server...")

# Create FastAPI app with lifespan
app = FastAPI(
    title="OpenAI Compatible API Server",
    description="OpenAI-compatible API server for Z.AI chat service with FlareProx IP rotation",
    version="1.0.0-flareprox",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)

# Include API router
app.include_router(openai_router)


@app.options("/")
async def handle_options():
    """Handle OPTIONS requests"""
    return Response(status_code=200)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "OpenAI Compatible API Server with FlareProx",
        "version": "1.0.0-flareprox",
        "description": "OpenAI格式转换功能，含工具调用和FlareProx IP轮换",
        "features": {
            "openai_compatible": True,
            "tool_calling": settings.ENABLE_TOOLIFY,
            "guest_token": settings.ENABLE_GUEST_TOKEN,
            "flareprox": settings.ENABLE_FLAREPROX
        }
    }


@app.get("/health")
async def health():
    """Health check endpoint with FlareProx stats"""
    health_data = {
        "status": "healthy",
        "server": {
            "port": settings.LISTEN_PORT,
            "tool_calling": settings.ENABLE_TOOLIFY,
            "guest_token": settings.ENABLE_GUEST_TOKEN
        }
    }
    
    # Add FlareProx stats if enabled
    if settings.ENABLE_FLAREPROX and flareprox_manager and flareprox_manager.enabled:
        try:
            stats = flareprox_manager.get_stats()
            health_data["flareprox"] = {
                "enabled": True,
                "total_workers": stats["total_workers"],
                "healthy_workers": stats["healthy_workers"],
                "total_requests": stats["total_requests"]
            }
        except Exception as e:
            health_data["flareprox"] = {
                "enabled": True,
                "error": str(e)
            }
    else:
        health_data["flareprox"] = {"enabled": False}
    
    return health_data


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.LISTEN_PORT,
        reload=False,
    )
