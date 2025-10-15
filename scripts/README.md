# ZAI-API Scripts

Complete automation scripts for the ZAI OpenAI-compatible API server.

## 📦 Scripts Overview

This directory contains 4 essential scripts for running and testing the ZAI-API server:

```
scripts/
├── all.sh              # Complete pipeline (setup → start → test)
├── send_request.sh     # Send requests via OpenAI SDK
├── setup.sh            # Environment setup + token validation
└── start.sh            # Start server + health checks
```

---

## 🚀 Quick Start

### **Run Complete Pipeline:**
```bash
./scripts/all.sh
```

This will:
1. Set up environment and validate token
2. Start the OpenAI-compatible API server
3. Send a test request and display the response

---

## 📖 Individual Scripts

### 1. **setup.sh** - Environment Setup & Token Validation

Sets up your environment and validates JWT tokens.

```bash
./scripts/setup.sh
```

**What it does:**
- ✅ Checks Python installation
- ✅ Creates/verifies `.env` file
- ✅ Installs all Python dependencies
- ✅ Verifies OpenAI SDK installation
- ✅ Validates configuration
- ✅ Runs 6-step JWT token validation
  - JWT format check
  - Payload decoding
  - User ID extraction
  - Expiration check
  - Signature generation test
  - Validation module test

**Output:**
- Environment status summary
- Token validation results
- Next steps to run

---

### 2. **start.sh** - Start Server & Health Checks

Starts the FastAPI server and runs comprehensive health checks.

```bash
./scripts/start.sh
```

**What it does:**
- ✅ Checks for existing server processes
- ✅ Starts FastAPI server on port 8080
- ✅ Waits for server to be ready
- ✅ Runs 7-step health check system:
  1. Schema files verification
  2. Python dependencies check
  3. Server status (`/health` endpoint)
  4. Models endpoint (`/v1/models`)
  5. Chat completions endpoint test
  6. Token pool status
  7. Upstream connectivity (chat.z.ai)

**Output:**
- Server startup status
- Health check results
- Server information and endpoints
- Commands to view logs/stop server

**Server Endpoints:**
- Health: `http://localhost:8080/health`
- Models: `http://localhost:8080/v1/models`
- Chat: `http://localhost:8080/v1/chat/completions`

---

### 3. **send_request.sh** - Send OpenAI SDK Requests

Send questions to the API using the OpenAI Python SDK.

```bash
./scripts/send_request.sh "Your question here"
```

**Examples:**
```bash
# Default question
./scripts/send_request.sh

# Custom question
./scripts/send_request.sh "What is Python?"

# Complex question
./scripts/send_request.sh "Explain quantum computing in simple terms"
```

**What it does:**
- ✅ Checks if server is running
- ✅ Uses OpenAI Python SDK to send request
- ✅ Displays the complete response
- ✅ Shows token usage statistics
- ✅ Saves result to `test_results/` directory

**Output:**
- Request configuration
- Full AI response
- Token usage statistics
- Path to saved result file

---

### 4. **all.sh** - Complete Pipeline

Runs the complete workflow: setup → start → test

```bash
./scripts/all.sh
```

**With custom question:**
```bash
./scripts/all.sh "Explain blockchain technology"
```

**What it does:**
- **Step 1/3:** Runs `setup.sh` (environment + validation)
- **Step 2/3:** Runs `start.sh` (start server + health checks)
- **Step 3/3:** Runs `send_request.sh` (send test request)

**Output:**
- Beautiful progress display for each step
- Success/failure status for each phase
- Final summary with all results

---

## ⚙️ Configuration

All scripts use the `.env` file for configuration:

```bash
# Required
AUTH_TOKEN=your_zai_token_here
API_ENDPOINT=https://chat.z.ai/api/chat/completions

# Optional
LISTEN_PORT=8080
ZAI_TOKEN=your_zai_token_here
```

---

## 📁 Output Files

All test results are saved to `test_results/` directory:

```
test_results/
└── result_20251015_145841.txt  # Timestamped results
```

Each result file contains:
- Original question
- Timestamp
- Complete AI response
- Token usage statistics

---

## 🔧 Requirements

- **Python:** 3.8+
- **Dependencies:** Automatically installed by `setup.sh`
- **OpenAI SDK:** Version 1.0.0+

---

## 🎯 Common Workflows

### **First Time Setup:**
```bash
# 1. Setup environment
./scripts/setup.sh

# 2. Start server
./scripts/start.sh

# 3. Test with a question
./scripts/send_request.sh "Hello!"
```

### **Development:**
```bash
# Quick test after code changes
./scripts/all.sh "Test question"
```

### **Server Management:**
```bash
# Start server
./scripts/start.sh

# View logs
tail -f server.log

# Stop server
pkill -f 'python3 main.py'
```

---

## 🐛 Troubleshooting

### **Server won't start:**
```bash
# Check if port is in use
lsof -i :8080

# Kill existing process
pkill -f 'python3 main.py'

# Try again
./scripts/start.sh
```

### **Dependencies issues:**
```bash
# Reinstall dependencies
pip3 install -r requirements.txt --force-reinstall
```

### **Token validation warnings:**
- Token validation warnings are **non-fatal**
- The scripts will continue even with warnings
- Check your token in `.env` file

---

## 📊 Features

✅ **OpenAI SDK Integration** - Uses official OpenAI Python library  
✅ **Non-Fatal Validation** - Continues even with warnings  
✅ **Comprehensive Health Checks** - 7-step validation system  
✅ **Automatic Result Saving** - All responses saved to files  
✅ **Beautiful Output** - Color-coded status messages  
✅ **Error Handling** - Graceful error messages at each step  

---

## 🔗 API Compatibility

This server is **100% OpenAI-compatible**. You can use it as a drop-in replacement:

```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:8080/v1",  # Your local server
    api_key="your_token"
)

response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

---

## 📝 Notes

- All scripts are **idempotent** - safe to run multiple times
- Server logs are written to `server.log`
- Token validation is **non-fatal** - continues with warnings
- Results are timestamped and never overwritten

---

## 🎉 That's It!

You now have a complete, automated workflow for:
- Setting up your environment
- Starting the OpenAI-compatible API server
- Sending requests and getting responses
- All with comprehensive validation and health checks!

**Happy coding!** 🚀

