# ZAI-API Scripts

**Streamlined deployment scripts - Everything you need in 4 files**

---

## 📁 Scripts Overview

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup.sh` | Complete environment setup | `bash scripts/setup.sh` |
| `start.sh` | Start API server | `bash scripts/start.sh` |
| `send_request.sh` | Test API functionality | `bash scripts/send_request.sh` |
| `all.sh` | **Run everything** | `bash scripts/all.sh` |

---

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/Zeeeepa/zai-api.git
cd zai-api

# Set configuration (optional)
export SERVER_PORT=7555
export CLOUDFLARE_API_TOKEN=your_token    # Optional for FlareProx
export CLOUDFLARE_ACCOUNT_ID=your_id      # Optional for FlareProx

# Run complete pipeline
bash scripts/all.sh
```

**That's it!** Server starts, tests run, everything works.

---

## 📝 Detailed Script Documentation

### 1. `setup.sh` - Environment Setup

**What it does:**
- ✅ Creates Python virtual environment (`.venv`)
- ✅ Installs all dependencies
- ✅ Creates/validates `.env` configuration
- ✅ Configures authentication (token or anonymous)
- ✅ Sets up FlareProx integration (optional)
- ✅ Validates configuration

**Usage:**
```bash
bash scripts/setup.sh
```

**Features:**
- Automatic virtual environment migration from legacy paths
- Interactive token configuration
- FlareProx Cloudflare Workers deployment
- Comprehensive validation checks

**Environment Variables:**
- `SERVER_PORT` - Server port (default: 8080)
- `ZAI_TOKEN` - Your Z.AI token (optional, uses anonymous mode if not set)
- `ENABLE_FLAREPROX` - Enable proxy rotation (default: false)
- `CLOUDFLARE_API_TOKEN` - For FlareProx integration
- `CLOUDFLARE_ACCOUNT_ID` - For FlareProx integration

---

### 2. `start.sh` - Start Server

**What it does:**
- ✅ Activates virtual environment
- ✅ Checks for port conflicts
- ✅ Launches API server
- ✅ Performs health checks
- ✅ Validates all endpoints
- ✅ Displays server information

**Usage:**
```bash
bash scripts/start.sh
```

**Features:**
- Smart server conflict detection
- Automatic health validation
- Available models display
- Comprehensive server info

**Server Endpoints:**
- Health: `http://localhost:$SERVER_PORT/health`
- Models: `http://localhost:$SERVER_PORT/v1/models`
- Chat: `http://localhost:$SERVER_PORT/v1/chat/completions`

---

### 3. `send_request.sh` - Test API

**What it does:**
- ✅ Checks server availability
- ✅ Runs non-streaming test
- ✅ Runs streaming test
- ✅ Lists available models
- ✅ Validates API responses

**Usage:**
```bash
# Default test
bash scripts/send_request.sh

# Custom question
bash scripts/send_request.sh "Your question here"
```

**Tests Performed:**
1. **Non-streaming request** - Full response validation
2. **Streaming request** - Real-time response chunks
3. **Model listing** - Available models check

**Example Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test 1: Non-Streaming Request
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Status: Success
📝 Model: GLM-4.6
🔢 Tokens: 45

💬 Response:
Logic takes its form,
Building worlds from simple lines,
The machine awakes.
```

---

### 4. `all.sh` - Complete Pipeline

**What it does:**
- ✅ Runs `setup.sh` (environment)
- ✅ Runs `start.sh` (server)
- ✅ Runs `send_request.sh` (tests)
- ✅ Displays summary and usage guide

**Usage:**
```bash
bash scripts/all.sh
```

**Pipeline Flow:**
```
Step 1/3: Environment Setup & Configuration
  ↓
Step 2/3: Start API Server
  ↓
Step 3/3: Run API Tests
  ↓
🎉 Pipeline Complete!
```

**What You Get:**
- Complete deployment in one command
- Comprehensive validation
- Ready-to-use API server
- Usage examples and documentation

---

## 🔧 Configuration

### Environment Variables

Set these **before** running scripts:

```bash
# Server Configuration
export SERVER_PORT=7555              # Default: 8080

# Authentication (Optional)
export ZAI_TOKEN=your_token_here     # Uses anonymous mode if not set

# FlareProx Integration (Optional)
export ENABLE_FLAREPROX=true
export CLOUDFLARE_API_TOKEN=your_token
export CLOUDFLARE_ACCOUNT_ID=your_account_id
```

### Configuration File

All settings are stored in `.env`:

```env
# Server
LISTEN_PORT=8080
AUTH_TOKEN=sk-123456

# Authentication
ZAI_TOKEN=your_token_here         # Optional

# Features
ENABLE_GUEST_TOKEN=true           # Anonymous mode
ENABLE_TOOLIFY=true               # Function calling
DEBUG_LOGGING=false               # Verbose logs

# FlareProx (Optional)
ENABLE_FLAREPROX=false
CLOUDFLARE_API_TOKEN=your_token
CLOUDFLARE_ACCOUNT_ID=your_id
```

---

## 📊 Common Workflows

### First Time Setup

```bash
git clone https://github.com/Zeeeepa/zai-api.git
cd zai-api
bash scripts/all.sh
```

### Update & Restart

```bash
git pull origin main
bash scripts/setup.sh    # Reinstall dependencies
bash scripts/start.sh    # Restart server
```

### Development Workflow

```bash
# Make code changes
# ...

# Test changes
bash scripts/start.sh        # Start server
bash scripts/send_request.sh # Validate
```

### Production Deployment

```bash
# Set production port
export SERVER_PORT=8080

# Configure authentication
export ZAI_TOKEN=production_token

# Deploy
bash scripts/all.sh
```

---

## 🐛 Troubleshooting

### Server Won't Start

```bash
# Check if port is in use
lsof -i :8080

# Kill existing process
pkill -f 'python3 main.py'

# Restart
bash scripts/start.sh
```

### Dependencies Issue

```bash
# Reinstall everything
rm -rf .venv
bash scripts/setup.sh
```

### Token Not Working

```bash
# Use anonymous mode
# Just remove or comment out ZAI_TOKEN in .env

# Or get new token from https://chat.z.ai
# DevTools → Application → Local Storage → token
```

### View Logs

```bash
# Live logs
tail -f server.log

# All logs
cat server.log
```

---

## 💡 Tips & Best Practices

### 1. Use Anonymous Mode for Testing

No need to configure tokens for quick tests:

```bash
# Don't set ZAI_TOKEN - just run
bash scripts/all.sh
```

### 2. Configure Port for Multiple Instances

```bash
export SERVER_PORT=7555
bash scripts/all.sh
```

### 3. Enable FlareProx for Production

```bash
export ENABLE_FLAREPROX=true
export CLOUDFLARE_API_TOKEN=your_token
export CLOUDFLARE_ACCOUNT_ID=your_id
bash scripts/setup.sh
```

### 4. Check Server Status

```bash
curl http://localhost:8080/health
```

### 5. Stop Server Cleanly

```bash
kill $(cat .server.pid)
```

---

## 🎯 What Each Script Does NOT Do

To keep scripts simple and focused:

- **setup.sh** - Doesn't start the server
- **start.sh** - Doesn't install dependencies
- **send_request.sh** - Doesn't start the server
- **all.sh** - Just orchestrates the other three

**Design Philosophy:** Each script does one thing well, `all.sh` combines them.

---

## 📚 Related Documentation

- [Complete Documentation](../DOCUMENTATION.md) - Full guide
- [README](../README.md) - Project overview
- [Environment Template](../env_template.txt) - Configuration reference

---

## 🔄 Migration from Old Scripts

If you used the old script structure (10 scripts), everything is now consolidated:

| Old Script | New Location |
|------------|--------------|
| `fetch_token.sh` | Integrated into `setup.sh` |
| `get_token_from_browser.sh` | Integrated into `setup.sh` |
| `deploy_zai_api_server.sh` | Integrated into `setup.sh` |
| `integrate_flareprox.sh` | Integrated into `setup.sh` |
| `validate_scripts.sh` | Tests in `send_request.sh` |

**Same functionality, simpler structure.** 🎉

---

## ✨ Summary

**Four scripts. That's all you need.**

1. `setup.sh` - Get ready
2. `start.sh` - Run server
3. `send_request.sh` - Validate
4. `all.sh` - Do everything

**Simple. Clean. Effective.**

---

**Made with ❤️ by the Zeeeepa team**

