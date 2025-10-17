#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}🚀 ZAI-API Server Auto-Deployment Script${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Function to log with timestamp
log_info() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"
}

log_success() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')] ✅ $1${NC}"
}

# Set defaults if not provided
export ZAI_EMAIL="${ZAI_EMAIL:-}"
export ZAI_PASSWORD="${ZAI_PASSWORD:-}"
export SERVER_PORT="${SERVER_PORT:-7321}"
export ENABLE_FLAREPROX="${ENABLE_FLAREPROX:-false}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"

log_info "Configuration:"
log_info "  EMAIL: ${ZAI_EMAIL:-<not set>}"
log_info "  PORT: $SERVER_PORT"
log_info "  FLAREPROX: $ENABLE_FLAREPROX"
echo ""

# Step 1: Check Python version
log_info "Step 1/6: Checking Python version..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    log_success "Python $PYTHON_VERSION found"
else
    log_error "Python 3 not found! Please install Python 3.8+"
    exit 1
fi

# Step 2: Clone or update repository
log_info "Step 2/6: Setting up repository..."
if [ -d "zai-api" ]; then
    log_info "Repository exists, pulling latest changes..."
    cd zai-api
    git fetch origin
    git checkout main
    git pull
else
    log_info "Cloning repository..."
    git clone https://github.com/Zeeeepa/zai-api.git
    cd zai-api
fi

log_success "Repository ready"

# Step 3: Run setup script
log_info "Step 3/6: Running setup (creating venv, installing dependencies)..."
export SETUP_NON_INTERACTIVE=1
if [ -f "scripts/setup.sh" ]; then
    # Run setup in non-interactive mode
    echo "3" | bash scripts/setup.sh > /tmp/setup.log 2>&1
    if [ $? -eq 0 ]; then
        log_success "Setup completed successfully"
    else
        log_error "Setup failed! Check /tmp/setup.log for details"
        exit 1
    fi
else
    log_error "scripts/setup.sh not found!"
    exit 1
fi

# Step 4: Update .env with user-provided values
log_info "Step 4/6: Configuring environment..."

# Source the venv
source .venv/bin/activate

# Update .env file
if [ -n "$ZAI_EMAIL" ] && [ -n "$ZAI_PASSWORD" ]; then
    log_info "Configuring authentication with provided credentials..."
    
    # Update or add EMAIL and PASSWORD
    sed -i.bak "s/^ZAI_EMAIL=.*/ZAI_EMAIL=$ZAI_EMAIL/" .env || echo "ZAI_EMAIL=$ZAI_EMAIL" >> .env
    sed -i.bak "s/^ZAI_PASSWORD=.*/ZAI_PASSWORD=$ZAI_PASSWORD/" .env || echo "ZAI_PASSWORD=$ZAI_PASSWORD" >> .env
fi

# Update port
sed -i.bak "s/^LISTEN_PORT=.*/LISTEN_PORT=$SERVER_PORT/" .env || echo "LISTEN_PORT=$SERVER_PORT" >> .env
sed -i.bak "s/^SERVER_PORT=.*/SERVER_PORT=$SERVER_PORT/" .env || echo "SERVER_PORT=$SERVER_PORT" >> .env

# Update FlareProx setting
sed -i.bak "s/^ENABLE_FLAREPROX=.*/ENABLE_FLAREPROX=$ENABLE_FLAREPROX/" .env || echo "ENABLE_FLAREPROX=$ENABLE_FLAREPROX" >> .env

log_success "Environment configured"

# Step 5: Stop any existing server on the port
log_info "Step 5/6: Checking for existing server on port $SERVER_PORT..."
if lsof -Pi :$SERVER_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    log_warn "Port $SERVER_PORT is in use, killing existing process..."
    kill -9 $(lsof -t -i:$SERVER_PORT) 2>/dev/null || true
    sleep 2
    log_success "Port cleared"
else
    log_success "Port $SERVER_PORT is available"
fi

# Step 6: Start the server
log_info "Step 6/6: Starting ZAI-API server..."

# Start server in background
nohup python3 main.py > server.log 2>&1 &
SERVER_PID=$!
log_success "Server started with PID: $SERVER_PID"

# Wait for server to be ready
log_info "Waiting for server to initialize..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s http://localhost:$SERVER_PORT/health > /dev/null 2>&1; then
        log_success "Server is ready!"
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
    echo -n "."
done
echo ""

if [ $WAITED -ge $MAX_WAIT ]; then
    log_error "Server failed to start within ${MAX_WAIT}s"
    log_error "Check logs: tail -f $(pwd)/server.log"
    exit 1
fi

# Test the server
log_info "Testing server with health check..."
HEALTH_RESPONSE=$(curl -s http://localhost:$SERVER_PORT/health)
echo "$HEALTH_RESPONSE" | python3 -m json.tool

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}✨ ZAI-API Server Successfully Deployed! ✨${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""
echo -e "${BLUE}📊 Server Information:${NC}"
echo -e "  🌐 Base URL: http://localhost:$SERVER_PORT"
echo -e "  📋 Health Check: http://localhost:$SERVER_PORT/health"
echo -e "  📖 API Docs: http://localhost:$SERVER_PORT/docs"
echo -e "  🔧 Process ID: $SERVER_PID"
echo ""
echo -e "${BLUE}📝 Useful Commands:${NC}"
echo -e "  View logs: ${YELLOW}tail -f $(pwd)/server.log${NC}"
echo -e "  Stop server: ${YELLOW}kill $SERVER_PID${NC}"
echo ""
echo -e "${BLUE}🧪 Test with Python:${NC}"
cat << 'PYTHON_TEST_EOF'
from openai import OpenAI
client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:SERVER_PORT/v1"
)
result = client.chat.completions.create(
    model="GLM-4.6",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(result.choices[0].message.content)
PYTHON_TEST_EOF
echo ""
echo -e "${GREEN}🎉 Ready to serve requests!${NC}"
echo ""

