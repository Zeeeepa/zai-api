# Testing Guide

Comprehensive testing documentation for zai-api project.

## Quick Start

```bash
# Run all tests and validation
./all.sh

# Run specific components
./validate_token.sh      # Test JWT token
./health_check.sh        # Check system health
./send_request.sh        # Test API requests
```

## Test Structure

```
zai-api/
├── test_requests/          # Test request JSON files
│   ├── graph_rag.json      # Graph-RAG test
│   ├── basic_chat.json     # Basic conversation
│   ├── streaming_chat.json # Streaming test
│   └── function_calling.json # Tool calling test
├── test_results/           # Test output directory
├── tests/                  # Python unit tests (future)
└── *.sh                    # Shell script tests
```

## Running Tests

### 1. Token Validation (`./validate_token.sh`)

Tests JWT token format, decoding, expiration, and signature generation.

**Tests performed:**
- JWT format check (3 parts)
- Payload decoding
- User ID extraction
- Expiration check
- Signature generation
- Validation module integration

**Example:**
```bash
./validate_token.sh

# Expected output:
# ✅ All token validation tests passed!
# Token Details:
#   • Format: Valid JWT (3 parts)
#   • User ID: abc123
#   • Signature Generation: Working
```

### 2. Health Check (`./health_check.sh`)

Verifies system health and connectivity.

**Tests performed:**
- Schema files existence
- Python dependencies
- Server status
- Endpoints functionality
- Token pool status
- Upstream connectivity

**Example:**
```bash
./health_check.sh

# Expected output:
# ✅ All health checks passed!
# 🎉 System is healthy and ready
```

### 3. Setup (`./setup.sh`)

Prepares environment and validates configuration.

**Actions:**
- Creates .env if missing
- Validates dependencies
- Tests token extraction (if browser automation enabled)
- Validates schemas

**Example:**
```bash
./setup.sh

# Follow prompts to:
# 1. Enter email/password (for browser token extraction)
# 2. Or manually paste token
# 3. Validate configuration
```

### 4. Start Server (`./start.sh`)

Starts the OpenAI-compatible API server.

**Actions:**
- Validates environment
- Starts FastAPI server
- Runs health checks
- Monitors startup

**Example:**
```bash
./start.sh

# Server starts on http://localhost:8080
# Health endpoint: http://localhost:8080/health
```

### 5. Send Request (`./send_request.sh`)

Tests API requests with validation.

**Actions:**
- Validates request JSON against schema
- Sends request to server
- Validates response
- Saves results to test_results/

**Example:**
```bash
# Test Graph-RAG question
./send_request.sh test_requests/graph_rag.json

# Test all requests
for req in test_requests/*.json; do
    ./send_request.sh "$req"
done
```

### 6. Complete Pipeline (`./all.sh`)

Runs complete validation and testing pipeline.

**Execution order:**
1. Validate token (`validate_token.sh`)
2. Setup environment (`setup.sh`)
3. Start server (`start.sh`)
4. Health check (`health_check.sh`)
5. Send test requests (`send_request.sh`)
6. Generate report
7. Stop server

**Example:**
```bash
./all.sh

# Runs complete test suite
# Outputs detailed report at end
```

## Python Unit Tests (Future)

### Running pytest

```bash
# Install test dependencies
uv pip install pytest pytest-asyncio pytest-cov

# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/test_validation.py -v

# Run specific test function
pytest tests/test_validation.py::test_validate_zai_request -v
```

### Test Files (Planned)

- `tests/test_validation.py` - Validation module tests
- `tests/test_schemas.py` - Schema validation tests
- `tests/mock_zai_responses.py` - Mock fixtures
- `tests/test_scripts.sh` - Shell script integration tests
- `tests/test_signature_validation.py` - Signature tests
- `tests/test_transformation.py` - Transformation tests

## Test Request Files

### graph_rag.json
Tests Graph-RAG knowledge with comprehensive question.

```json
{
  "model": "GLM-4.5",
  "messages": [
    {
      "role": "user",
      "content": "What is Graph-RAG? Explain comprehensively."
    }
  ]
}
```

### basic_chat.json
Simple conversation test.

```json
{
  "model": "GLM-4.5",
  "messages": [
    {"role": "system", "content": "You are a helpful AI assistant."},
    {"role": "user", "content": "Hello! Can you introduce yourself?"}
  ]
}
```

### streaming_chat.json
Tests SSE streaming responses.

```json
{
  "model": "GLM-4.5",
  "messages": [
    {"role": "user", "content": "Count from 1 to 10"}
  ],
  "stream": true
}
```

### function_calling.json
Tests tool/function calling.

```json
{
  "model": "GLM-4.5",
  "messages": [
    {"role": "user", "content": "What's the weather in Beijing?"}
  ],
  "tools": [...]
}
```

## Creating New Tests

### Add Test Request

1. Create JSON file in `test_requests/`:
```json
{
  "model": "GLM-4.5",
  "messages": [
    {"role": "user", "content": "Your test query"}
  ],
  "stream": false
}
```

2. Validate against schema:
```bash
python3 -c "
import json, jsonschema
from pathlib import Path

with open('schemas/openaiapi.json') as f:
    schema = json.load(f)
with open('test_requests/your_test.json') as f:
    request = json.load(f)

jsonschema.validate(request, schema['definitions']['ChatCompletionRequest'])
print('✅ Valid request')
"
```

3. Run test:
```bash
./send_request.sh test_requests/your_test.json
```

## Validation Levels

### Schema Validation
- Request structure matches OpenAI format
- Response matches Z.AI web interface format
- Headers include required fields
- Signatures are properly formatted

### Functional Validation
- Server responds correctly
- Tokens are valid and not expired
- Signatures are correctly generated
- Endpoints return expected status codes

### Integration Validation
- Complete request-response cycle works
- Streaming responses parse correctly
- Error handling works properly
- Transformation maintains data integrity

## Test Results

Test results are saved to `test_results/` with timestamps:

```
test_results/
├── graph_rag_20250115_130500.json
├── basic_chat_20250115_130501.json
└── validation_report_20250115.txt
```

## Troubleshooting

### Tests Failing?

1. **Schema validation errors**:
   - Check JSON syntax
   - Verify required fields present
   - Ensure types match schema

2. **Token validation errors**:
   - Check token format (3 parts)
   - Verify not expired
   - Ensure ZAI_TOKEN in .env

3. **Health check failures**:
   - Verify server running
   - Check port not in use
   - Test network connectivity

4. **Request failures**:
   - Check server logs
   - Verify authentication
   - Test with simpler request first

### Debug Mode

Enable detailed logging:
```bash
export LOG_LEVEL=debug
./send_request.sh test_requests/basic_chat.json
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run validation tests
        run: |
          ./validate_token.sh || true  # Allow anonymous mode
          ./health_check.sh
      - name: Run pytest
        run: pytest tests/ -v --cov=src
```

## Performance Testing

Test API performance:
```bash
# Simple load test
for i in {1..10}; do
    time ./send_request.sh test_requests/basic_chat.json &
done
wait

# Using ab (Apache Bench)
ab -n 100 -c 10 -H "Authorization: Bearer $AUTH_TOKEN" \
   -H "Content-Type: application/json" \
   -p test_requests/basic_chat.json \
   http://localhost:8080/v1/chat/completions
```

## Best Practices

1. ✅ Always validate tokens before testing
2. ✅ Run health checks after server startup
3. ✅ Test with simple requests first
4. ✅ Save test results for debugging
5. ✅ Use schema validation before sending requests
6. ✅ Check logs when tests fail
7. ✅ Test both streaming and non-streaming modes
8. ✅ Verify error handling with invalid inputs

## Resources

- [Schema Validation Guide](schemas/README.md)
- [Validation Module API](VALIDATION.md)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [pytest Documentation](https://docs.pytest.org/)

