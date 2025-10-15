#!/bin/bash
# Setup script - Environment setup and dependency installation

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "================================================================"
echo -e "${BLUE}🔧 Environment Setup${NC}"
echo "================================================================"

# Step 1: Check Python
echo -e "\n${BLUE}Step 1: Checking Python...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✅ Python found: $PYTHON_VERSION${NC}"
else
    echo -e "${RED}❌ Python3 not found. Please install Python 3.8+${NC}"
    exit 1
fi

# Step 2: Create .env if not exists
echo -e "\n${BLUE}Step 2: Setting up .env file...${NC}"
if [ ! -f .env ]; then
    if [ -f env_template.txt ]; then
        cp env_template.txt .env
        echo -e "${GREEN}✅ Created .env from template${NC}"
    else
        echo -e "${RED}❌ env_template.txt not found${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Step 3: Install Python dependencies
echo -e "\n${BLUE}Step 3: Installing Python dependencies...${NC}"
if pip3 install -q -r requirements.txt; then
    echo -e "${GREEN}✅ Dependencies installed successfully${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi

# Step 4: Verify openai package
echo -e "\n${BLUE}Step 4: Verifying openai package...${NC}"
if python3 -c "import openai; print(f'OpenAI SDK version: {openai.__version__}')" 2>&1; then
    echo -e "${GREEN}✅ OpenAI SDK is ready${NC}"
else
    echo -e "${BLUE}ℹ️  Installing openai package...${NC}"
    pip3 install -q openai
    echo -e "${GREEN}✅ OpenAI SDK installed${NC}"
fi

# Step 5: Check configuration
echo -e "\n${BLUE}Step 5: Checking configuration...${NC}"
if grep -q "AUTH_TOKEN=" .env && grep -q "API_ENDPOINT=" .env; then
    AUTH_TOKEN=$(grep "^AUTH_TOKEN=" .env | cut -d'=' -f2)
    API_ENDPOINT=$(grep "^API_ENDPOINT=" .env | cut -d'=' -f2)
    echo -e "${GREEN}✅ AUTH_TOKEN configured${NC}"
    echo -e "${GREEN}✅ API_ENDPOINT configured: ${API_ENDPOINT}${NC}"
else
    echo -e "${RED}❌ Configuration incomplete in .env${NC}"
    exit 1
fi

# Step 6: Create test_results directory
echo -e "\n${BLUE}Step 6: Creating test_results directory...${NC}"
mkdir -p test_results
echo -e "${GREEN}✅ test_results directory ready${NC}"

echo -e "\n${GREEN}================================================================"
echo -e "✅ Setup Complete!"
echo -e "================================================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Review .env configuration"
echo "  2. Run: ./scripts/start.sh"
echo "  3. Test: ./scripts/send_request.sh"
echo ""

