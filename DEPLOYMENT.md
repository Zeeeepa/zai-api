# ZAI-API Deployment Guide

## ✅ Fully Tested & Working Setup

This project has been successfully tested and verified to work with Z.AI service.

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Zeeeepa/zai-api.git
```

### 2. Navigate to Project Directory

```bash
cd zai-api
```

### 3. Set Environment Variables

```bash
export ZAI_EMAIL="developer@pixelium.uk"
export ZAI_PASSWORD="developer123?"
export SERVER_PORT=7322
```

### 4. Run Complete Setup

```bash
bash scripts/all.sh
```

This will:
- ✅ Create virtual environment (.venv)
- ✅ Set up environment and validate tokens
- ✅ Start the OpenAI-compatible API server on port 7322
- ✅ Display available models and server port
- ✅ Run comprehensive API tests

**That's it! Your server is now running on `http://localhost:7322`** 🎯

## 📝 Available Scripts

### 1. `setup.sh` - Environment Setup & Token Validation
```bash
bash scripts/setup.sh
```
- Creates .env configuration
- Validates JWT tokens
- Installs Python dependencies
- Configures ZAI credentials

### 2. `start.sh` - Start API Server
```bash
bash scripts/start.sh
```
- Activates virtual environment (.venv)
- Starts server on port 7322 (configurable via SERVER_PORT env var)
- Displays server port and available models
- Performs health checks
- Validates all endpoints

### 3. `send_request.sh` - Test API
```bash
bash scripts/send_request.sh
```
- Runs comprehensive test suite
- Tests streaming and non-streaming responses
- Validates model mappings

### 4. `all.sh` - Complete Pipeline
```bash
bash scripts/all.sh
```
- Runs all scripts sequentially (setup → start → test)
- Complete deployment in one command

## 🔧 Configuration

### Port Configuration
Default: `7322`

To change:
```bash
export SERVER_PORT=8080
bash scripts/start.sh
```

Or edit `.env`:
```
LISTEN_PORT=8080
```

### Model Mapping
All unknown models automatically map to `GLM-4.6` (default).

Example:
- `gpt-4` → `GLM-4.6`
- `gpt-5` → `GLM-4.6`
- `claude-3` → `GLM-4.6`
- Any unknown model → `GLM-4.6`

## 💻 Usage Example

### Python OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",  # ✅ Any key works!
    base_url="http://localhost:7322/v1"
)

result = client.chat.completions.create(
    model="gpt-5",  # ✅ Any model works!
    messages=[{"role": "user", "content": "Write a haiku about code."}]
)

print(result.choices[0].message.content)
```

### cURL

```bash
curl http://localhost:7322/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any" \
  -d '{
    "model": "gpt-5",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## ✅ Test Results

**Tested on:** 2025-10-15

### Server Startup
```
✅ Virtual environment 'zai-api' activated
✅ Server started with PID: 1741
✅ Server is ready on http://localhost:7322
✅ Health check passed: {"status":"healthy"}
✅ SERVER_PORT: 7322
```

### API Tests
```
✅ Simple greeting test: PASSED
✅ Complex query test: PASSED
✅ Streaming response: PASSED
✅ Model mapping: gpt-5 → GLM-4.6 ✅

Available Models:
  - GLM-4.5
  - GLM-4.5-Thinking
  - GLM-4.5-Search
  - GLM-4.5-Air
  - GLM-4.5V
  - GLM-4.6
  - GLM-4.6-Thinking
  - GLM-4.6-Search
```

### Example Response
```
Logic takes its form,
Building worlds from simple lines,
The machine awakes.
```

## 🎯 Key Features

1. ✅ **OpenAI-Compatible API** - Works with any OpenAI SDK
2. ✅ **Flexible Authentication** - Any API key accepted (server uses internal token)
3. ✅ **Smart Model Mapping** - Unknown models → GLM-4.6 default
4. ✅ **Automatic Token Management** - Handles Z.AI authentication
5. ✅ **Comprehensive Health Checks** - Validates all components
6. ✅ **Production-Ready Scripts** - Complete deployment automation

## 🛠️ Server Management

### View Logs
```bash
tail -f server.log
```

### Stop Server
```bash
pkill -f 'python3 main.py'
```

### Restart Server
```bash
bash scripts/start.sh
```

### Check Health
```bash
curl http://localhost:7322/health
```

### Get Available Models
```bash
curl http://localhost:7322/v1/models
```

## 📊 Endpoints

- **Health Check:** `GET /health`
- **Models List:** `GET /v1/models`
- **Chat Completions:** `POST /v1/chat/completions`

## 🔒 Environment Variables

Required:
- `ZAI_EMAIL` - Your Z.AI email
- `ZAI_PASSWORD` - Your Z.AI password

Optional:
- `SERVER_PORT` - Server port (default: 7322)
- `LISTEN_PORT` - Server listen port (default: 7322, same as SERVER_PORT)
- `ZAI_TOKEN` - Pre-fetched JWT token (auto-fetched if not provided)

## 🎉 Success Indicators

When deployment is successful, you'll see:

```
================================================================
🎉 Server Started & Health Checks Complete!
================================================================

✅ All 7 health checks passed
✅ Server running on http://localhost:7322
✅ SERVER_PORT: 7322
✅ Ready to accept requests

Available Models:
  - GLM-4.5
  - GLM-4.5-Thinking
  - GLM-4.5-Search
  - GLM-4.5-Air
  - GLM-4.5V
  - GLM-4.6
  - GLM-4.6-Thinking
  - GLM-4.6-Search
```

## 💡 Troubleshooting

### Server won't start
1. Check if port 7322 is already in use: `lsof -i :7322`
2. Try a different port: `SERVER_PORT=8080 bash scripts/start.sh`
3. Check logs: `tail -f server.log`

### Authentication errors
1. Verify credentials: `echo $ZAI_EMAIL`
2. Re-fetch token: `bash scripts/fetch_token.sh`
3. Check token validity: `bash scripts/setup.sh`

### Connection refused
1. Ensure server is running: `curl http://localhost:7322/health`
2. Check server logs: `tail -f server.log`
3. Restart server: `bash scripts/start.sh`

## 🚀 All Systems Go!

This project is **production-ready** and fully tested with Z.AI service! 🎯💯🔥
