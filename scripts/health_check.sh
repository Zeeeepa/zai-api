#!/bin/bash

# health_check.sh - System Health Check Script
# Verifies server status, token pool, schemas, and connectivity

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${1}${2}${NC}"
}

print_header() {
    echo ""
    echo "================================================================"
    echo "$1"
    echo "================================================================"
}

# Configuration
PORT="${LISTEN_PORT:-8080}"
HOST="localhost"
BASE_URL="http://${HOST}:${PORT}"

print_header "🏥 System Health Check"

# Test 1: Check if schemas exist
print_header "Test 1: Schema Files"
SCHEMA_FILES=("zai_web_request.json" "zai_web_response.json" "zai_auth.json" "openaiapi.json")
ALL_SCHEMAS_EXIST=true

for schema in "${SCHEMA_FILES[@]}"; do
    if [ -f "schemas/$schema" ]; then
        print_status "$GREEN" "✅ Found: schemas/$schema"
    else
        print_status "$RED" "❌ Missing: schemas/$schema"
        ALL_SCHEMAS_EXIST=false
    fi
done

if [ "$ALL_SCHEMAS_EXIST" = false ]; then
    print_status "$RED" "❌ Some schema files are missing"
    exit 1
fi

# Test 2: Check Python dependencies
print_header "Test 2: Python Dependencies"
REQUIRED_DEPS=("jsonschema" "fastapi" "httpx" "jose")
ALL_DEPS_INSTALLED=true

for dep in "${REQUIRED_DEPS[@]}"; do
    if python3 -c "import $dep" 2>/dev/null; then
        print_status "$GREEN" "✅ $dep installed"
    else
        print_status "$RED" "❌ $dep not installed"
        ALL_DEPS_INSTALLED=false
    fi
done

if [ "$ALL_DEPS_INSTALLED" = false ]; then
    print_status "$YELLOW" "⚠️  Some dependencies missing. Run: uv pip install -r requirements.txt"
fi

# Test 3: Check if server is running
print_header "Test 3: Server Status"
if curl -s --connect-timeout 2 "$BASE_URL/health" > /dev/null 2>&1; then
    print_status "$GREEN" "✅ Server is running on $BASE_URL"
    
    # Get health response
    HEALTH_RESPONSE=$(curl -s "$BASE_URL/health")
    echo "   Response: $HEALTH_RESPONSE"
else
    print_status "$YELLOW" "⚠️  Server is not running on $BASE_URL"
    print_status "$BLUE" "ℹ️  Run ./start.sh to start the server"
    print_header "📊 Health Check Summary"
    print_status "$YELLOW" "⚠️  Server offline - remaining checks skipped"
    exit 0
fi

# Test 4: Test models endpoint
print_header "Test 4: Models Endpoint"
MODELS_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/v1/models" -H "Authorization: Bearer ${AUTH_TOKEN:-sk-test}")
HTTP_CODE=$(echo "$MODELS_RESPONSE" | tail -1)
MODELS_BODY=$(echo "$MODELS_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    print_status "$GREEN" "✅ /v1/models endpoint working"
    MODEL_COUNT=$(echo "$MODELS_BODY" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['data']))" 2>/dev/null || echo "0")
    echo "   Available models: $MODEL_COUNT"
else
    print_status "$YELLOW" "⚠️  /v1/models returned HTTP $HTTP_CODE"
fi

# Test 5: Test chat completions endpoint (simple health check)
print_header "Test 5: Chat Completions Endpoint"
TEST_REQUEST='{
  "model": "GLM-4.5",
  "messages": [{"role": "user", "content": "Hi"}],
  "stream": false,
  "max_tokens": 5
}'

CHAT_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${AUTH_TOKEN:-sk-test}" \
    -d "$TEST_REQUEST")

HTTP_CODE=$(echo "$CHAT_RESPONSE" | tail -1)

if [ "$HTTP_CODE" = "200" ]; then
    print_status "$GREEN" "✅ /v1/chat/completions endpoint working"
elif [ "$HTTP_CODE" = "401" ]; then
    print_status "$YELLOW" "⚠️  Authentication required (HTTP 401)"
    print_status "$BLUE" "ℹ️  Set AUTH_TOKEN in .env or use SKIP_AUTH_TOKEN=true"
else
    print_status "$YELLOW" "⚠️  Chat completions returned HTTP $HTTP_CODE"
fi

# Test 6: Check token pool status
print_header "Test 6: Token Pool Status"
if [ -f .env ]; then
    source .env
    if [ -n "$ZAI_TOKEN" ]; then
        print_status "$GREEN" "✅ ZAI_TOKEN configured"
        TOKEN_PREVIEW="${ZAI_TOKEN:0:20}..."
        echo "   Preview: $TOKEN_PREVIEW"
    else
        print_status "$BLUE" "ℹ️  ZAI_TOKEN not set (anonymous mode)"
    fi
else
    print_status "$YELLOW" "⚠️  .env file not found"
fi

# Test 7: Check connectivity to chat.z.ai
print_header "Test 7: Upstream Connectivity"
if curl -s --connect-timeout 5 "https://chat.z.ai" > /dev/null 2>&1; then
    print_status "$GREEN" "✅ Can reach chat.z.ai"
else
    print_status "$RED" "❌ Cannot reach chat.z.ai"
    print_status "$YELLOW" "⚠️  Check network connectivity or proxy settings"
fi

# Summary
print_header "📊 Health Check Summary"

if [ "$ALL_SCHEMAS_EXIST" = true ] && [ "$ALL_DEPS_INSTALLED" = true ] && [ "$HTTP_CODE" = "200" ]; then
    print_status "$GREEN" "✅ All health checks passed!"
    print_status "$GREEN" "🎉 System is healthy and ready"
    exit 0
elif [ "$ALL_SCHEMAS_EXIST" = true ] && [ "$ALL_DEPS_INSTALLED" = true ]; then
    print_status "$YELLOW" "⚠️  System is partially healthy"
    print_status "$BLUE" "ℹ️  Server is running but some endpoints may need attention"
    exit 0
else
    print_status "$RED" "❌ System has issues that need attention"
    exit 1
fi

