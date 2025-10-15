# Z.AI Web Interface Schemas

This directory contains JSON Schema definitions for the zai-api project - a **Z.AI web scraping proxy** that provides OpenAI-compatible API access.

## ⚠️ Important: This is NOT an official API wrapper

This project **mimics browser behavior** to access chat.z.ai's web interface, not an official API. All schemas document the **actual web interface format**, not API documentation.

## Schema Files

### `zai_web_request.json`
Complete JSON Schema for Z.AI web interface HTTP requests.

**Defines:**
- Request body structure (messages, features, mcp_servers, files, etc.)
- Query parameters (60+ browser fingerprint fields)
- Required HTTP headers (Authorization, X-Signature, browserforge-generated headers)
- Model mappings (OpenAI model names → Z.AI internal IDs)
- File upload structure for images

**Key Components:**
- `RequestBody` - Complete request body sent to chat.z.ai
- `QueryParams` - Browser fingerprint parameters
- `Headers` - Required HTTP headers including X-Signature
- `ZAIMessage` - Message format (system converted to user)
- `Features` - Feature flags and MCP server configuration

### `zai_web_response.json`
JSON Schema for Z.AI web interface SSE streaming responses.

**Defines:**
- Server-Sent Events (SSE) format
- Streaming chunk types (chat:completion, chat:error, chat:usage, tool_call)
- Response phases (thinking, content, done)
- Token usage metadata
- Tool call structures
- Web search results

**Key Components:**
- `StreamingChunk` - SSE event structure
- `ChunkData` - Event data payload
- `Usage` - Token usage statistics
- `ToolCall` - Function calling format
- `ErrorResponse` - Error format

### `zai_auth.json`
JWT token and signature authentication schema.

**Defines:**
- JWT payload structure (user_id extraction logic)
- Double HMAC-SHA256 signature algorithm
- Signature components and canonical string format
- Guest/anonymous token flow
- Authentication endpoints

**Key Components:**
- `JWTPayload` - Decoded token structure
- `SignatureComponents` - Signature generation components
- `GuestTokenRequest` / `GuestTokenResponse` - Anonymous access

### `openaiapi.json`
Complete JSON Schema for OpenAI-compatible API layer.

**Defines:**
- OpenAI API request/response formats
- Compatibility layer structures
- Request transformation requirements
- Response conversion formats

## Authentication Flow

### 1. JWT Token Acquisition
```bash
# Method 1: User-provided token (from browser)
export ZAI_TOKEN="your_jwt_token_from_browser"

# Method 2: Anonymous guest token
curl -X POST https://chat.z.ai/api/v1/auths/ \
  -H "Content-Type: application/json" \
  -d '{"grant_type": "anonymous"}'
```

### 2. Signature Generation
```python
import hmac
import hashlib
import base64

# Extract user_id from JWT (try: id, user_id, uid, sub)
user_id = jwt_payload.get("id", "guest")

# Build canonical string
canonical = f"requestId,{request_id},timestamp,{timestamp},user_id,{user_id}|{base64.b64encode(message.encode()).decode()}|{timestamp}"

# Generate signature
window_index = timestamp // 300000  # 5-minute windows
derived_key = hmac.new(secret.encode(), str(window_index).encode(), hashlib.sha256).hexdigest()
signature = hmac.new(derived_key.encode(), canonical.encode(), hashlib.sha256).hexdigest()
```

### 3. Request Headers
```python
headers = {
    "Authorization": f"Bearer {jwt_token}",
    "X-Signature": signature,
    "X-Fe-Version": "prod-fe-1.0.78",
    "Origin": "https://chat.z.ai",
    "Referer": "https://chat.z.ai/",
    "User-Agent": "Mozilla/5.0 ...",  # browserforge-generated
    "Content-Type": "application/json",
    # ... more browser-like headers
}
```

## Model Mapping

OpenAI Model Name → Z.AI Internal ID:
```
GLM-4.5            → 0727-360B-API
GLM-4.5-Thinking   → 0727-360B-API (with enable_thinking: true)
GLM-4.5-Search     → 0727-360B-API (with mcp_servers: ["deep-web-search"])
GLM-4.5-Air        → 0727-106B-API
GLM-4.5V           → glm-4.5v (vision model)
GLM-4.6            → GLM-4-6-API-V1
GLM-4.6-Thinking   → GLM-4-6-API-V1 (with enable_thinking: true)
GLM-4.6-Search     → GLM-4-6-API-V1 (with mcp_servers: ["deep-web-search"])
```

## Endpoints

- **Guest Token**: `https://chat.z.ai/api/v1/auths/`
- **Chat Completions**: `https://chat.z.ai/api/chat/completions`

## Response Format

Z.AI uses **Server-Sent Events (SSE)** for streaming:

```
data: {"type":"chat:completion","data":{"phase":"thinking","delta_content":"..."}}

data: {"type":"chat:completion","data":{"phase":"content","delta_content":"Hello"}}

data: {"type":"chat:completion","data":{"phase":"done","usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}}

data: [DONE]
```

## Usage with Validation

```python
import json
import jsonschema

# Load schemas
with open('schemas/zai_web_request.json') as f:
    request_schema = json.load(f)

# Validate request
try:
    jsonschema.validate(
        request_data,
        request_schema['definitions']['CompleteRequest']
    )
    print("✅ Request is valid")
except jsonschema.ValidationError as e:
    print(f"❌ Validation error: {e.message}")
```

## Important Notes

1. **Web Scraping Approach**: This project accesses Z.AI's web interface, not an official API
2. **Browser Mimicry Required**: Requests must include proper headers and signatures
3. **JWT Tokens**: Either user-provided (from browser) or anonymous guest tokens
4. **Double HMAC Signature**: Required for all requests (X-Signature header)
5. **Time Windows**: Signatures valid for 5-minute windows
6. **SSE Streaming**: Responses use Server-Sent Events format
7. **System Role Conversion**: System messages converted to user messages with prefix

## Schema Updates

When updating schemas:
1. Analyze actual browser network traffic to chat.z.ai
2. Update the relevant JSON schema file
3. Update this README if needed
4. Update validation code in `src/validation.py`
5. Run schema validation tests

## References

- [JSON Schema Specification](https://json-schema.org/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference) (for compatibility layer)
- [Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)

