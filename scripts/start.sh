#!/bin/bash
################################################################################
# start.sh - Start ZAI-API Server
# 
# This script:
# 1. Loads configuration from .env
# 2. Validates ZAI_TOKEN exists
# 3. Starts the FastAPI server with uvicorn
# 4. Monitors server health
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Starting ZAI-API Server                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ ERROR: .env file not found!${NC}"
    echo -e "${YELLOW}Please run ./setup.sh first to configure the environment${NC}"
    exit 1
fi

# Load environment variables
echo -e "${CYAN}📄 Loading configuration from .env...${NC}"
export $(grep -v '^#' .env | xargs)

# Validate required variables
echo -e "${CYAN}🔍 Validating configuration...${NC}"

if [ -z "$ZAI_TOKEN" ]; then
    echo -e "${RED}❌ ERROR: ZAI_TOKEN not found in .env!${NC}"
    echo -e "${YELLOW}Please run ./setup.sh to extract the Qwen token${NC}"
    exit 1
fi

if [ -z "$LISTEN_PORT" ]; then
    echo -e "${YELLOW}⚠️  LISTEN_PORT not set, using default: 8080${NC}"
    LISTEN_PORT=8080
fi

if [ -z "$AUTH_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  AUTH_TOKEN not set, using default: sk-123456${NC}"
    AUTH_TOKEN="sk-123456"
fi

echo -e "${GREEN}✓ Configuration validated${NC}"
echo ""

# Display configuration
echo -e "${CYAN}📋 Server Configuration:${NC}"
echo "----------------------------------------"
echo -e "  ${BLUE}Listen Port:${NC} $LISTEN_PORT"
echo -e "  ${BLUE}Auth Token:${NC} ${AUTH_TOKEN:0:10}..."
echo -e "  ${BLUE}ZAI Token:${NC} ${ZAI_TOKEN:0:20}..."
echo -e "  ${BLUE}Log Level:${NC} ${LOG_LEVEL:-info}"
echo -e "  ${BLUE}Toolify Enabled:${NC} ${ENABLE_TOOLIFY:-true}"
echo "----------------------------------------"
echo ""

# Check if server is already running
if [ -f server.pid ]; then
    OLD_PID=$(cat server.pid)
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Server already running (PID: $OLD_PID)${NC}"
        echo -e "${YELLOW}Stopping existing server...${NC}"
        kill $OLD_PID 2>/dev/null || true
        sleep 2
    fi
    rm -f server.pid
fi

# Clean up old logs
if [ -f server.log ]; then
    mv server.log "server.log.$(date +%Y%m%d_%H%M%S).old"
fi

# Start the server
echo -e "${GREEN}🚀 Starting FastAPI server...${NC}"
echo ""

# Start server in background
nohup python3 main.py > server.log 2>&1 &
SERVER_PID=$!

# Save PID
echo $SERVER_PID > server.pid

# Wait for server to start
echo -e "${CYAN}⏳ Waiting for server to initialize...${NC}"
sleep 3

# Check if process is running
if ! ps -p $SERVER_PID > /dev/null; then
    echo -e "${RED}❌ ERROR: Server failed to start!${NC}"
    echo -e "${YELLOW}Server log:${NC}"
    tail -20 server.log
    exit 1
fi

# Health check
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:$LISTEN_PORT/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Server is healthy!${NC}"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo -e "${YELLOW}Attempt $RETRY_COUNT/$MAX_RETRIES...${NC}"
    sleep 1
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}❌ ERROR: Server health check failed!${NC}"
    echo -e "${YELLOW}Server log:${NC}"
    tail -20 server.log
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ SERVER STARTED SUCCESSFULLY!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📊 Server Information:${NC}"
echo "----------------------------------------"
echo -e "  ${BLUE}PID:${NC} $SERVER_PID"
echo -e "  ${BLUE}URL:${NC} http://localhost:$LISTEN_PORT"
echo -e "  ${BLUE}Health:${NC} http://localhost:$LISTEN_PORT/health"
echo -e "  ${BLUE}Models:${NC} http://localhost:$LISTEN_PORT/v1/models"
echo -e "  ${BLUE}Log File:${NC} $SCRIPT_DIR/server.log"
echo "----------------------------------------"
echo ""
echo -e "${CYAN}📡 Available Endpoints:${NC}"
echo "  • GET  /health                 - Health check"
echo "  • GET  /v1/models              - List available models"
echo "  • POST /v1/chat/completions    - Chat completion (OpenAI compatible)"
echo ""
echo -e "${CYAN}💡 Usage Examples:${NC}"
echo ""
echo "  # Test health:"
echo "  curl http://localhost:$LISTEN_PORT/health"
echo ""
echo "  # List models:"
echo "  curl http://localhost:$LISTEN_PORT/v1/models \\"
echo "    -H \"Authorization: Bearer $AUTH_TOKEN\""
echo ""
echo "  # Chat completion:"
echo "  curl http://localhost:$LISTEN_PORT/v1/chat/completions \\"
echo "    -H \"Authorization: Bearer $AUTH_TOKEN\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"model\":\"GLM-4.5\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}]}'"
echo ""
echo -e "${CYAN}🔧 Management Commands:${NC}"
echo "  • View logs:   tail -f server.log"
echo "  • Stop server: kill $SERVER_PID"
echo "  • Restart:     ./start.sh"
echo ""
echo -e "${GREEN}Next step: Run ${YELLOW}./send_request.sh${GREEN} to test the API${NC}"
echo ""

