#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Set defaults if not provided
export ZAI_EMAIL="${ZAI_EMAIL:-developer@pixelium.uk}"
export ZAI_PASSWORD="${ZAI_PASSWORD:-developer123?}"
export SERVER_PORT="${SERVER_PORT:-7322}"
export ENABLE_FLAREPROX="${ENABLE_FLAREPROX:-false}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"

log_info "Configuration:"
log_info "  EMAIL: $ZAI_EMAIL"
log_info "  PORT: $SERVER_PORT"
log_info "  FLAREPROX: $ENABLE_FLAREPROX"
echo ""

# Step 1: Check Python version
log_info "Step 1/8: Checking Python version..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    log_info "✅ Python $PYTHON_VERSION found"
else
    log_error "Python 3 not found! Please install Python 3.8+"
    exit 1
fi

# Step 2: Clone or update repository
log_info "Step 2/8: Setting up repository..."
if [ -d "zai-api" ]; then
    log_info "Repository exists, pulling latest changes..."
    cd zai-api
    git fetch origin
    git checkout codegen-bot/integrate-flareprox-routing-1760647503 || {
        log_warn "Branch not found, using main"
        git checkout main
    }
    git pull
else
    log_info "Cloning repository..."
    git clone https://github.com/Zeeeepa/zai-api.git
    cd zai-api
    git checkout codegen-bot/integrate-flareprox-routing-1760647503 || {
        log_warn "Branch not found, using main"
        git checkout main
    }
fi

# Step 3: Create virtual environment
log_info "Step 3/8: Creating virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    log_info "✅ Virtual environment created"
else
    log_info "✅ Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate

# Step 4: Install dependencies
log_info "Step 4/8: Installing dependencies..."
pip install --upgrade pip > /dev/null 2>&1
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt > /dev/null 2>&1
    log_info "✅ Dependencies installed from requirements.txt"
else
    log_warn "requirements.txt not found, installing core dependencies..."
    pip install fastapi uvicorn httpx python-dotenv pydantic > /dev/null 2>&1
fi

# Step 5: Create .env file
log_info "Step 5/8: Creating .env configuration..."
cat > .env << ENV_EOF
# Authentication
ZAI_EMAIL=$ZAI_EMAIL
ZAI_PASSWORD=$ZAI_PASSWORD

# Server Configuration
SERVER_PORT=$SERVER_PORT
LOG_LEVEL=$LOG_LEVEL

# FlareProx Configuration
ENABLE_FLAREPROX=$ENABLE_FLAREPROX

# Optional: Cloudflare credentials (if FlareProx enabled)
# CLOUDFLARE_API_TOKEN=your_token_here
# CLOUDFLARE_ACCOUNT_ID=your_account_id_here
ENV_EOF
log_info "✅ Configuration saved to .env"

# Step 6: Kill any existing process on the port
log_info "Step 6/8: Checking for existing server on port $SERVER_PORT..."
if lsof -Pi :$SERVER_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    log_warn "Port $SERVER_PORT is in use, killing existing process..."
    kill -9 $(lsof -t -i:$SERVER_PORT) 2>/dev/null || true
    sleep 2
    log_info "✅ Port cleared"
else
    log_info "✅ Port $SERVER_PORT is available"
fi

# Step 7: Start the server in background
log_info "Step 7/8: Starting ZAI-API server..."
nohup python3 -m uvicorn main:app --host 0.0.0.0 --port $SERVER_PORT > server.log 2>&1 &
SERVER_PID=$!
log_info "✅ Server started with PID: $SERVER_PID"

# Wait for server to be ready
log_info "Waiting for server to initialize..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s http://localhost:$SERVER_PORT/health > /dev/null 2>&1; then
        log_info "✅ Server is ready!"
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
    echo -n "."
done
echo ""

if [ $WAITED -ge $MAX_WAIT ]; then
    log_error "Server failed to start within ${MAX_WAIT}s"
    log_error "Check logs: tail -f server.log"
    exit 1
fi

# Step 8: Test the server
log_info "Step 8/8: Testing server with OpenAI API call..."

# Create test script
cat > test_api.py << 'TEST_EOF'
import sys
from openai import OpenAI

try:
    client = OpenAI(
        api_key="sk-test-key",
        base_url=f"http://localhost:{sys.argv[1]}/v1"
    )
    
    print("🧪 Sending test request to server...")
    result = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": "Write a haiku about code."}],
        stream=False
    )
    
    print("\n✅ API Test Successful!")
    print(f"\n📝 Response:\n{result.choices[0].message.content}\n")
    sys.exit(0)
    
except Exception as e:
    print(f"\n❌ API Test Failed: {e}\n")
    sys.exit(1)
TEST_EOF

# Run the test
if python3 test_api.py $SERVER_PORT; then
    log_info "✅ All tests passed!"
else
    log_error "API test failed! Check logs: tail -f server.log"
    exit 1
fi

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
echo -e "  Restart: ${YELLOW}kill $SERVER_PID && bash deploy_zai_api_server.sh${NC}"
echo ""
echo -e "${BLUE}🧪 Test with Python:${NC}"
cat << 'PYTHON_TEST_EOF'
from openai import OpenAI
client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:SERVER_PORT/v1"
)
result = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(result.choices[0].message.content)
PYTHON_TEST_EOF
echo ""
echo -e "${GREEN}🎉 Ready to serve requests!${NC}"
echo ""
