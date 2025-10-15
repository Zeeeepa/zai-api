# 🚀 Quick Start - Get Your Z.AI API Running in 2 Minutes

## **The Simplest Way - Just Run It!**

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

---

## 🔐 **Want Authenticated Mode? (Optional)**

If you want to use your own Z.AI account instead of guest mode:

### **Step 1: Get Your Token from Browser**

1. Open https://chat.z.ai in your browser
2. Login with your email and password
3. Open Developer Tools (F12 or Ctrl+Shift+I)
4. Go to 'Application' tab → 'Local Storage' → 'https://chat.z.ai'
5. Find 'token' key and copy its value

**OR** use this JavaScript in Console:
```javascript
localStorage.getItem('token')
```

### **Step 2: Save Token**

Run the interactive token setup script:
```bash
bash scripts/get_token_from_browser.sh
```

It will prompt you to paste your token, then save it to .env automatically!

### **Step 3: Start Server**

```bash
bash scripts/all.sh
```

---

## 📋 **What Happens Behind the Scenes:**

### **Anonymous Mode (Default):**
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

### **Authenticated Mode (With Your Token):**
```
get_token_from_browser.sh (saves your token)
     ↓
bash scripts/all.sh
     ↓
Server uses your token for all requests
     ↓
Done! 🎉
```

---

## 🎯 **Individual Scripts:**

### **Complete Setup:**
```bash
bash scripts/setup.sh
```

### **Start Server:**
```bash
bash scripts/start.sh
```

### **Send Test Request:**
```bash
bash scripts/send_request.sh "Your question here"
```

### **Run Everything:**
```bash
bash scripts/all.sh
```

---

## 🌟 **After Setup - Your Server**

### **Server Running:**
```
http://localhost:8080
```

### **Available Endpoints:**
```
GET  http://localhost:8080/health              # Health check
GET  http://localhost:8080/v1/models           # List models
POST http://localhost:8080/v1/chat/completions # Chat
```

### **Test with curl:**
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-123456" \
  -d '{
    "model": "GLM-4.5",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### **Test with OpenAI SDK:**
```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="sk-123456"  # Any key works
)

response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

---

## 🔐 **Anonymous vs Authenticated Mode**

### **Anonymous Mode (Default):**
✅ **No login required**  
✅ **Works immediately**  
✅ **Great for testing**  
⚠️ **Limited features** - Some advanced features may be restricted

### **Authenticated Mode:**
✅ **Full features**  
✅ **Your own account**  
✅ **No restrictions**  
⚠️ **Requires manual token copy** - Due to CAPTCHA protection

---

## 🔧 **Configuration**

All configuration is in `.env` file:

```bash
# Authentication (optional - uses guest tokens if not set)
AUTH_TOKEN=your_token_here
ZAI_TOKEN=your_token_here

# Server settings
PORT=8080
API_ENDPOINT=https://chat.z.ai/api/chat/completions

# Features
ENABLE_GUEST_TOKEN=true
DEBUG_LOGGING=true
```

---

## 🐛 **Troubleshooting**

### **"Server Won't Start"**
```bash
# Check if port 8080 is in use:
lsof -i :8080

# Kill existing process:
pkill -f 'python3 main.py'

# Try again:
bash scripts/start.sh
```

### **"Token Not Working"**
```bash
# Get a fresh token from browser
bash scripts/get_token_from_browser.sh

# Or let the system use guest tokens automatically
# (just remove AUTH_TOKEN from .env)
```

### **"Connection Refused"**
```bash
# Make sure server is running:
bash scripts/start.sh

# Check server status:
curl http://localhost:8080/health
```

---

## 📊 **Expected Output**

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

## 🎉 **You're Done!**

Your OpenAI-compatible Z.AI API server is now running!

### **Anonymous Mode:**
- ✅ Works immediately
- ✅ No login needed
- ✅ Perfect for testing

### **Authenticated Mode:**
- ✅ Full features
- ✅ Your own account
- ✅ See QUICK_START.md for token setup

---

## 📚 **Next Steps:**

1. **Read the full README.md** for advanced configuration
2. **Check out the examples** in tests/ directory
3. **Integrate with your application** using OpenAI SDK
4. **Explore tool calling** and other advanced features

---

## 🔗 **Links**

- **GitHub Repository:** https://github.com/Zeeeepa/zai-api
- **Z.AI Website:** https://chat.z.ai
- **Documentation:** See README.md for complete docs

---

## 💡 **Why Guest Tokens?**

Z.AI uses CAPTCHA protection for login, which prevents automatic authentication.

**The solution:**
- **Anonymous mode** - Uses guest tokens automatically (default)
- **Authenticated mode** - Manually copy token from browser (optional)

Both modes work perfectly! Choose what fits your needs. 🚀

---

**Made with ❤️ by the Zeeeepa team**

