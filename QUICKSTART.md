# ZAI-API Quick Start Guide

## 🚀 Complete Setup & Test Workflow

### Prerequisites
- Python 3.8+
- Git
- Z.AI account credentials

### Full Workflow

```bash
# 1. Set environment variables
export ZAI_EMAIL="developer@pixelium.uk"
export ZAI_PASSWORD="developer123?"
export SERVER_PORT=7322

# 2. Clone repository
git clone https://github.com/Zeeeepa/zai-api.git

# 3. Checkout the enhanced branch (optional - features are in main)
cd zai-api
git checkout codegen-bot/upgrade-to-port-7322-with-venv-1760558861

# 4. Run complete setup and test
bash scripts/all.sh
```

### What Happens

The `all.sh` script automatically:

1. **Creates virtual environment** named `{REPO_NAME}` (e.g., `zai-api`)
2. **Activates** the virtual environment
3. **Installs** all Python dependencies
4. **Validates** your Z.AI token
5. **Starts** the OpenAI-compatible server on port **7322**
6. **Runs** a test request using the OpenAI SDK
7. **Displays** available models and server information

### Expected Output

```bash
✅ Virtual environment 'zai-api' created
✅ Virtual environment 'zai-api' activated
✅ SERVER_PORT set to 7322
✅ Server started with PID: XXXX
✅ Server is ready!

Server Information:
  • URL:              http://localhost:7322
  • SERVER_PORT:      7322
  • Health Check:     http://localhost:7322/health

Available Models:
  - GLM-4.5
  - GLM-4.5-Thinking
  - GLM-4.5-Search
  - GLM-4.5-Air
  - GLM-4.5V
  - GLM-4.6
  - GLM-4.6-Thinking
  - GLM-4.6-Search

📡 Sending request to http://localhost:7322/v1/chat/completions

✅ RESPONSE RECEIVED
[AI response content here]

📊 USAGE STATISTICS
Prompt tokens:     XX
Completion tokens: XXX
Total tokens:      XXX

✅ Complete Pipeline Executed Successfully!
```

### Test Request Script

The `scripts/send_request.sh` runs this Python code:

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

### Individual Scripts

You can also run scripts separately:

```bash
# 1. Setup only (creates venv, installs deps, validates token)
bash scripts/setup.sh

# 2. Start server only (activates venv, starts server)
bash scripts/start.sh

# 3. Test request only (activates venv, sends test)
bash scripts/send_request.sh
```

### Configuration

All scripts respect these environment variables:

- `ZAI_EMAIL` - Your Z.AI account email
- `ZAI_PASSWORD` - Your Z.AI password
- `SERVER_PORT` - Server port (default: 7322)

### Troubleshooting

**Virtual environment activation fails:**
- Make sure you're in the correct directory (`cd zai-api`)
- Check that Python 3.8+ is installed
- Verify the venv was created successfully

**Server fails to start:**
- Check if port 7322 is already in use
- Verify your Z.AI credentials are correct
- Check `server.log` for detailed error messages

**Test request fails:**
- Ensure server is running (check process list)
- Verify SERVER_PORT matches in all commands
- Check network connectivity to Z.AI API

### Next Steps

Once the server is running:

1. **Use with any OpenAI-compatible client:**
   ```python
   from openai import OpenAI
   
   client = OpenAI(
       api_key="sk-any",
       base_url="http://localhost:7322/v1"
   )
   ```

2. **Test with curl:**
   ```bash
   curl http://localhost:7322/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d '{
       "model": "gpt-4",
       "messages": [{"role": "user", "content": "Hello!"}]
     }'
   ```

3. **Check available models:**
   ```bash
   curl http://localhost:7322/v1/models
   ```

### Clean Up

To stop the server and clean up:

```bash
# Stop server
pkill -f 'python3 main.py'

# Remove virtual environment (optional)
rm -rf zai-api  # or whatever your venv is named
```

## 🎯 Summary

This setup provides:
- ✅ Automated virtual environment management
- ✅ Configurable server port (default 7322)
- ✅ Complete token validation
- ✅ OpenAI SDK compatibility
- ✅ 8 GLM models available
- ✅ Full test suite included

For more details, see `DEPLOYMENT.md` or `README.md`.

