# 🚀 Enhanced Server Startup Guide

This guide covers the improved startup scripts with comprehensive status monitoring and API testing.

## Quick Start

### Method 1: Enhanced Startup Script (Recommended)

The new `start_server.sh` provides comprehensive monitoring and automatic testing:

```bash
# From project root
bash scripts/start_server.sh
```

**What it does:**
- ✅ Checks for existing server instances
- ✅ Activates virtual environment automatically
- ✅ Displays full configuration summary
- ✅ Starts server with health monitoring
- ✅ Runs automatic API test
- ✅ Shows FlareProx worker status
- ✅ Provides usage examples and management commands

**Output includes:**
- Configuration details (API endpoint, port, auth mode)
- FlareProx status (workers, account)
- Real-time health check results
- API test with actual response
- Python/curl usage examples
- Management commands

### Method 2: Complete Pipeline (Setup + Start)

For first-time setup or when dependencies need updating:

```bash
# Run complete setup
bash scripts/all.sh

# Then start with enhanced script
bash scripts/start_server.sh
```

### Method 3: Direct Start

For quick restarts when everything is already configured:

```bash
# Activate environment
source .venv/bin/activate

# Start server
python3 main.py
```

## What the Enhanced Startup Shows

### Configuration Summary
```
📋 Configuration
================

API Endpoint:
   https://chat.z.ai/api/chat/completions

Listen Port:
   8080

Authentication:
   Any key accepted (guest mode)

FlareProx IP Rotation:
   Enabled
   Account: 2b2a1d3e...81e3

Features:
   ✅ Guest Tokens
   ✅ Tool Calling
```

### Health Check
```
🏥 Health Check
================

✅ Server is healthy

Health Status:
   {
       "status": "healthy",
       "server": {
           "port": 8080,
           "tool_calling": true,
           "guest_token": true
       },
       "flareprox": {
           "enabled": true,
           "total_workers": 2,
           "healthy_workers": 2,
           "total_requests": 0
       }
   }

   FlareProx: 2/2 workers active
```

### API Test
```
🧪 API Test
============

Sending test request...
Model: GLM-4.5
Question: What is 2+2?

✅ API Test Successful!

Response:
   Answer: 4
   Tokens: 43

Full Response:
   {
       "id": "...",
       "model": "GLM-4.5",
       "choices": [...],
       "usage": {...}
   }
```

### Connection Details
```
📊 Server Information
======================

✅ Server is running successfully!

Connection Details:
   Base URL: http://localhost:8080
   API Endpoint: http://localhost:8080/v1/chat/completions
   Health Check: http://localhost:8080/health

Example Usage:

   # Python
   from openai import OpenAI
   client = OpenAI(base_url='http://localhost:8080/v1', api_key='any-key')
   response = client.chat.completions.create(model='GLM-4.5', messages=[...])

   # curl
   curl http://localhost:8080/v1/chat/completions \
     -H "Authorization: Bearer your-key" \
     -H "Content-Type: application/json" \
     -d '{"model":"GLM-4.5","messages":[{"role":"user","content":"Hello"}]}'

Management:
   View logs: tail -f server.log
   Stop server: kill <PID> || pkill -f 'python3 main.py'
   Restart: bash scripts/start_server.sh
```

## Configuration Options

### Authentication Modes

**Accept Any Key (Default):**
```bash
# In .env - no AUTH_TOKEN set
SKIP_AUTH_TOKEN=false

# Server will accept any API key
# Perfect for development and testing
```

**Required Token:**
```bash
# In .env - set AUTH_TOKEN
AUTH_TOKEN=sk-your-custom-key
SKIP_AUTH_TOKEN=false

# Server will only accept this specific key
# Recommended for production
```

### FlareProx IP Rotation

**Enabled (with credentials):**
```bash
# In .env
ENABLE_FLAREPROX=true
CLOUDFLARE_API_TOKEN=your_token
CLOUDFLARE_ACCOUNT_ID=your_account_id
```

**Disabled:**
```bash
# In .env
ENABLE_FLAREPROX=false
```

## Setup Script Improvements

The updated `setup.sh` now:

### ✅ Supports Optional AUTH_TOKEN
- No longer requires AUTH_TOKEN to be set
- Shows appropriate warning for guest mode
- Validates API_ENDPOINT only (required field)

### ✅ FlareProx Validation
- Checks if FlareProx is enabled
- Validates Cloudflare credentials
- Warns if credentials are missing

### ✅ Better Status Messages
```bash
Step 5/7: Checking configuration...
✅ API_ENDPOINT configured: https://chat.z.ai/api/chat/completions
ℹ️  No AUTH_TOKEN configured
   Authentication mode: Any key accepted (guest mode)
✅ FlareProx enabled
   Cloudflare credentials configured
```

## Troubleshooting

### Server Won't Start

**Check logs:**
```bash
tail -f server.log
```

**Common issues:**
- Port already in use (change `LISTEN_PORT` in .env)
- Missing dependencies (run `pip install -r requirements.txt`)
- Invalid .env configuration

### FlareProx Not Working

**Verify Cloudflare credentials:**
```bash
curl "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Check health endpoint:**
```bash
curl http://localhost:8080/health | jq .flareprox
```

### API Requests Failing

**401 Unauthorized:**
- Z.AI guest token may have expired
- Try with a real Z.AI account token in `AUTH_TOKEN`

**Connection refused:**
- Server not running
- Check if port 8080 is accessible
- Verify firewall settings

## Features Comparison

| Feature | setup.sh + all.sh | start_server.sh | Direct Start |
|---------|------------------|-----------------|--------------|
| First-time setup | ✅ | ❌ | ❌ |
| Dependency install | ✅ | ❌ | ❌ |
| Health monitoring | ❌ | ✅ | ❌ |
| API testing | ❌ | ✅ | ❌ |
| Status display | Basic | Comprehensive | None |
| Usage examples | ❌ | ✅ | ❌ |
| FlareProx status | ❌ | ✅ | ❌ |
| Management commands | ❌ | ✅ | ❌ |

## Recommended Workflow

### Development
```bash
# First time
bash scripts/all.sh

# Daily restarts
bash scripts/start_server.sh
```

### Production
```bash
# Setup once
bash scripts/all.sh

# Use systemd or docker-compose for management
# See main README for production deployment
```

### Testing
```bash
# Quick start for testing
source .venv/bin/activate
python3 main.py

# Check specific features
curl http://localhost:8080/health
```

## Next Steps

- Check [README_FLAREPROX.md](README_FLAREPROX.md) for FlareProx configuration
- See [QUICK_START.md](QUICK_START.md) for general usage
- Review [README.md](README.md) for API documentation

---

🎉 **Your server is now easier to start and monitor than ever before!**

