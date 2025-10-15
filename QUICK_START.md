# 🚀 Zero to Started - Automatic Token Fetch

## **The CORRECT Way - Automatic Token Retrieval**

```bash
# 1. Clone the repository
git clone https://github.com/Zeeeepa/zai-api.git
cd zai-api

# 2. Set your Z.AI credentials (replace with your actual email and password)
export EMAIL='your@email.com'
export PASSWORD='your_password'

# 3. Run everything - token will be fetched automatically!
bash scripts/all.sh
```

**That's it!** The setup script will:
1. ✅ Automatically fetch your Z.AI token using EMAIL and PASSWORD
2. ✅ Save it to .env file
3. ✅ Start the OpenAI-compatible API server
4. ✅ Run a test request to verify everything works

---

## 📋 Detailed Explanation

### **What Happens Behind the Scenes:**

1. **setup.sh** detects EMAIL and PASSWORD environment variables
2. Calls **fetch_token.sh** which:
   - Logs into Z.AI using your credentials
   - Retrieves your authentication token
   - Saves it to .env file as AUTH_TOKEN and ZAI_TOKEN
3. **start.sh** starts the server using your token
4. **send_request.sh** tests the server with a question

---

## 🎯 Three Ways to Run:

### **Method 1: One-Liner (Recommended)**
```bash
EMAIL='your@email.com' PASSWORD='your_password' bash scripts/all.sh
```

### **Method 2: Export Variables**
```bash
export EMAIL='your@email.com'
export PASSWORD='your_password'
bash scripts/all.sh
```

### **Method 3: Permanent Configuration**
```bash
# Add to your ~/.bashrc or ~/.zshrc
echo 'export EMAIL="your@email.com"' >> ~/.bashrc
echo 'export PASSWORD="your_password"' >> ~/.bashrc
source ~/.bashrc

# Then just run
bash scripts/all.sh
```

---

## 🔧 Individual Scripts:

### **Fetch Token Only:**
```bash
EMAIL='your@email.com' PASSWORD='your_password' bash scripts/fetch_token.sh
```

### **Complete Setup:**
```bash
EMAIL='your@email.com' PASSWORD='your_password' bash scripts/setup.sh
```

### **Start Server:**
```bash
bash scripts/start.sh
```

### **Send Request:**
```bash
bash scripts/send_request.sh "Your question here"
```

---

## ⚠️ Fallback: Anonymous Mode

If you don't want to provide EMAIL/PASSWORD, the system automatically uses **anonymous tokens**:

```bash
# No EMAIL/PASSWORD needed - uses anonymous mode
bash scripts/all.sh
```

**Note:** Anonymous mode has some limitations compared to authenticated mode.

---

## 🌟 After Setup - Your Server

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
  -H "Authorization: Bearer your_token" \
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
    api_key="your_token"
)

response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

---

## 🔐 Security Notes

1. **Never commit your .env file to git** (already in .gitignore)
2. **Store credentials securely** - use environment variables
3. **Use strong passwords**
4. **Rotate tokens periodically**

---

## 🐛 Troubleshooting

### **"EMAIL and PASSWORD environment variables are required"**
```bash
# Make sure to export them:
export EMAIL='your@email.com'
export PASSWORD='your_password'
```

### **Token Fetch Failed**
```bash
# Check your credentials:
1. Can you login at https://chat.z.ai?
2. Is your email/password correct?
3. Try running fetch_token.sh manually to see the error:
   EMAIL='your@email.com' PASSWORD='your_password' bash scripts/fetch_token.sh
```

### **Server Won't Start**
```bash
# Check if port 8080 is in use:
lsof -i :8080

# Kill existing process:
pkill -f 'python3 main.py'

# Try again:
bash scripts/start.sh
```

---

## 📊 Expected Output

```
================================================================
🚀 Complete Pipeline Execution
================================================================

Step 1/3: Environment Setup & Token Fetch
📧 EMAIL and PASSWORD detected, fetching token automatically...
✅ Token fetched and saved to .env
✅ Dependencies installed
✅ Configuration validated

Step 2/3: Start Server & Health Checks
✅ Server started with PID: xxxx
✅ All 7 health checks passed

Step 3/3: Send Test Request
✅ Request sent via OpenAI SDK
✅ Response received successfully

🎉 Complete Pipeline Executed Successfully!
```

---

## 🎉 You're Done!

Your OpenAI-compatible API server is now running with your authenticated Z.AI token!

**No more manual token copying!** 🎊

---

## 🔗 Links

- **GitHub Repository:** https://github.com/Zeeeepa/zai-api
- **Z.AI Website:** https://chat.z.ai
- **Documentation:** See README.md for advanced configuration

---

**Made with ❤️ by the Zeeeepa team**

