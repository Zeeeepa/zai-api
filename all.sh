#!/bin/bash
################################################################################
# all.sh - Master Script to Run Complete ZAI-API Setup and Test
# 
# This script orchestrates the entire process:
# 1. Runs setup.sh    - Installs dependencies, gets Qwen token
# 2. Runs start.sh    - Starts the API server
# 3. Runs send_request.sh - Tests API with Graph-RAG question
# 
# Usage: ./all.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Banner
clear
echo ""
echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║                                                            ║${NC}"
echo -e "${BOLD}${BLUE}║            ZAI-API Complete Automation Suite               ║${NC}"
echo -e "${BOLD}${BLUE}║                                                            ║${NC}"
echo -e "${BOLD}${BLUE}║  Automated Setup → Server Start → API Testing             ║${NC}"
echo -e "${BOLD}${BLUE}║                                                            ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Prompt for credentials if not set
if [ ! -f .env ] || ! grep -q "QWEN_EMAIL" .env 2>/dev/null || ! grep -q "QWEN_PASSWORD" .env 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Qwen credentials not found in .env${NC}"
    echo ""
    read -p "Enter your Qwen email: " QWEN_EMAIL
    read -sp "Enter your Qwen password: " QWEN_PASSWORD
    echo ""
    echo ""
    
    # Create or update .env
    if [ -f .env ]; then
        echo "QWEN_EMAIL=$QWEN_EMAIL" >> .env
        echo "QWEN_PASSWORD=$QWEN_PASSWORD" >> .env
    else
        cp env_template.txt .env
        echo "" >> .env
        echo "# Qwen Credentials" >> .env
        echo "QWEN_EMAIL=$QWEN_EMAIL" >> .env
        echo "QWEN_PASSWORD=$QWEN_PASSWORD" >> .env
    fi
    
    export QWEN_EMAIL
    export QWEN_PASSWORD
fi

# Make scripts executable
chmod +x setup.sh start.sh send_request.sh

# Progress tracking
TOTAL_STEPS=3
CURRENT_STEP=0

function print_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    echo -e "${BOLD}${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${MAGENTA}║  STEP $CURRENT_STEP/$TOTAL_STEPS: $1${NC}"
    echo -e "${BOLD}${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

function print_success() {
    echo ""
    echo -e "${GREEN}✅ $1${NC}"
    echo ""
}

function print_error() {
    echo ""
    echo -e "${RED}❌ ERROR: $1${NC}"
    echo ""
    exit 1
}

# Confirm before starting
echo -e "${CYAN}This script will:${NC}"
echo "  1. Install all dependencies and extract Qwen token (Playwright automation)"
echo "  2. Start the OpenAI-compatible API server"
echo "  3. Test the API with a Graph-RAG question"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${BOLD}${CYAN}Starting automated workflow...${NC}"
sleep 2

# ============================================================================
# STEP 1: Setup
# ============================================================================
print_step "Running setup.sh - Installing dependencies & extracting token"

if ./setup.sh; then
    print_success "Setup completed successfully"
else
    print_error "Setup failed. Check the output above for details."
fi

sleep 2

# ============================================================================
# STEP 2: Start Server
# ============================================================================
print_step "Running start.sh - Starting API server"

if ./start.sh; then
    print_success "Server started successfully"
else
    print_error "Server startup failed. Check server.log for details."
fi

# Give server extra time to fully initialize
echo -e "${CYAN}⏳ Waiting for server to fully initialize...${NC}"
sleep 5

# ============================================================================
# STEP 3: Send Test Request
# ============================================================================
print_step "Running send_request.sh - Testing API with Graph-RAG question"

if ./send_request.sh; then
    print_success "API test completed successfully"
else
    print_error "API test failed. Check the output above for details."
fi

# ============================================================================
# Final Summary
# ============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║                                                            ║${NC}"
echo -e "${BOLD}${GREEN}║              ✅ ALL STEPS COMPLETED SUCCESSFULLY!           ║${NC}"
echo -e "${BOLD}${GREEN}║                                                            ║${NC}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Display summary
echo -e "${CYAN}📊 Summary:${NC}"
echo "════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}✓${NC} Dependencies installed"
echo -e "  ${GREEN}✓${NC} Qwen token extracted and saved"
echo -e "  ${GREEN}✓${NC} API server running"
echo -e "  ${GREEN}✓${NC} OpenAI-compatible API tested"
echo -e "  ${GREEN}✓${NC} Graph-RAG question answered"
echo "════════════════════════════════════════════════════════════"
echo ""

# Display server info
if [ -f server.pid ]; then
    SERVER_PID=$(cat server.pid)
    export $(grep -v '^#' .env | xargs)
    LISTEN_PORT=${LISTEN_PORT:-8080}
    
    echo -e "${CYAN}🚀 Server Information:${NC}"
    echo "----------------------------------------"
    echo -e "  ${BLUE}Status:${NC} Running (PID: $SERVER_PID)"
    echo -e "  ${BLUE}URL:${NC} http://localhost:$LISTEN_PORT"
    echo -e "  ${BLUE}Health:${NC} http://localhost:$LISTEN_PORT/health"
    echo -e "  ${BLUE}Models:${NC} http://localhost:$LISTEN_PORT/v1/models"
    echo "----------------------------------------"
    echo ""
fi

# Display useful commands
echo -e "${CYAN}💡 Useful Commands:${NC}"
echo ""
echo "  # View server logs:"
echo "  tail -f server.log"
echo ""
echo "  # Stop server:"
echo "  kill \$(cat server.pid)"
echo ""
echo "  # Test API again:"
echo "  ./send_request.sh"
echo ""
echo "  # Restart server:"
echo "  ./start.sh"
echo ""
echo "  # View last response:"
echo "  cat last_response.json | jq ."
echo ""

echo -e "${BOLD}${GREEN}🎉 Your ZAI-API is ready for production use!${NC}"
echo ""

