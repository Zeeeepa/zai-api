# 🔄 OpenAI API Compatibility Guide

This server provides **MAXIMUM COMPATIBILITY** with OpenAI clients by accepting ANY api_key and ANY model name!

---

## 🎯 **Key Features:**

### **1. Accept ANY API Key**
The server accepts **ANY** api_key from clients and uses its own configured token internally.

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any123123",  # ANY key works!
    base_url="http://localhost:8080/v1"
)
```

**Why?**  
- Maximum compatibility with existing OpenAI clients
- No need to configure special tokens for each client
- Server handles authentication centrally

---

### **2. Accept ANY Model Name**
The server accepts **ANY** model name and intelligently maps it:

- **Known models** → Used as-is (GLM-4.5, GLM-4.5V, GLM-4.6, etc.)
- **Unknown models** → Mapped to GLM-4.6 (default)

```python
# Unknown model - maps to GLM-4.6
response = client.chat.completions.create(
    model="gpt-5",  # Unknown model
    messages=[{"role": "user", "content": "Hello!"}]
)

# Known model - uses it directly
response = client.chat.completions.create(
    model="GLM-4.5V",  # Known model
    messages=[{"role": "user", "content": "Hello!"}]
)
```

**Why?**  
- Works with any OpenAI client without modification
- Clients can use familiar model names (gpt-4, gpt-3.5-turbo, etc.)
- Intelligent fallback to best available model

---

## 📋 **Supported Models:**

### **Known Models (Used As-Is):**
- `GLM-4.5` - Standard model
- `GLM-4.5-Thinking` - Thinking model
- `GLM-4.5-Search` - Search-enhanced model
- `GLM-4.5-Air` - Lightweight model
- `GLM-4.5V` - Vision model
- `GLM-4.6` - Latest model (default for unknown models)
- `GLM-4.6-Thinking` - Latest thinking model
- `GLM-4.6-Search` - Latest search model

### **Unknown Models (Map to GLM-4.6):**
Any other model name will be mapped to `GLM-4.6`:
- `gpt-4` → GLM-4.6
- `gpt-5` → GLM-4.6
- `gpt-3.5-turbo` → GLM-4.6
- `claude-3` → GLM-4.6
- `anything-else` → GLM-4.6

---

## 🚀 **Examples:**

### **Example 1: Standard OpenAI Client**
```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any123123",  # Any key
    base_url="http://localhost:8080/v1"
)

response = client.chat.completions.create(
    model="gpt-4",  # Will use GLM-4.6
    messages=[{"role": "user", "content": "Write a haiku about code"}]
)

print(response.choices[0].message.content)
```

### **Example 2: Use Specific Model**
```python
response = client.chat.completions.create(
    model="GLM-4.5V",  # Vision model for images
    messages=[
        {
            "role": "user", 
            "content": [
                {"type": "text", "text": "What's in this image?"},
                {"type": "image_url", "image_url": {"url": "https://example.com/image.jpg"}}
            ]
        }
    ]
)
```

### **Example 3: Streaming**
```python
stream = client.chat.completions.create(
    model="gpt-5",  # Will use GLM-4.6
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

### **Example 4: With curl**
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any123123" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## 📊 **Model Mapping in Action:**

### **Server Logs:**
```
[AUTH] Accepting client API key (server will use configured token)
[MODEL] Unknown model 'gpt-5', using default: GLM-4.6
[MODEL] Mapped gpt-5 -> GLM-4.6
```

### **Response:**
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "GLM-4.6",  // Original model mapped
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Hello! How can I help you today?"
    },
    "finish_reason": "stop"
  }]
}
```

---

## 🔐 **Authentication Flow:**

### **Client Side:**
```python
# Client provides ANY api_key
client = OpenAI(
    api_key="sk-random123",  # Any value
    base_url="http://localhost:8080/v1"
)
```

### **Server Side:**
1. ✅ Accept client's api_key (ignore it)
2. ✅ Use server's configured `AUTH_TOKEN` for upstream
3. ✅ Log: `[AUTH] Accepting client API key`

**Result:** Maximum compatibility with existing OpenAI clients!

---

## 🎯 **Why This Design?**

### **Problem:**
- Different clients use different api_keys
- Different clients expect different model names
- Hard to maintain compatibility

### **Solution:**
- **Accept ANY api_key** → Server handles auth centrally
- **Accept ANY model** → Intelligent mapping to available models
- **Maximum compatibility** → Works with ANY OpenAI client

### **Benefits:**
✅ Works with existing OpenAI clients without modification  
✅ No need to configure special tokens per client  
✅ Familiar model names (gpt-4, gpt-3.5-turbo, etc.)  
✅ Intelligent fallback to best available model  
✅ Centralized authentication and model management  

---

## 🔧 **Configuration:**

### **In .env:**
```bash
# Server's authentication token (used for upstream)
AUTH_TOKEN=your_token_here
ZAI_TOKEN=your_token_here

# Default model for unknown model names
# (Automatically set to GLM-4.6)

# Skip auth token validation (for testing)
SKIP_AUTH_TOKEN=false  # Always false in production
```

---

## 📚 **Integration Examples:**

### **LangChain:**
```python
from langchain.chat_models import ChatOpenAI

llm = ChatOpenAI(
    model="gpt-4",  # Will use GLM-4.6
    openai_api_key="sk-any123",
    openai_api_base="http://localhost:8080/v1"
)

response = llm.predict("Hello!")
```

### **LlamaIndex:**
```python
from llama_index.llms import OpenAI

llm = OpenAI(
    model="gpt-4",  # Will use GLM-4.6
    api_key="sk-any123",
    api_base="http://localhost:8080/v1"
)

response = llm.complete("Hello!")
```

### **Autogen:**
```python
from autogen import AssistantAgent, UserProxyAgent, config_list_from_json

config_list = [{
    "model": "gpt-4",  # Will use GLM-4.6
    "api_key": "sk-any123",
    "base_url": "http://localhost:8080/v1"
}]

assistant = AssistantAgent("assistant", llm_config={"config_list": config_list})
```

---

## 🎉 **Summary:**

### **What This Means:**
- ✅ Use ANY OpenAI client **without modification**
- ✅ Use ANY api_key (server handles auth)
- ✅ Use ANY model name (intelligent mapping)
- ✅ Maximum compatibility
- ✅ Zero configuration needed on client side

### **What You Get:**
- 🔓 Universal OpenAI API compatibility
- 🎯 Intelligent model name mapping
- 🔐 Centralized authentication
- 🚀 Works with existing tools and libraries

---

**JUST WORKS!** 🎉

No special configuration. No api_key management. No model name restrictions.

**Use ANY OpenAI client. Use ANY api_key. Use ANY model name.**

**The server handles everything!** 🚀

