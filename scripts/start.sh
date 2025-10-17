#!/bin/bash
set -e

# =============================================================================
# ZAI-API Start Script - Start API Server with Health Checks
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# =============================================================================
# PART 1: ENVIRONMENT ACTIVATION
# =============================================================================

print_header "Starting ZAI-API Server"

# Virtual environment activation with fallback
VENV_PATH=".venv"
LEGACY_VENV="zai-api"

if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    print_status "Virtual environment activated (.venv)"
elif [ -f "$LEGACY_VENV/bin/activate" ]; then
    source "$LEGACY_VENV/bin/activate"
    print_warning "Using legacy virtual environment ($LEGACY_VENV) - consider migrating to .venv"
else
    print_warning "No virtual environment found - using system Python"
    print_warning "Run 'bash scripts/setup.sh' to create virtual environment"
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set default port if not configured
if [ -z "$SERVER_PORT" ]; then
    export SERVER_PORT="${LISTEN_PORT:-8080}"
fi

# =============================================================================
# PART 2: PRE-FLIGHT CHECKS
# =============================================================================

echo ""
echo "Pre-flight checks..."

# Check if server is already running
if lsof -Pi :$SERVER_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    PID=$(lsof -Pi :$SERVER_PORT -sTCP:LISTEN -t)
    print_warning "Server already running on port $SERVER_PORT (PID: $PID)"
    echo ""
    echo "Options:"
    echo "  1. Kill existing server and restart"
    echo "  2. Keep existing server running"
    echo "  3. Exit"
    echo ""
    read -p "Choose [1-3]: " choice
    
    case $choice in
        1)
            kill $PID
            sleep 2
            print_status "Existing server stopped"
            ;;
        2)
            print_status "Keeping existing server - checking health..."
            # Skip to health check section
            SKIP_START=true
            ;;
        *)
            echo "Exiting..."
            exit 0
            ;;
    esac
fi

# Check Python dependencies
if ! python3 -c "import fastapi, httpx" &> /dev/null; then
    print_error "Missing Python dependencies"
    echo "Run: bash scripts/setup.sh"
    exit 1
fi

# Check main.py exists
if [ ! -f "main.py" ]; then
    print_error "main.py not found!"
    exit 1
fi

print_status "Pre-flight checks passed"

# =============================================================================
# PART 3: START SERVER
# =============================================================================

if [ "$SKIP_START" != "true" ]; then
    echo ""
    print_header "Starting Server"
    
    # Start server in background
    echo "Launching server on port $SERVER_PORT..."
    nohup python3 main.py > server.log 2>&1 &
    SERVER_PID=$!
    
    # Save PID to file
    echo $SERVER_PID > .server.pid
    
    print_status "Server started with PID: $SERVER_PID"
    print_status "Logs: server.log"
    
    # Wait for server to be ready
    echo ""
    echo "Waiting for server to be ready..."
    MAX_WAIT=30
    WAITED=0
    
    while ! curl -s http://localhost:$SERVER_PORT/health > /dev/null 2>&1; do
        if [ $WAITED -ge $MAX_WAIT ]; then
            print_error "Server failed to start after ${MAX_WAIT}s"
            echo "Check logs: tail -f server.log"
            exit 1
        fi
        echo -n "."
        sleep 1
        WAITED=$((WAITED + 1))
    done
    
    echo ""
    print_status "Server is ready!"
fi

# =============================================================================
# PART 4: HEALTH CHECKS
# =============================================================================

echo ""
print_header "Health Checks"

# Health check endpoint
HEALTH_RESPONSE=$(curl -s http://localhost:$SERVER_PORT/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    print_status "Health check passed"
else
    print_error "Health check failed"
    exit 1
fi

# Models endpoint
MODELS_RESPONSE=$(curl -s http://localhost:$SERVER_PORT/v1/models)
if echo "$MODELS_RESPONSE" | grep -q "GLM"; then
    print_status "Models endpoint working"
    
    # Extract and display available models
    echo ""
    echo "Available Models:"
    echo "$MODELS_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for model in data.get('data', []):
        print(f\"  - {model.get('id', 'unknown')}\")
except:
    pass
" 2>/dev/null || echo "  (Could not parse model list)"
else
    print_warning "Models endpoint returned unexpected response"
fi

# =============================================================================
# SERVER INFO
# =============================================================================

echo ""
print_header "🎉 Server Running Successfully!"
echo ""
echo "Server Information:"
echo "  🌐 Base URL: http://localhost:$SERVER_PORT"
echo "  📡 Health: http://localhost:$SERVER_PORT/health"
echo "  🤖 Models: http://localhost:$SERVER_PORT/v1/models"
echo "  💬 Chat: http://localhost:$SERVER_PORT/v1/chat/completions"
echo ""
echo "  📋 PID: $(cat .server.pid 2>/dev/null || echo $SERVER_PID)"
echo "  📝 Logs: server.log"
echo ""
echo "Quick Test:"
echo '  curl -X POST http://localhost:'$SERVER_PORT'/v1/chat/completions \'
echo '    -H "Content-Type: application/json" \'
echo '    -H "Authorization: Bearer sk-any" \'
echo "    -d '{\"model\": \"GLM-4.6\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]}'"
echo ""
echo "Python Test:"
echo "  bash scripts/send_request.sh"
echo ""
echo "Stop Server:"
echo "  kill \$(cat .server.pid)"
echo "  # or"
echo "  pkill -f 'python3 main.py'"
echo ""

