#!/bin/bash
# All-in-one script - Complete pipeline: setup → start → send request

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "================================================================"
echo -e "${CYAN}🚀 Complete Pipeline Execution${NC}"
echo "================================================================"
echo ""

# Step 1: Setup (includes token validation)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 1/3: Environment Setup & Token Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if ./scripts/setup.sh; then
    echo -e "${GREEN}✅ Setup & validation completed${NC}"
else
    echo -e "${RED}❌ Setup failed${NC}"
    exit 1
fi

echo ""
sleep 2

# Step 2: Start Server (includes health checks)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 2/3: Start Server & Health Checks${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if ./scripts/start.sh; then
    echo -e "${GREEN}✅ Server started & health checks passed${NC}"
else
    echo -e "${RED}❌ Server failed to start${NC}"
    exit 1
fi

echo ""
sleep 2

# Step 3: Send Request
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 3/3: Send Test Request${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Allow custom question via argument
QUESTION=${1:-"What is Graph-Sitter?"}

if ./scripts/send_request.sh "$QUESTION"; then
    echo -e "${GREEN}✅ Request completed${NC}"
else
    echo -e "${RED}❌ Request failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}================================================================"
echo -e "🎉 Complete Pipeline Executed Successfully!"
echo -e "================================================================${NC}"
echo ""
echo "Summary:"
echo "  ✅ Environment setup complete"
echo "  ✅ Token validated"
echo "  ✅ Server running & healthy"
echo "  ✅ Request sent and response received"
echo ""
echo "Check test_results/ for saved responses"
echo ""

