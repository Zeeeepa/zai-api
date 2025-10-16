#!/bin/bash

# Enhanced server startup script with comprehensive status monitoring
# This script starts the server, monitors health, and tests API functionality

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
VENV_PATH=".venv"
SERVER_LOG="server.log"
PID_FILE=".server.pid"
HEALTH_ENDPOINT="http://localhost:8080/health"
API_ENDPOINT="http://localhost:8080/v1/chat/completions"

print_status() {
    echo -e "${1}${2}${NC}"
}

print_header() {
    echo ""
    echo "================================================================"
    echo -e "${CYAN}$1${NC}"
    echo "================================================================"
    echo ""
}

# Check if server is already running
check_existing_server() {
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            print_status "$YELLOW" "⚠️  Server already running (PID: $OLD_PID)"
            read -p "Stop existing server and restart? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                kill "$OLD_PID" 2>/dev/null || true
                sleep 2
                rm -f "$PID_FILE"
            else
                print_status "$BLUE" "ℹ️  Exiting without changes"
                exit 0
            fi
        else
            rm -f "$PID_FILE"
        fi
    fi
}

# Activate virtual environment
activate_venv() {
    if [ -f "${VENV_PATH}/bin/activate" ]; then
        source "${VENV_PATH}/bin/activate"
        print_status "$GREEN" "✅ Virtual environment activated"
    else
        print_status "$RED" "❌ Virtual environment not found at ${VENV_PATH}"
        print_status "$YELLOW" "   Run: bash scripts/all.sh first"
        exit 1
    fi
}

# Load and validate configuration
load_config() {
    if [ ! -f .env ]; then
        print_status "$RED" "❌ .env file not found"
        exit 1
    fi
    
    source .env
    
    print_header "📋 Configuration"
    
    # API Endpoint
    print_status "$BLUE" "API Endpoint:"
    print_status "$GREEN" "   ${API_ENDPOINT:-Not configured}"
    
    # Port
    LISTEN_PORT=${LISTEN_PORT:-8080}
    print_status "$BLUE" "Listen Port:"
    print_status "$GREEN" "   ${LISTEN_PORT}"
    
    # Authentication
    print_status "$BLUE" "Authentication:"
    if [ -n "$AUTH_TOKEN" ]; then
        TOKEN_PREVIEW="${AUTH_TOKEN:0:15}...${AUTH_TOKEN: -5}"
        print_status "$GREEN" "   Required (${TOKEN_PREVIEW})"
    else
        print_status "$YELLOW" "   Any key accepted (guest mode)"
    fi
    
    # FlareProx
    print_status "$BLUE" "FlareProx IP Rotation:"
    if [ "$ENABLE_FLAREPROX" = "true" ]; then
        print_status "$GREEN" "   Enabled"
        if [ -n "$CLOUDFLARE_API_TOKEN" ] && [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
            ACCOUNT_PREVIEW="${CLOUDFLARE_ACCOUNT_ID:0:8}...${CLOUDFLARE_ACCOUNT_ID: -4}"
            print_status "$GREEN" "   Account: ${ACCOUNT_PREVIEW}"
        else
            print_status "$YELLOW" "   ⚠️  Cloudflare credentials missing"
        fi
    else
        print_status "$BLUE" "   Disabled"
    fi
    
    # Features
    print_status "$BLUE" "Features:"
    [ "$ENABLE_GUEST_TOKEN" = "true" ] && print_status "$GREEN" "   ✅ Guest Tokens"
    [ "$ENABLE_TOOLIFY" = "true" ] && print_status "$GREEN" "   ✅ Tool Calling"
    
    echo ""
}

# Start the server
start_server() {
    print_header "🚀 Starting Server"
    
    # Clean old logs
    rm -f "$SERVER_LOG"
    
    # Start server in background
    python3 main.py > "$SERVER_LOG" 2>&1 &
    SERVER_PID=$!
    echo "$SERVER_PID" > "$PID_FILE"
    
    print_status "$BLUE" "Server process started (PID: $SERVER_PID)"
    print_status "$BLUE" "Waiting for server to initialize..."
    
    # Wait for server to start (max 30 seconds)
    for i in {1..30}; do
        if curl -s "$HEALTH_ENDPOINT" > /dev/null 2>&1; then
            print_status "$GREEN" "✅ Server is ready!"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    echo ""
    print_status "$RED" "❌ Server failed to start within 30 seconds"
    print_status "$YELLOW" "   Check logs: tail -f $SERVER_LOG"
    cat "$SERVER_LOG"
    exit 1
}

# Check server health
check_health() {
    print_header "🏥 Health Check"
    
    HEALTH_RESPONSE=$(curl -s "$HEALTH_ENDPOINT")
    
    if [ $? -eq 0 ]; then
        print_status "$GREEN" "✅ Server is healthy"
        echo ""
        print_status "$BLUE" "Health Status:"
        echo "$HEALTH_RESPONSE" | python3 -m json.tool | sed 's/^/   /'
        
        # Parse FlareProx status
        FLAREPROX_ENABLED=$(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('flareprox', {}).get('enabled', False))")
        if [ "$FLAREPROX_ENABLED" = "True" ]; then
            WORKERS=$(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; fp=json.load(sys.stdin).get('flareprox', {}); print(f\"{fp.get('healthy_workers', 0)}/{fp.get('total_workers', 0)}\")")
            print_status "$GREEN" "\n   FlareProx: $WORKERS workers active"
        fi
    else
        print_status "$RED" "❌ Health check failed"
        return 1
    fi
}

# Test API with a simple request
test_api() {
    print_header "🧪 API Test"
    
    print_status "$BLUE" "Sending test request..."
    print_status "$BLUE" "Model: GLM-4.5"
    print_status "$BLUE" "Question: What is 2+2?"
    echo ""
    
    API_RESPONSE=$(curl -s "$API_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer test-key" \
        -d '{
            "model": "GLM-4.5",
            "messages": [
                {"role": "user", "content": "What is 2+2? Answer briefly."}
            ]
        }' 2>&1)
    
    if [ $? -eq 0 ]; then
        # Check if response contains expected fields
        if echo "$API_RESPONSE" | grep -q "\"choices\""; then
            ANSWER=$(echo "$API_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null)
            TOKENS=$(echo "$API_RESPONSE" | python3 -c "import sys, json; u=json.load(sys.stdin).get('usage',{}); print(f\"{u.get('total_tokens',0)}\")" 2>/dev/null)
            
            print_status "$GREEN" "✅ API Test Successful!"
            echo ""
            print_status "$CYAN" "Response:"
            print_status "$GREEN" "   Answer: ${ANSWER}"
            print_status "$BLUE" "   Tokens: ${TOKENS}"
            
            echo ""
            print_status "$BLUE" "Full Response:"
            echo "$API_RESPONSE" | python3 -m json.tool | sed 's/^/   /'
        else
            print_status "$YELLOW" "⚠️  Unexpected response format"
            echo "$API_RESPONSE" | head -20
        fi
    else
        print_status "$RED" "❌ API request failed"
        echo "$API_RESPONSE"
        return 1
    fi
}

# Display server info
show_server_info() {
    print_header "📊 Server Information"
    
    print_status "$GREEN" "✅ Server is running successfully!"
    echo ""
    
    print_status "$CYAN" "Connection Details:"
    print_status "$BLUE" "   Base URL: http://localhost:${LISTEN_PORT}"
    print_status "$BLUE" "   API Endpoint: http://localhost:${LISTEN_PORT}/v1/chat/completions"
    print_status "$BLUE" "   Health Check: http://localhost:${LISTEN_PORT}/health"
    echo ""
    
    print_status "$CYAN" "Example Usage:"
    echo ""
    print_status "$BLUE" "   # Python"
    echo '   from openai import OpenAI'
    echo "   client = OpenAI(base_url='http://localhost:${LISTEN_PORT}/v1', api_key='any-key')"
    echo "   response = client.chat.completions.create(model='GLM-4.5', messages=[...])"
    echo ""
    
    print_status "$BLUE" "   # curl"
    echo "   curl http://localhost:${LISTEN_PORT}/v1/chat/completions \\"
    echo '     -H "Authorization: Bearer your-key" \\'
    echo '     -H "Content-Type: application/json" \\'
    echo '     -d '\''{"model":"GLM-4.5","messages":[{"role":"user","content":"Hello"}]}'\'''
    echo ""
    
    print_status "$CYAN" "Management:"
    print_status "$BLUE" "   View logs: tail -f $SERVER_LOG"
    print_status "$BLUE" "   Stop server: kill $(cat $PID_FILE) || pkill -f 'python3 main.py'"
    print_status "$BLUE" "   Restart: bash scripts/start_server.sh"
    echo ""
}

# Main execution
main() {
    print_header "🔧 ZAI-API Server Startup"
    
    # Pre-flight checks
    check_existing_server
    activate_venv
    load_config
    
    # Start and validate
    start_server
    sleep 2
    check_health
    
    # Test functionality
    test_api
    
    # Show info
    show_server_info
    
    print_status "$GREEN" "================================================================"
    print_status "$GREEN" "🎉 Server is ready to accept requests!"
    print_status "$GREEN" "================================================================"
}

# Run main
main

