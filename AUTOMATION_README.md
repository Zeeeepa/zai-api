# 🚀 ZAI-API Automation Scripts

Complete automation suite for deploying and testing the ZAI-API OpenAI-compatible proxy server.

## 📋 Overview

This repository includes 4 bash scripts that automate the entire setup, deployment, and testing workflow:

1. **`setup.sh`** - Environment setup with Playwright automation
2. **`start.sh`** - API server startup with health monitoring
3. **`send_request.sh`** - API testing with OpenAI requests
4. **`all.sh`** - Master orchestration script

---

## 🎯 Quick Start

### One-Line Setup & Test

```bash
# Add your Qwen credentials to .env
echo "QWEN_EMAIL=your_email@example.com" >> .env
echo "QWEN_PASSWORD=your_password" >> .env

# Run everything at once
./all.sh
```

### Step-by-Step Execution

```bash
# 1. Setup environment (extract Qwen token)
./setup.sh

# 2. Start API server
./start.sh

# 3. Test API with Graph-RAG question
./send_request.sh
```

---

## 📜 Script Details

### 1️⃣ setup.sh

**Purpose:** Automated environment setup with Playwright token extraction

**Features:**
- ✅ Installs Python dependencies (`requirements.txt`)
- ✅ Installs Playwright + Chromium browser
- ✅ **Automates login to https://chat.qwen.ai/auth?action=signin**
- ✅ Extracts JWT token from browser storage
- ✅ Saves token to `.env` as `ZAI_TOKEN`
- ✅ Validates credentials before proceeding

**Prerequisites:**
```bash
# Add to .env file:
QWEN_EMAIL=your_email@example.com
QWEN_PASSWORD=your_password
```

**Usage:**
```bash
./setup.sh
```

**What happens:**
1. Loads credentials from `.env` or environment variables
2. Installs Python packages: `fastapi`, `uvicorn`, `playwright`, etc.
3. Installs Playwright Chromium browser
4. Creates Python script for browser automation
5. Opens headless browser and navigates to Qwen login
6. Fills email and password, clicks login
7. Waits for login completion
8. Extracts JWT token from:
   - localStorage (preferred)
   - Cookies (fallback)
   - sessionStorage (secondary)
9. Saves token to `.env` file
10. Creates backup: `.env.backup`

**Error Handling:**
- Screenshots saved on failure: `login_error.png`, `timeout_error.png`
- Detailed error messages with debugging info
- Validates token extraction before proceeding

---

### 2️⃣ start.sh

**Purpose:** Start OpenAI-compatible API server with health monitoring

**Features:**
- ✅ Loads configuration from `.env`
- ✅ Validates `ZAI_TOKEN` exists
- ✅ Starts FastAPI server with uvicorn
- ✅ Health check with 10 retry attempts
- ✅ Process management (PID tracking)
- ✅ Log rotation with timestamps
- ✅ Graceful shutdown of existing instances

**Usage:**
```bash
./start.sh
```

**Server Information Displayed:**
- PID (process ID)
- Server URL: `http://localhost:8080`
- Health endpoint: `/health`
- Models endpoint: `/v1/models`
- Log file location

**Process Management:**
```bash
# View logs
tail -f server.log

# Stop server
kill $(cat server.pid)

# Restart server
./start.sh
```

**Configuration Loaded:**
- `LISTEN_PORT` (default: 8080)
- `AUTH_TOKEN` (API authentication)
- `ZAI_TOKEN` (Qwen session token)
- `LOG_LEVEL` (info, debug)
- `ENABLE_TOOLIFY` (function calling support)

---

### 3️⃣ send_request.sh

**Purpose:** Test API with OpenAI-compatible chat completion request

**Features:**
- ✅ Verifies server health before sending request
- ✅ Sends OpenAI-format POST to `/v1/chat/completions`
- ✅ **Asks: "What is Graph-RAG?"**
- ✅ Parses JSON response with `jq`
- ✅ Displays formatted output:
  - Response metadata (ID, model, timestamps)
  - Token usage statistics
  - Full answer text (word-wrapped)
- ✅ Saves response to `last_response.json`
- ✅ Provides additional usage examples

**Usage:**
```bash
./send_request.sh
```

**Request Payload:**
```json
{
  "model": "GLM-4.5",
  "messages": [
    {
      "role": "user",
      "content": "What is Graph-RAG? Please provide a comprehensive explanation in 3-4 paragraphs."
    }
  ],
  "stream": false,
  "temperature": 0.7,
  "max_tokens": 1000
}
```

**Output Example:**
```
╔════════════════════════════════════════════════════════════╗
║                      API RESPONSE                         ║
╚════════════════════════════════════════════════════════════╝

📊 Response Metadata:
----------------------------------------
  ID: chatcmpl-abc123xyz
  Model: GLM-4.5
  Created: 1697123456
  Finish Reason: stop
----------------------------------------

🔢 Token Usage:
----------------------------------------
  Prompt Tokens: 25
  Completion Tokens: 387
  Total Tokens: 412
----------------------------------------

💬 Answer to "What is Graph-RAG?":
════════════════════════════════════════════════════════════

Graph-RAG (Graph-based Retrieval Augmented Generation) is
an advanced AI technique that combines knowledge graphs with
retrieval systems to enhance language model responses...

[Full answer displayed here]

════════════════════════════════════════════════════════════
```

**Additional Test Examples Provided:**
- Streaming responses (`stream: true`)
- Function calling with tools
- Different models (GLM-4.6, GLM-4.5-Air)

---

### 4️⃣ all.sh

**Purpose:** Master orchestration script for complete automation

**Features:**
- ✅ Runs all 3 scripts sequentially
- ✅ Interactive credential prompt if not set
- ✅ Progress tracking (Step 1/3, 2/3, 3/3)
- ✅ Validation between steps
- ✅ Comprehensive final summary
- ✅ Server info display
- ✅ Useful command references

**Usage:**
```bash
./all.sh
```

**Interactive Flow:**
```
╔════════════════════════════════════════════════════════════╗
║            ZAI-API Complete Automation Suite               ║
║  Automated Setup → Server Start → API Testing             ║
╚════════════════════════════════════════════════════════════╝

This script will:
  1. Install all dependencies and extract Qwen token
  2. Start the OpenAI-compatible API server
  3. Test the API with a Graph-RAG question

Continue? (y/n) y

Starting automated workflow...

╔════════════════════════════════════════════════════════════╗
║  STEP 1/3: Running setup.sh - Installing dependencies     ║
╚════════════════════════════════════════════════════════════╝
[setup.sh output...]

╔════════════════════════════════════════════════════════════╗
║  STEP 2/3: Running start.sh - Starting API server         ║
╚════════════════════════════════════════════════════════════╝
[start.sh output...]

╔════════════════════════════════════════════════════════════╗
║  STEP 3/3: Running send_request.sh - Testing API          ║
╚════════════════════════════════════════════════════════════╝
[send_request.sh output...]

╔════════════════════════════════════════════════════════════╗
║              ✅ ALL STEPS COMPLETED SUCCESSFULLY!           ║
╚════════════════════════════════════════════════════════════╝

📊 Summary:
  ✓ Dependencies installed
  ✓ Qwen token extracted and saved
  ✓ API server running
  ✓ OpenAI-compatible API tested
  ✓ Graph-RAG question answered

🚀 Server Information:
  Status: Running (PID: 12345)
  URL: http://localhost:8080
  Health: http://localhost:8080/health
  Models: http://localhost:8080/v1/models

🎉 Your ZAI-API is ready for production use!
```

---

## 🔧 Configuration

### Environment Variables (.env)

**Required:**
```bash
# Qwen Credentials (for token extraction)
QWEN_EMAIL=your_email@example.com
QWEN_PASSWORD=your_secure_password

# Auto-extracted by setup.sh
ZAI_TOKEN=eyJhbGc...  # JWT token from Qwen
```

**Optional:**
```bash
# Server Configuration
LISTEN_PORT=8080
AUTH_TOKEN=sk-123456  # Client API key

# Logging
LOG_LEVEL=info  # or debug

# Features
ENABLE_TOOLIFY=true  # Function calling support
ENABLE_GUEST_TOKEN=true  # Anonymous token fallback
```

---

## 🧪 Testing

### Health Check
```bash
curl http://localhost:8080/health
# Response: {"status":"healthy"}
```

### List Models
```bash
curl http://localhost:8080/v1/models \
  -H "Authorization: Bearer sk-123456"
```

### Chat Completion (Non-Streaming)
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer sk-123456" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "GLM-4.5",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Chat Completion (Streaming)
```bash
curl -N http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer sk-123456" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "GLM-4.5",
    "messages": [{"role": "user", "content": "Count to 5"}],
    "stream": true
  }'
```

### Function Calling
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer sk-123456" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "GLM-4.5",
    "messages": [{"role": "user", "content": "What is the weather?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get weather info",
        "parameters": {
          "type": "object",
          "properties": {
            "city": {"type": "string"}
          }
        }
      }
    }]
  }'
```

---

## 📁 File Structure

```
zai-api/
├── setup.sh              # Setup + token extraction
├── start.sh              # Server startup
├── send_request.sh       # API testing
├── all.sh                # Master orchestration
├── main.py               # FastAPI application
├── requirements.txt      # Python dependencies
├── env_template.txt      # Environment template
├── .env                  # Configuration (generated)
├── .env.backup          # Backup (auto-created)
├── server.log           # Server output log
├── server.pid           # Process ID file
└── last_response.json   # Latest API response
```

---

## 🐛 Troubleshooting

### Issue: Token Extraction Fails

**Symptoms:**
- setup.sh fails at Playwright step
- Screenshot saved: `login_error.png`

**Solutions:**
1. Verify credentials in `.env`:
   ```bash
   grep "QWEN_" .env
   ```

2. Check screenshot for clues:
   ```bash
   open login_error.png  # macOS
   xdg-open login_error.png  # Linux
   ```

3. Try manual browser test:
   ```bash
   python3 -m playwright codegen https://chat.qwen.ai/auth?action=signin
   ```

4. Check Qwen website status

---

### Issue: Server Won't Start

**Symptoms:**
- start.sh reports health check failure
- Error in `server.log`

**Solutions:**
1. Check logs:
   ```bash
   tail -50 server.log
   ```

2. Verify port is available:
   ```bash
   lsof -i :8080
   ```

3. Check ZAI_TOKEN exists:
   ```bash
   grep "ZAI_TOKEN" .env
   ```

4. Test manually:
   ```bash
   python3 main.py
   ```

---

### Issue: API Request Fails

**Symptoms:**
- send_request.sh returns HTTP error
- Response: 401, 403, 500

**Solutions:**
1. Verify server is running:
   ```bash
   curl http://localhost:8080/health
   ```

2. Check AUTH_TOKEN:
   ```bash
   grep "AUTH_TOKEN" .env
   ```

3. Test with curl:
   ```bash
   curl -v http://localhost:8080/v1/models \
     -H "Authorization: Bearer sk-123456"
   ```

4. Check server logs for errors

---

## 🔐 Security Notes

**Token Management:**
- ZAI_TOKEN is sensitive - keep `.env` secure
- Token expires after ~30 minutes
- Re-run `setup.sh` to refresh token
- Consider using environment variables instead of `.env` in production

**Best Practices:**
- Add `.env` to `.gitignore`
- Use strong AUTH_TOKEN for client authentication
- Enable HTTPS in production
- Rotate tokens regularly
- Monitor access logs

---

## 📚 Additional Resources

- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Playwright Documentation](https://playwright.dev/python/)
- [ZAI-API GitHub Repository](https://github.com/Zeeeepa/zai-api)

---

## 🎯 Next Steps

After successful setup:

1. **Production Deployment:**
   ```bash
   # Use Docker for production
   docker-compose up -d
   ```

2. **Monitoring:**
   ```bash
   # Set up log monitoring
   tail -f server.log | grep ERROR
   ```

3. **Load Testing:**
   ```bash
   # Test with multiple concurrent requests
   ab -n 100 -c 10 http://localhost:8080/health
   ```

4. **Integration:**
   ```python
   # Use with OpenAI Python SDK
   import openai
   openai.api_base = "http://localhost:8080/v1"
   openai.api_key = "sk-123456"
   ```

---

## 🤝 Contributing

Improvements welcome! Please:
1. Test scripts on your system
2. Report issues with logs
3. Submit PRs with detailed descriptions

---

## 📄 License

MIT License - See repository for details

---

**Happy Coding! 🚀**

