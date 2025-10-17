# ZAI-API Complete Documentation

**完整的 OpenAI 兼容 API 服务器文档**

---

## 📑 Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Deployment Guide](#deployment-guide)
6. [FlareProx Integration](#flareprox-integration)
7. [API Usage](#api-usage)
8. [Tool Calling (Function Calling)](#tool-calling-function-calling)
9. [Testing](#testing)
10. [Migration Guide](#migration-guide)
11. [Compatibility](#compatibility)
12. [Troubleshooting](#troubleshooting)
13. [Changelog](#changelog)

---

## Overview

**ZAI-API** 是一个完全兼容 OpenAI API 格式的代理服务器，将 OpenAI 格式的请求转换为 Z.AI API 调用，支持完整的工具调用（Function Calling）功能。

### 功能特性

#### 核心功能

- **OpenAI 格式兼容**：完全兼容 OpenAI API 请求和响应格式
- **Z.AI 后端集成**：自动转换并调用 Z.AI API
- **多模型支持**：支持 GLM-4.5、GLM-4.6、Thinking、Search、Air 等多个模型
- **流式和非流式**：同时支持流式（SSE）和非流式响应模式
- **匿名Token支持**：无需Z.AI账号，自动获取临时匿名Token，零配置部署
- **智能Token降级**：配置Token → 匿名Token → 缓存Token 三级降级策略
- **Claude Code支持**：支持通过Claude Code Router接入到CC中
- **Code插件支持**：支持Cline、Roo Code、Kilo Code等第三方插件

#### 工具调用（Function Calling）

- **标准 OpenAI 工具调用**：完全兼容 OpenAI 的 tools 和 tool_choice 参数
- **多函数并行调用**：支持在一次响应中调用多个函数
- **智能 XML 解析**：自动检测和解析模型响应中的工具调用
- **流式实时检测**：在流式模式下实时检测工具调用触发
- **Think 标签过滤**：智能过滤思考过程，只返回工具调用结果
- **自定义提示词**：支持自定义工具调用提示词模板

#### 其他功能

- **健康检查**：提供 `/health` 端点用于服务监控
- **CORS 支持**：内置跨域支持，方便前端集成
- **代理配置**：支持 HTTP/HTTPS 代理
- **Token 认证**：支持 API Key 认证和跳过认证选项
- **智能Token缓存**：30分钟缓存策略，减少API调用频率
- **重试机制**：请求失败自动重试
- **详细日志**：可配置的详细日志输出

### 支持的模型

| 模型名称         | Z.AI 后端模型  | 说明                     |
| ---------------- | -------------- | ----------------------- |
| GLM-4.5          | 0727-360B-API  | 主模型                   |
| GLM-4.5-Thinking | 0727-360B-API  | 思考模型                 |
| GLM-4.5-Search   | 0727-360B-API  | 搜索模型                 |
| GLM-4.5-Air      | 0727-106B-API  | 轻量级模型               |
| GLM-4.5V         | glm-4.5v       | 视觉模型                 |
| GLM-4.6          | GLM-4-6-API-V1 | 4.6 版本                 |
| GLM-4.6-Thinking | GLM-4-6-API-V1 | 4.6 思考版本             |
| GLM-4.6-Search   | GLM-4-6-API-V1 | 4.6 搜索版本             |

> **所有模型均支持图像上传**

---

## Quick Start

### 🚀 The Simplest Way - Just Run It!

```bash
# 1. Clone the repository
git clone https://github.com/Zeeeepa/zai-api.git
cd zai-api

# 2. Run everything
bash scripts/all.sh
```

**That's it!** The system will:
1. ✅ Create .env from template
2. ✅ Use anonymous/guest tokens automatically (no login needed!)
3. ✅ Start the OpenAI-compatible API server
4. ✅ Run a test request to verify everything works

### 🔐 Want Authenticated Mode? (Optional)

If you want to use your own Z.AI account instead of guest mode:

#### Step 1: Get Your Token from Browser

1. Open https://chat.z.ai in your browser
2. Login with your email and password
3. Open Developer Tools (F12 or Ctrl+Shift+I)
4. Go to 'Application' tab → 'Local Storage' → 'https://chat.z.ai'
5. Find 'token' key and copy its value

**OR** use this JavaScript in Console:
```javascript
localStorage.getItem('token')
```

#### Step 2: Save Token

Run the interactive token setup script:
```bash
bash scripts/get_token_from_browser.sh
```

It will prompt you to paste your token, then save it to .env automatically!

#### Step 3: Start Server

```bash
bash scripts/all.sh
```

### 📋 What Happens Behind the Scenes

#### Anonymous Mode (Default):
```
bash scripts/all.sh
     ↓
setup.sh creates .env
     ↓
start.sh starts server
     ↓
Server automatically fetches guest tokens as needed
     ↓
send_request.sh tests the API
     ↓
Done! 🎉
```

#### Authenticated Mode (With Your Token):
```
get_token_from_browser.sh (saves your token)
     ↓
bash scripts/all.sh
     ↓
Server uses your token for all requests
     ↓
Done! 🎉
```

### 🔐 Anonymous vs Authenticated Mode

#### Anonymous Mode (Default):
✅ **No login required**  
✅ **Works immediately**  
✅ **Great for testing**  
⚠️ **Limited features** - Some advanced features may be restricted

#### Authenticated Mode:
✅ **Full features**  
✅ **Your own account**  
✅ **No restrictions**  
⚠️ **Requires manual token copy** - Due to CAPTCHA protection

---

## Installation

### Method 1: Docker Deployment (Recommended)

Using Docker Compose is the simplest way to deploy:

#### 1. Configure Environment

Copy the environment template:

```bash
cp env_template.txt .env
```

Edit `.env` file with key parameters:

```env
# Z.AI API Configuration
API_ENDPOINT=https://chat.z.ai/api/chat/completions
# ZAI_TOKEN=your_zai_token        # Optional: will use anonymous tokens if not set
ZAI_SIGNING_SECRET=junjie

# Server Configuration
LISTEN_PORT=8080
AUTH_TOKEN=sk-123456

# Anonymous Token Configuration (recommended defaults)
ENABLE_GUEST_TOKEN=true          # Enable anonymous token functionality
GUEST_TOKEN_CACHE_MINUTES=30     # Cache for 30 minutes

# Feature Switches
ENABLE_TOOLIFY=true              # Enable tool calling
DEBUG_LOGGING=false              # Disable in production
```

#### Zero Configuration Deployment Mode

If you don't want to configure any token, use anonymous mode:

```env
# Minimal configuration - only need these two basic parameters
LISTEN_PORT=8080
AUTH_TOKEN=sk-123456

# Other parameters will use defaults, automatically enabling anonymous token mode
```

#### 2. Start Service

```bash
# Build and start container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop service
docker-compose down
```

Service will start at `http://localhost:8080`.

#### 3. Update Service

```bash
# Rebuild after pulling latest code
docker-compose up -d --build
```

### Method 2: Local Deployment

If you prefer to run directly in your local environment:

#### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

#### 2. Configure Environment

Copy the environment template:

```bash
cp env_template.txt .env
```

Edit `.env` file with the same parameters as above.

#### 3. Start Service

```bash
python main.py
```

Service will start at `http://localhost:8080`.

---

## Configuration

### Environment Variables

| Variable Name                     | Description                  | Default Value                            |
| --------------------------------- | ---------------------------- | ---------------------------------------- |
| `API_ENDPOINT`                    | Z.AI API address             | `https://chat.z.ai/api/chat/completions` |
| `ZAI_TOKEN`                       | Z.AI auth token (optional)   | -                                        |
| `ZAI_SIGNING_SECRET`              | Signing secret               | `junjie`                                 |
| `AUTH_TOKEN`                      | API Key (client auth)        | `sk-your-api-key`                        |
| `LISTEN_PORT`                     | Server listen port           | `8080`                                   |
| `ENABLE_GUEST_TOKEN`              | Enable anonymous tokens      | `true`                                   |
| `GUEST_TOKEN_CACHE_MINUTES`       | Anonymous token cache (min)  | `30`                                     |
| `ZAI_AUTH_ENDPOINT`               | Z.AI auth API endpoint       | `https://chat.z.ai/api/v1/auths/`        |
| `PRIMARY_MODEL`                   | Primary model name           | `GLM-4.5`                                |
| `THINKING_MODEL`                  | Thinking model name          | `GLM-4.5-Thinking`                       |
| `SEARCH_MODEL`                    | Search model name            | `GLM-4.5-Search`                         |
| `AIR_MODEL`                       | Air model name               | `GLM-4.5-Air`                            |
| `GLM_45V_MODEL`                   | GLM-4.5V vision model        | `GLM-4.5V`                               |
| `GLM_46_MODEL`                    | GLM-4.6 model name           | `GLM-4.6`                                |
| `GLM_46_THINKING_MODEL`           | GLM-4.6 thinking model       | `GLM-4.6-Thinking`                       |
| `GLM_46_SEARCH_MODEL`             | GLM-4.6 search model         | `GLM-4.6-Search`                         |
| `ENABLE_TOOLIFY`                  | Enable tool calling          | `true`                                   |
| `TOOLIFY_CUSTOM_PROMPT`           | Custom tool calling prompt   | -                                        |
| `DEBUG_LOGGING`                   | Detailed logging             | `true`                                   |
| `SKIP_AUTH_TOKEN`                 | Skip auth (for testing)      | `false`                                  |
| `MAX_RETRIES`                     | Request retry count          | `3`                                      |
| `HTTP_PROXY`                      | HTTP proxy address           | -                                        |
| `HTTPS_PROXY`                     | HTTPS proxy address          | -                                        |

### Port Configuration

Default: `7322` or `8080`

To change:
```bash
export SERVER_PORT=8080
bash scripts/start.sh
```

Or edit `.env`:
```env
LISTEN_PORT=8080
```

### Model Mapping

All unknown models automatically map to `GLM-4.6` (default).

Example:
- `gpt-4` → `GLM-4.6`
- `gpt-4-turbo` → `GLM-4.6`
- `claude-3` → `GLM-4.6`

---

## Deployment Guide

### ✅ Fully Tested & Working Setup

This project has been successfully tested and verified to work with Z.AI service.

### 🚀 Quick Deployment

#### 1. Clone the Repository

```bash
git clone https://github.com/Zeeeepa/zai-api.git
```

#### 2. Navigate to Project Directory

```bash
cd zai-api
```

#### 3. Set Environment Variables

```bash
export ZAI_EMAIL="your-email@example.com"
export ZAI_PASSWORD="your-password"
export SERVER_PORT=7322
```

#### 4. Run Complete Setup

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

### 📝 Available Scripts

#### 1. `setup.sh` - Environment Setup & Token Validation
```bash
bash scripts/setup.sh
```
- Creates .env configuration
- Validates JWT tokens
- Installs Python dependencies
- Configures ZAI credentials

#### 2. `start.sh` - Start API Server
```bash
bash scripts/start.sh
```
- Activates virtual environment (.venv)
- Starts server on configured port
- Displays server port and available models
- Performs health checks
- Validates all endpoints

#### 3. `send_request.sh` - Test API
```bash
bash scripts/send_request.sh
```
- Runs comprehensive test suite
- Tests streaming and non-streaming responses
- Validates model mappings

#### 4. `all.sh` - Complete Pipeline
```bash
bash scripts/all.sh
```
- Runs all scripts sequentially (setup → start → test)
- Complete deployment in one command

### 🎯 Individual Scripts Usage

#### Complete Setup:
```bash
bash scripts/setup.sh
```

#### Start Server:
```bash
bash scripts/start.sh
```

#### Send Test Request:
```bash
bash scripts/send_request.sh "Your question here"
```

#### Run Everything:
```bash
bash scripts/all.sh
```

### 🌟 After Setup - Your Server

#### Server Running:
```
http://localhost:7322
```

#### Available Endpoints:
```
GET  http://localhost:7322/health              # Health check
GET  http://localhost:7322/v1/models           # List models
POST http://localhost:7322/v1/chat/completions # Chat
```

#### Test with curl:
```bash
curl http://localhost:7322/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-123456" \
  -d '{
    "model": "GLM-4.5",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

#### Test with OpenAI SDK:
```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:7322/v1",
    api_key="sk-123456"  # Any key works
)

response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

---

## FlareProx Integration

### What is FlareProx?

FlareProx provides rotating proxy IPs through Cloudflare Workers to avoid rate limiting and IP blocks.

### Features

- **Automatic IP rotation** for each request
- **Cloudflare Workers** based proxy
- **Easy integration** with existing setup
- **No additional configuration** required after setup

### Setup Instructions

#### 1. Enable FlareProx

Set environment variable:
```bash
export ENABLE_FLAREPROX="true"
```

Or edit `.env`:
```env
ENABLE_FLAREPROX=true
```

#### 2. Run Integration Script

```bash
bash scripts/integrate_flareprox.sh
```

This script will:
- Install FlareProx if not already installed
- Configure Cloudflare Workers
- Set up proxy rotation
- Test the integration

#### 3. Restart Server

```bash
bash scripts/start.sh
```

### Configuration

FlareProx configuration is automatic. The integration script handles:
- Cloudflare Worker deployment
- Proxy endpoint configuration
- Request routing setup

### Verification

Check if FlareProx is working:
```bash
# Check health endpoint
curl http://localhost:8080/health

# FlareProx status should show "active"
```

### Troubleshooting FlareProx

#### FlareProx not working:
1. Check Cloudflare Workers are deployed
2. Verify ENABLE_FLAREPROX=true in .env
3. Check logs for proxy errors

#### Rate limiting still occurring:
1. Verify FlareProx is active (check logs)
2. Try redeploying Cloudflare Workers
3. Check Cloudflare account limits

---

## API Usage

### API Endpoints

| Endpoint                     | Method | Description                |
| ---------------------------- | ------ | -------------------------- |
| `/`                          | GET    | Service information        |
| `/health`                    | GET    | Health check               |
| `/v1/chat/completions`       | POST   | Chat completion (OpenAI compatible) |
| `/v1/models`                 | GET    | Model list                 |

### Using the API

#### With OpenAI SDK:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="sk-123456"  # Match AUTH_TOKEN in .env
)

# Simple conversation
response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[
        {"role": "user", "content": "Hello"}
    ]
)

print(response.choices[0].message.content)
```

#### With curl:

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-123456" \
  -d '{
    "model": "GLM-4.5",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": false
  }'
```

#### Streaming Response:

```python
stream = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end='')
```

---

## Tool Calling (Function Calling)

### Overview

ZAI-API fully supports OpenAI-compatible tool calling, allowing models to call functions you define.

### Single Function Call

```python
tools = [{
    "type": "function",
    "function": {
        "name": "calculate",
        "description": "Perform mathematical calculations",
        "parameters": {
            "type": "object",
            "properties": {
                "expression": {"type": "string", "description": "Math expression"}
            },
            "required": ["expression"]
        }
    }
}]

response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "Calculate 123 * 456"}],
    tools=tools
)
```

### Multiple Function Calls

```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get weather information",
            "parameters": {...}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "search_restaurants",
            "description": "Search restaurants",
            "parameters": {...}
        }
    }
]

response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "What's the weather in Beijing and where can I eat?"}],
    tools=tools
)
```

### Tool Choice Strategy

```python
# Force call specific function
response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "What time is it?"}],
    tools=tools,
    tool_choice={"type": "function", "function": {"name": "get_current_time"}}
)

# Force call any function
response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "Help me query information"}],
    tools=tools,
    tool_choice="required"
)
```

### Streaming Tool Calls

```python
stream = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "How's the weather today?"}],
    tools=tools,
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.tool_calls:
        print(chunk.choices[0].delta.tool_calls)
```

---

## Testing

### Run Integration Tests

```bash
# Tool calling integration tests
python tests/test_toolify_integration.py

# Stream mode tests
python tests/test_stream_modes.py

# Non-stream tests
python tests/test_non_stream.py

# Concurrency tests
python tests/test_concurrency.py
```

### Expected Output

```
================================================================
🚀 Complete Pipeline Execution
================================================================

Step 1/3: Environment Setup & Token Validation
✅ .env file exists
✅ Found existing token: eyJhbGciOiJFUzI1NiIs...
✅ Dependencies installed
✅ Configuration validated

Step 2/3: Start Server & Health Checks
✅ Server started with PID: 5858
✅ Server is ready!
✅ All health checks passed

Step 3/3: Send Test Request
✅ Request sent via OpenAI SDK
✅ Response received successfully

🎉 Complete Pipeline Executed Successfully!
```

---

## Migration Guide

### Upgrading from Previous Versions

#### From v1.x to v2.x

**Breaking Changes:**
- Anonymous token support added (ENABLE_GUEST_TOKEN)
- Token fallback mechanism changed (3-tier strategy)
- FlareProx integration added

**Migration Steps:**

1. **Update Environment Variables:**
```bash
# Add new variables to .env
ENABLE_GUEST_TOKEN=true
GUEST_TOKEN_CACHE_MINUTES=30
ENABLE_FLAREPROX=false
```

2. **Update Dependencies:**
```bash
pip install -r requirements.txt --upgrade
```

3. **Restart Server:**
```bash
bash scripts/start.sh
```

#### Token Migration

**Old Configuration:**
```env
ZAI_TOKEN=your_token_here
```

**New Configuration (Automatic Fallback):**
```env
# Primary: Your configured token (optional)
ZAI_TOKEN=your_token_here

# Fallback: Anonymous tokens (automatic)
ENABLE_GUEST_TOKEN=true
GUEST_TOKEN_CACHE_MINUTES=30
```

If you don't set ZAI_TOKEN, the system automatically uses anonymous tokens.

### Database Schema Changes

No database migrations required - this is a stateless API proxy.

---

## Compatibility

### System Requirements

#### Minimum Requirements:
- **Python**: 3.8+
- **OS**: Linux, macOS, Windows
- **RAM**: 512MB
- **Disk**: 100MB

#### Recommended:
- **Python**: 3.10+
- **RAM**: 1GB+
- **CPU**: 2+ cores

### Python Version Compatibility

| Python Version | Status      | Notes                    |
| -------------- | ----------- | ------------------------ |
| 3.8            | ✅ Supported | Minimum version          |
| 3.9            | ✅ Supported | Recommended              |
| 3.10           | ✅ Supported | Recommended              |
| 3.11           | ✅ Supported | Recommended              |
| 3.12           | ✅ Supported | Latest tested            |

### Dependency Compatibility

Key dependencies and their versions:

```
fastapi>=0.104.0
uvicorn>=0.24.0
httpx>=0.25.0
python-dotenv>=1.0.0
pydantic>=2.0.0
```

### Platform Support

| Platform           | Status      | Notes                    |
| ------------------ | ----------- | ------------------------ |
| Ubuntu 20.04+      | ✅ Fully tested | Recommended          |
| Debian 11+         | ✅ Supported |                          |
| CentOS 8+          | ✅ Supported |                          |
| macOS 11+          | ✅ Supported | Apple Silicon supported  |
| Windows 10+        | ✅ Supported | Use WSL2 recommended     |
| Docker             | ✅ Supported | Recommended deployment   |

### Browser Compatibility (for token extraction)

| Browser            | Status      | Notes                    |
| ------------------ | ----------- | ------------------------ |
| Chrome/Chromium    | ✅ Fully supported |                      |
| Firefox            | ✅ Fully supported |                      |
| Edge               | ✅ Fully supported |                      |
| Safari             | ✅ Supported | DevTools slightly different |

### Known Issues

#### Python 3.8:
- Some type hints may show warnings (non-critical)

#### Windows:
- Use WSL2 for better compatibility
- Native Windows works but may have path issues

#### Docker:
- Ensure Docker version 20.10+
- docker-compose v2 recommended

---

## Troubleshooting

### Common Issues

#### Tool Calling Not Working

1. Confirm `ENABLE_TOOLIFY=true` in `.env`
2. Check request contains `tools` parameter
3. Look for `[TOOLIFY]` info in logs

#### Authentication Failed

1. Verify `.env` has correct `ZAI_TOKEN`, or enable anonymous mode
2. Check client `api_key` matches `AUTH_TOKEN`
3. If using anonymous mode, confirm `ENABLE_GUEST_TOKEN=true`

#### Model Unavailable

1. Check Z.AI API is accessible
2. Verify model name configuration is correct
3. Check Z.AI Token is valid
4. In anonymous mode, some advanced features may be limited

#### Server Won't Start

```bash
# Check if port is in use:
lsof -i :8080

# Kill existing process:
pkill -f 'python3 main.py'

# Try again:
bash scripts/start.sh
```

#### Token Not Working

```bash
# Get a fresh token from browser
bash scripts/get_token_from_browser.sh

# Or let system use guest tokens automatically
# (just remove ZAI_TOKEN from .env)
```

#### Connection Refused

```bash
# Make sure server is running:
bash scripts/start.sh

# Check server status:
curl http://localhost:8080/health
```

### View Detailed Logs

Set `DEBUG_LOGGING=true` in `.env` and restart service to see complete request and response logs.

### Getting Help

1. Check this documentation first
2. Review logs for error messages
3. Search existing GitHub issues
4. Open new issue with:
   - System info (OS, Python version)
   - Configuration (with secrets redacted)
   - Error logs
   - Steps to reproduce

---

## Changelog

### Scripts Changelog

#### [Latest] - 2024-10
**Major Updates:**
- Added anonymous token support
- Integrated FlareProx for proxy rotation
- Enhanced token fallback mechanism
- Improved error handling

**Script Changes:**
- `setup.sh`: Added guest token configuration
- `start.sh`: Enhanced health checks
- `integrate_flareprox.sh`: New FlareProx integration
- `all.sh`: Updated pipeline flow

**Bug Fixes:**
- Fixed token validation edge cases
- Improved error messages
- Better handling of network failures

#### [1.0.0] - 2024-09
**Initial Release:**
- Basic OpenAI compatibility
- Z.AI API integration
- Tool calling support
- Docker deployment
- Complete script suite

---

## Reference Projects

This project was inspired by and references:

1. [z.ai2api_python](https://github.com/ZyphrZero/z.ai2api_python)
2. [Toolify](https://github.com/funnycups/Toolify)

---

## License

See LICENSE file for details.

---

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Made with ❤️ by the Zeeeepa team**

