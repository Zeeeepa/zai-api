#!/bin/bash
# Start script - Start the OpenAI-compatible API server

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================================"
echo -e "${BLUE}🚀 Starting OpenAI-Compatible API Server${NC}"
echo "================================================================"

# Check if server is already running
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Server already running on port 8080${NC}"
    echo ""
    read -p "Kill existing server and restart? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pkill -f "python3 main.py" || true
        echo -e "${GREEN}✅ Killed existing server${NC}"
        sleep 2
    else
        echo -e "${BLUE}ℹ️  Using existing server${NC}"
        exit 0
    fi
fi

# Load environment
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found. Run ./scripts/setup.sh first${NC}"
    exit 1
fi

source .env

# Check configuration
LISTEN_PORT=${LISTEN_PORT:-8080}
API_ENDPOINT=${API_ENDPOINT:-"https://chat.z.ai/api/chat/completions"}

echo -e "${BLUE}Configuration:${NC}"
echo "  Listen Port: ${LISTEN_PORT}"
echo "  API Endpoint: ${API_ENDPOINT}"
echo ""

# Start server in background
echo -e "${BLUE}Starting server...${NC}"
nohup python3 main.py > server.log 2>&1 &
SERVER_PID=$!

echo -e "${GREEN}✅ Server started with PID: ${SERVER_PID}${NC}"

# Wait for server to be ready
echo -e "${BLUE}Waiting for server to be ready...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:${LISTEN_PORT}/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Server is ready!${NC}"
        echo ""
        echo "================================================================"
        echo -e "${GREEN}🎉 Server running on http://localhost:${LISTEN_PORT}${NC}"
        echo "================================================================"
        echo ""
        echo "OpenAI-Compatible Endpoints:"
        echo "  • Health Check:     http://localhost:${LISTEN_PORT}/health"
        echo "  • Models List:      http://localhost:${LISTEN_PORT}/v1/models"
        echo "  • Chat Completions: http://localhost:${LISTEN_PORT}/v1/chat/completions"
        echo ""
        echo "Logs: tail -f server.log"
        echo "Stop: pkill -f 'python3 main.py'"
        echo ""
        exit 0
    fi
    sleep 1
done

echo -e "${RED}❌ Server failed to start. Check server.log${NC}"
tail -20 server.log
exit 1

