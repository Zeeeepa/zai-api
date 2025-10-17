#!/bin/bash
set -e

# =============================================================================
# ZAI-API All-in-One Script - Complete Pipeline
# =============================================================================
# This script runs the complete pipeline:
#   1. Setup (environment + dependencies + configuration)
#   2. Start (launch server with health checks)
#   3. Test (validate API functionality)
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper functions
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  $1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ Step $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo ""
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo ""
    echo -e "${RED}❌ $1${NC}"
}

# =============================================================================
# START PIPELINE
# =============================================================================

START_TIME=$(date +%s)

print_header "🚀 ZAI-API Complete Pipeline Execution"

echo "This will:"
echo "  1. Set up your environment (virtual env + dependencies)"
echo "  2. Start the API server (with health checks)"
echo "  3. Run comprehensive API tests"
echo ""
echo "Press Enter to continue or Ctrl+C to cancel..."
read

# =============================================================================
# STEP 1: SETUP
# =============================================================================

print_step "1/3: Environment Setup & Configuration"

if [ -f "$SCRIPT_DIR/setup.sh" ]; then
    bash "$SCRIPT_DIR/setup.sh"
    SETUP_RESULT=$?
    
    if [ $SETUP_RESULT -eq 0 ]; then
        print_success "Setup completed successfully"
    else
        print_error "Setup failed"
        exit 1
    fi
else
    print_error "setup.sh not found in $SCRIPT_DIR"
    exit 1
fi

# =============================================================================
# STEP 2: START SERVER
# =============================================================================

print_step "2/3: Start API Server"

if [ -f "$SCRIPT_DIR/start.sh" ]; then
    bash "$SCRIPT_DIR/start.sh"
    START_RESULT=$?
    
    if [ $START_RESULT -eq 0 ]; then
        print_success "Server started successfully"
    else
        print_error "Server failed to start"
        exit 1
    fi
else
    print_error "start.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Small delay to ensure server is fully ready
sleep 2

# =============================================================================
# STEP 3: TEST API
# =============================================================================

print_step "3/3: Run API Tests"

if [ -f "$SCRIPT_DIR/send_request.sh" ]; then
    bash "$SCRIPT_DIR/send_request.sh" "Write a haiku about code."
    TEST_RESULT=$?
    
    if [ $TEST_RESULT -eq 0 ]; then
        print_success "All tests passed"
    else
        print_error "Some tests failed"
        exit 1
    fi
else
    print_error "send_request.sh not found in $SCRIPT_DIR"
    exit 1
fi

# =============================================================================
# PIPELINE COMPLETE
# =============================================================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              🎉 Pipeline Completed Successfully! 🎉            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Summary:"
echo "  ⏱️  Total Time: ${DURATION}s"
echo "  ✅ Setup: Complete"
echo "  ✅ Server: Running"
echo "  ✅ Tests: Passed"
echo ""
echo "Your ZAI-API server is now running and ready to use!"
echo ""

# Load environment to get port
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi
SERVER_PORT="${SERVER_PORT:-${LISTEN_PORT:-8080}}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Quick Start Guide:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔗 Server URLs:"
echo "   Base:   http://localhost:$SERVER_PORT"
echo "   Health: http://localhost:$SERVER_PORT/health"
echo "   Models: http://localhost:$SERVER_PORT/v1/models"
echo "   Chat:   http://localhost:$SERVER_PORT/v1/chat/completions"
echo ""
echo "💻 Python Example:"
echo "   from openai import OpenAI"
echo "   client = OpenAI("
echo "       api_key=\"sk-any\","
echo "       base_url=\"http://localhost:$SERVER_PORT/v1\""
echo "   )"
echo "   response = client.chat.completions.create("
echo "       model=\"GLM-4.6\","
echo "       messages=[{\"role\": \"user\", \"content\": \"Hello!\"}]"
echo "   )"
echo "   print(response.choices[0].message.content)"
echo ""
echo "🔧 Management:"
echo "   View logs:  tail -f server.log"
echo "   Stop server: kill \$(cat .server.pid)"
echo "   Restart:     bash scripts/start.sh"
echo "   Test again:  bash scripts/send_request.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

