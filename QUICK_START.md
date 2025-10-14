# ⚡ ZAI-API Quick Start Guide

## 🚀 One-Command Setup

```bash
# 1. Add your Qwen credentials
cat >> .env << EOF
QWEN_EMAIL=your_email@example.com
QWEN_PASSWORD=your_password
EOF

# 2. Run everything
./all.sh
```

That's it! The script will:
- ✅ Install dependencies
- ✅ Extract Qwen token via Playwright
- ✅ Start API server
- ✅ Test with Graph-RAG question

---

## 📋 Individual Scripts

### Extract Token
```bash
./setup.sh
```
- Automates login to chat.qwen.ai
- Extracts JWT token
- Saves to .env

### Start Server
```bash
./start.sh
```
- Validates token
- Starts API on port 8080
- Health monitoring

### Test API
```bash
./send_request.sh
```
- Sends "What is Graph-RAG?" question
- Prints full answer
- Saves response JSON

---

## 🎯 Common Commands

```bash
# View logs
tail -f server.log

# Stop server
kill $(cat server.pid)

# Restart
./start.sh

# Test health
curl http://localhost:8080/health

# List models
curl http://localhost:8080/v1/models \
  -H "Authorization: Bearer sk-123456"
```

---

## 🔧 Troubleshooting

### Token extraction fails?
```bash
# Check credentials
grep QWEN .env

# View error screenshot
open login_error.png
```

### Server won't start?
```bash
# Check logs
tail -50 server.log

# Verify port free
lsof -i :8080

# Check token exists
grep ZAI_TOKEN .env
```

### API request fails?
```bash
# Test health first
curl http://localhost:8080/health

# Check auth token
grep AUTH_TOKEN .env
```

---

## 📚 Full Documentation

See [AUTOMATION_README.md](./AUTOMATION_README.md) for complete details.

---

**Quick? ✅ | Simple? ✅ | Works? ✅**

