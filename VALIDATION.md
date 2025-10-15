# Validation API Documentation

Complete guide to the validation module (`src/validation.py`) for Z.AI web interface requests, responses, signatures, headers, and tokens.

## Overview

The validation module provides comprehensive validation for:
- **Request Structure**: Z.AI web interface requests
- **Response Format**: SSE streaming responses
- **Signatures**: Double HMAC-SHA256 signatures
- **Headers**: Browser-like HTTP headers
- **Tokens**: JWT token format and content

## Installation

```bash
# Install validation dependencies
pip install jsonschema python-jose
```

## Quick Start

```python
from src.validation import (
    validate_zai_request,
    validate_zai_response,
    validate_signature,
    validate_headers,
    validate_token,
    print_validation_result
)

# Validate a request
result = validate_zai_request(request_data)
print_validation_result(result)

# Check if valid
if result.valid:
    print("✅ Valid!")
else:
    print("❌ Errors found:", result.errors)
```

## API Reference

### ValidationResult

Result object returned by all validation functions.

**Attributes:**
- `valid` (bool): True if validation passed
- `errors` (list): Critical/error severity issues
- `warnings` (list): Non-critical issues
- `info` (list): Informational messages

**Methods:**
- `has_errors()` → bool: Check if errors present
- `has_warnings()` → bool: Check if warnings present
- `get_all_messages()` → list[str]: Get all formatted messages

**Example:**
```python
result = validate_zai_request(data)

# Check validity
if result:  # Same as result.valid
    print("Valid!")

# Access details
print(f"Errors: {len(result.errors)}")
print(f"Warnings: {len(result.warnings)}")

# Get messages
for msg in result.get_all_messages():
    print(msg)
```

### validate_zai_request()

Validate Z.AI web interface request structure.

**Signature:**
```python
validate_zai_request(request_data: Dict[str, Any]) -> ValidationResult
```

**Parameters:**
- `request_data`: Complete request dict with 'body' and 'config'

**Validates:**
- Request structure against zai_web_request.json schema
- Model ID is valid (0727-360B-API, etc.)
- Messages array not empty
- X-Signature header present and formatted correctly
- Authorization header present and starts with "Bearer "

**Example:**
```python
request = {
    "body": {
        "stream": True,
        "model": "0727-360B-API",
        "messages": [{"role": "user", "content": "Hello"}],
        # ... more fields
    },
    "config": {
        "url": "https://chat.z.ai/api/chat/completions?...",
        "headers": {
            "Authorization": "Bearer eyJ...",
            "X-Signature": "abc123...",
            # ... more headers
        }
    }
}

result = validate_zai_request(request)
print_validation_result(result, "Request Validation")
```

### validate_zai_response()

Validate Z.AI web interface SSE response chunks.

**Signature:**
```python
validate_zai_response(response_chunk: Dict[str, Any]) -> ValidationResult
```

**Parameters:**
- `response_chunk`: SSE chunk data parsed from JSON

**Validates:**
- Chunk structure against zai_web_response.json schema
- Type field is valid (chat:completion, chat:error, etc.)
- Required fields present based on phase
- Error responses include error details

**Example:**
```python
# Response chunk from SSE stream
chunk = {
    "type": "chat:completion",
    "data": {
        "phase": "content",
        "delta_content": "Hello"
    }
}

result = validate_zai_response(chunk)
if result.valid:
    print("✅ Valid response chunk")
```

### validate_signature()

Validate Z.AI double HMAC-SHA256 signature.

**Signature:**
```python
validate_signature(
    token: str,
    request_id: str,
    timestamp: int,
    user_content: str,
    expected_signature: str,
    secret: str = None
) -> ValidationResult
```

**Parameters:**
- `token`: JWT token
- `request_id`: Request ID (UUID)
- `timestamp`: Timestamp in milliseconds
- `user_content`: Last user message content
- `expected_signature`: Signature to validate against
- `secret`: Signing secret (defaults to env ZAI_SIGNING_SECRET)

**Validates:**
- User ID extraction from token
- Signature generation matches expected
- Timestamp within valid window (5 minutes)

**Example:**
```python
result = validate_signature(
    token="eyJhbGciOiJ...",
    request_id="123e4567-e89b-12d3-a456-426614174000",
    timestamp=1705388800000,
    user_content="Hello, world!",
    expected_signature="a1b2c3d4..."
)

if result.valid:
    print("✅ Signature is valid")
else:
    print("❌ Signature mismatch:", result.errors)
```

### validate_headers()

Validate HTTP headers for Z.AI requests.

**Signature:**
```python
validate_headers(
    headers: Dict[str, str],
    check_browser_like: bool = True
) -> ValidationResult
```

**Parameters:**
- `headers`: HTTP headers dict
- `check_browser_like`: Enable browser-like header validation

**Validates:**
- Required headers present (Authorization, X-Signature, etc.)
- Header values match expected format
- Origin is https://chat.z.ai
- Referer starts with https://chat.z.ai
- Content-Type is application/json
- User-Agent looks browser-like (if check_browser_like=True)
- sec-ch-ua headers present (if check_browser_like=True)

**Example:**
```python
headers = {
    "Authorization": "Bearer eyJ...",
    "X-Signature": "abc123...",
    "Origin": "https://chat.z.ai",
    "Referer": "https://chat.z.ai/",
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0 ...",
}

result = validate_headers(headers)
if result.valid:
    print("✅ Headers are valid")
```

### validate_token()

Validate JWT token format and content.

**Signature:**
```python
validate_token(token: str) -> ValidationResult
```

**Parameters:**
- `token`: JWT token string

**Validates:**
- Token not empty
- JWT format (3 parts separated by dots)
- Payload can be decoded
- User ID field present (id, user_id, uid, or sub)
- Token not expired (if exp field present)

**Example:**
```python
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjEyMyIsImV4cCI6MTcwNTM4ODgwMH0.signature"

result = validate_token(token)
print_validation_result(result, "Token Validation")

if result.valid:
    print("✅ Token is valid and not expired")
```

### print_validation_result()

Pretty print validation result.

**Signature:**
```python
print_validation_result(
    result: ValidationResult,
    title: str = "Validation Result"
) -> None
```

**Parameters:**
- `result`: ValidationResult object
- `title`: Header title for output

**Example:**
```python
result = validate_zai_request(request_data)
print_validation_result(result, "Request Validation Report")

# Output:
# ================================================================
# Request Validation Report
# ================================================================
# ✅ Valid: True
# ❌ Errors: 0
# ⚠️  Warnings: 1
# ℹ️  Info: 2
#
# ⚠️  WARNINGS:
#   • Timestamp is 320s old (>5min window)
#     Field: timestamp
# ...
```

## Validation Severity Levels

The validation module uses severity levels to categorize issues:

```python
from src.validation import ValidationSeverity

ValidationSeverity.CRITICAL  # Blocks request
ValidationSeverity.ERROR     # Should be fixed
ValidationSeverity.WARNING   # Recommended fix
ValidationSeverity.INFO      # Informational
```

## Error Handling

### ValidationError

Base validation error exception.

```python
from src.validation import ValidationError, ValidationSeverity

try:
    # Validation code
    if not valid:
        raise ValidationError(
            "Invalid format",
            field_path="body.model",
            severity=ValidationSeverity.ERROR
        )
except ValidationError as e:
    print(f"Error: {e.message}")
    print(f"Field: {e.field_path}")
    print(f"Severity: {e.severity}")
```

### Specific Error Types

- `SchemaValidationError` - Schema validation failures
- `SignatureValidationError` - Signature validation failures
- `HeaderValidationError` - Header validation failures
- `TokenValidationError` - Token validation failures

## Integration Examples

### FastAPI Endpoint

```python
from fastapi import HTTPException
from src.validation import validate_zai_request, validate_headers

@app.post("/v1/chat/completions")
async def chat_completions(request: dict):
    # Validate request structure
    result = validate_zai_request(request)
    if not result.valid:
        raise HTTPException(
            status_code=400,
            detail={
                "error": "Invalid request",
                "details": result.errors
            }
        )
    
    # Process request...
```

### Pre-Request Validation

```python
from src.validation import (
    validate_token,
    validate_headers,
    validate_signature
)

def validate_before_send(token, headers, request_id, timestamp, message):
    """Validate all components before sending request"""
    
    # Validate token
    token_result = validate_token(token)
    if not token_result.valid:
        return False, "Invalid token", token_result.errors
    
    # Validate headers
    header_result = validate_headers(headers)
    if not header_result.valid:
        return False, "Invalid headers", header_result.errors
    
    # Validate signature
    signature_result = validate_signature(
        token, request_id, timestamp, message,
        headers.get("X-Signature")
    )
    if not signature_result.valid:
        return False, "Invalid signature", signature_result.errors
    
    return True, "All validations passed", []
```

### Response Stream Validation

```python
async def validate_response_stream(response_stream):
    """Validate each chunk in response stream"""
    async for line in response_stream:
        if line.startswith("data: "):
            chunk_str = line[6:].strip()
            if chunk_str and chunk_str != "[DONE]":
                chunk_data = json.loads(chunk_str)
                
                # Validate chunk
                result = validate_zai_response(chunk_data)
                if not result.valid:
                    print(f"⚠️  Invalid chunk: {result.errors}")
                
                yield chunk_data
```

## Schema Loading

Load JSON schemas programmatically:

```python
from src.validation import load_schema

# Load schema
schema = load_schema("zai_web_request")
if schema:
    print("Schema loaded successfully")
    print(f"Definitions: {list(schema['definitions'].keys())}")
```

## Best Practices

1. **Always validate before sending requests**
   ```python
   result = validate_zai_request(request)
   if not result.valid:
       print("Errors:", result.errors)
       return  # Don't send invalid request
   ```

2. **Check warnings even if valid**
   ```python
   if result.has_warnings():
       for warning in result.warnings:
           print(f"Warning: {warning['message']}")
   ```

3. **Use appropriate severity levels**
   - CRITICAL: Must fix immediately
   - ERROR: Should fix before production
   - WARNING: Recommended to fix
   - INFO: Informational only

4. **Validate responses for debugging**
   ```python
   for chunk in response_chunks:
       result = validate_zai_response(chunk)
       if not result.valid:
           log_debug("Invalid chunk", chunk, result.errors)
   ```

5. **Pretty print for humans**
   ```python
   print_validation_result(result, "Comprehensive Validation")
   ```

## Troubleshooting

### Schema not found
**Error**: `Schema file not found: schemas/zai_web_request.json`

**Solution**: Ensure running from project root with schemas/ directory.

### jsonschema missing
**Error**: `jsonschema library not available`

**Solution**: `pip install jsonschema`

### Signature mismatch
**Error**: `Signature mismatch`

**Solutions**:
- Check signing secret matches (ZAI_SIGNING_SECRET)
- Verify timestamp is correct
- Ensure canonical string format is correct
- Check user_id extraction logic

### Token expired
**Error**: `Token has expired`

**Solution**: Obtain new token or use anonymous guest token.

## Additional Resources

- [Schema Documentation](schemas/README.md)
- [Testing Guide](TESTING.md)
- [JSON Schema Specification](https://json-schema.org/)
- [JWT Specification](https://jwt.io/)

