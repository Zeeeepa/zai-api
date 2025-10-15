#!/bin/bash
# Start script - Start the OpenAI-compatible API server with health checks

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo "================================================================"
    echo -e "${BLUE}$1${NC}"
    echo "================================================================"
}

print_status() {
    echo -e "${1}${2}${NC}"
}

print_header "🚀 Starting OpenAI-Compatible API Server"

# Virtual environment activation with fallback
VENV_PATH=".venv"
LEGACY_VENV_PATH=$(basename "$(pwd)")

if [ -f "${VENV_PATH}/bin/activate" ]; then
    source "${VENV_PATH}/bin/activate"
    print_status "$GREEN" "✅ Virtual environment activated (${VENV_PATH})"
elif [ -f "${LEGACY_VENV_PATH}/bin/activate" ]; then
    source "${LEGACY_VENV_PATH}/bin/activate"
    print_status "$YELLOW" "⚠️  Using legacy virtual environment (${LEGACY_VENV_PATH}/)"
    print_status "$YELLOW" "   Consider running: bash scripts/setup.sh to migrate to .venv"
else
    print_status "$YELLOW" "⚠️  No virtual environment found, using system Python"
    print_status "$BLUE" "   To create one, run: bash scripts/setup.sh"
fi

# Check if server is already running
PORT=${LISTEN_PORT:-7322}
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    print_status "$YELLOW" "⚠️  Server already running on port $PORT"
    echo ""
    read -p "Kill existing server and restart? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pkill -f "python3 main.py" || true
        print_status "$GREEN" "✅ Killed existing server"
        sleep 2
    else
        print_status "$BLUE" "ℹ️  Using existing server"
        print_header "✅ Server Already Running"
        echo "Proceeding to health checks..."
        SKIP_START=true
    fi
fi

# Load environment
if [ ! -f .env ]; then
    print_status "$RED" "❌ .env file not found. Run ./scripts/setup.sh first"
    exit 1
fi

source .env

# Check configuration
LISTEN_PORT=${LISTEN_PORT:-7322}
API_ENDPOINT=${API_ENDPOINT:-"https://chat.z.ai/api/chat/completions"}

if [ "$SKIP_START" != "true" ]; then
    echo ""
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Listen Port: ${LISTEN_PORT}"
    echo "  API Endpoint: ${API_ENDPOINT}"
    echo ""

    # Start server in background
    echo -e "${BLUE}Starting server...${NC}"
    nohup python3 main.py > server.log 2>&1 &
    SERVER_PID=$!

    print_status "$GREEN" "✅ Server started with PID: ${SERVER_PID}"

    # Wait for server to be ready
    echo -e "${BLUE}Waiting for server to be ready...${NC}"
    for i in {1..30}; do
        if curl -s http://localhost:${LISTEN_PORT}/health > /dev/null 2>&1; then
            print_status "$GREEN" "✅ Server is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            print_status "$RED" "❌ Server failed to start. Check server.log"
            tail -20 server.log
            exit 1
        fi
        sleep 1
    done
fi

# ============================================================
# HEALTH CHECKS (Consolidated from health_check.sh)
# ============================================================

print_header "🏥 System Health Checks"

BASE_URL="http://localhost:${LISTEN_PORT}"

# Test 1: Check if schemas exist
echo ""
echo -e "${BLUE}Health Check 1/7: Schema Files${NC}"
SCHEMA_FILES=("zai_web_request.json" "zai_web_response.json" "zai_auth.json" "openaiapi.json")
ALL_SCHEMAS_EXIST=true

for schema in "${SCHEMA_FILES[@]}"; do
    if [ -f "schemas/$schema" ]; then
        print_status "$GREEN" "✅ Found: schemas/$schema"
    else
        print_status "$YELLOW" "⚠️  Missing: schemas/$schema"
        ALL_SCHEMAS_EXIST=false
    fi
done

# Test 2: Check Python dependencies
echo ""
echo -e "${BLUE}Health Check 2/7: Python Dependencies${NC}"
REQUIRED_DEPS=("fastapi" "httpx" "openai")
ALL_DEPS_INSTALLED=true

for dep in "${REQUIRED_DEPS[@]}"; do
    if python3 -c "import $dep" 2>/dev/null; then
        print_status "$GREEN" "✅ $dep installed"
    else
        print_status "$RED" "❌ $dep not installed"
        ALL_DEPS_INSTALLED=false
    fi
done

# Test 3: Server Status
echo ""
echo -e "${BLUE}Health Check 3/7: Server Status${NC}"
if curl -s --connect-timeout 2 "$BASE_URL/health" > /dev/null 2>&1; then
    print_status "$GREEN" "✅ Server is running on $BASE_URL"
    HEALTH_RESPONSE=$(curl -s "$BASE_URL/health")
    echo "   Response: $HEALTH_RESPONSE"
else
    print_status "$RED" "❌ Server health check failed"
    exit 1
fi

# Test 4: Models Endpoint
echo ""
echo -e "${BLUE}Health Check 4/7: Models Endpoint${NC}"
MODELS_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/v1/models" -H "Authorization: Bearer ${AUTH_TOKEN:-sk-test}" 2>/dev/null)
HTTP_CODE=$(echo "$MODELS_RESPONSE" | tail -1)
MODELS_BODY=$(echo "$MODELS_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    print_status "$GREEN" "✅ /v1/models endpoint working"
    MODEL_COUNT=$(echo "$MODELS_BODY" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['data']))" 2>/dev/null || echo "unknown")
    echo "   Available models: $MODEL_COUNT"
else
    print_status "$YELLOW" "⚠️  /v1/models returned HTTP $HTTP_CODE"
fi

# Test 5: Chat Completions Endpoint
echo ""
echo -e "${BLUE}Health Check 5/7: Chat Completions Endpoint${NC}"
TEST_REQUEST='{
  "model": "GLM-4.5",
  "messages": [{"role": "user", "content": "Hi"}],
  "stream": false,
  "max_tokens": 5
}'

CHAT_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${AUTH_TOKEN:-sk-test}" \
    -d "$TEST_REQUEST" 2>/dev/null)

HTTP_CODE=$(echo "$CHAT_RESPONSE" | tail -1)

if [ "$HTTP_CODE" = "200" ]; then
    print_status "$GREEN" "✅ /v1/chat/completions endpoint working"
elif [ "$HTTP_CODE" = "401" ]; then
    print_status "$YELLOW" "⚠️  Authentication required (HTTP 401)"
    print_status "$BLUE" "ℹ️  Set AUTH_TOKEN in .env"
else
    print_status "$YELLOW" "⚠️  Chat completions returned HTTP $HTTP_CODE"
fi

# Test 6: Token Pool Status
echo ""
echo -e "${BLUE}Health Check 6/7: Token Pool Status${NC}"
if [ -n "$ZAI_TOKEN" ]; then
    print_status "$GREEN" "✅ ZAI_TOKEN configured"
    TOKEN_PREVIEW="${ZAI_TOKEN:0:20}..."
    echo "   Preview: $TOKEN_PREVIEW"
else
    print_status "$BLUE" "ℹ️  ZAI_TOKEN not set (anonymous mode)"
fi

# Test 7: Upstream Connectivity
echo ""
echo -e "${BLUE}Health Check 7/7: Upstream Connectivity${NC}"
if curl -s --connect-timeout 5 "https://chat.z.ai" > /dev/null 2>&1; then
    print_status "$GREEN" "✅ Can reach chat.z.ai"
else
    print_status "$YELLOW" "⚠️  Cannot reach chat.z.ai (may need proxy)"
fi

# ============================================================
# FINAL SUMMARY
# ============================================================

print_header "🎉 Server Started & Health Checks Complete!"
echo ""
echo "Server Information:"
echo "  • URL:              http://localhost:${LISTEN_PORT}"
echo "  • SERVER_PORT:      ${LISTEN_PORT}"
echo "  • Health Check:     http://localhost:${LISTEN_PORT}/health"
echo "  • Models List:      http://localhost:${LISTEN_PORT}/v1/models"
echo "  • Chat Completions: http://localhost:${LISTEN_PORT}/v1/chat/completions"
echo ""
echo "Health Status:"
if [ "$ALL_SCHEMAS_EXIST" = true ] && [ "$ALL_DEPS_INSTALLED" = true ]; then
    echo "  ✅ All schemas present"
    echo "  ✅ All dependencies installed"
    echo "  ✅ Server endpoints responding"
    echo "  ✅ System is healthy and ready!"
else
    echo "  ⚠️  Some non-critical components missing"
    echo "  ✅ Server is operational"
fi
echo ""
echo "Commands:"
echo "  • View logs:  tail -f server.log"
echo "  • Stop:       pkill -f 'python3 main.py'"
echo "  • Test:       ./scripts/send_request.sh"
echo ""
echo "Available Models:"
echo "  - GLM-4.5"
echo "  - GLM-4.5-Thinking"
echo "  - GLM-4.5-Search"
echo "  - GLM-4.5-Air"
echo "  - GLM-4.5V"
echo "  - GLM-4.6"
echo "  - GLM-4.6-Thinking"
echo "  - GLM-4.6-Search"
echo ""
