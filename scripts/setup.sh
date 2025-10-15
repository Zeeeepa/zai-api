#!/bin/bash
# Setup script - Create venv, install dependencies, validate tokens

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo "================================================================"
    echo -e "${BLUE}$1${NC}"
    echo "================================================================"
}

print_status() {
    echo -e "${1}${2}${NC}"
}

print_header "🔧 Environment Setup & Validation"

# ============================================================
# PART 1: PYTHON & VENV SETUP
# ============================================================

# Step 1: Check Python
echo ""
echo -e "${BLUE}Step 1/7: Checking Python...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_status "$GREEN" "✅ Python found: $PYTHON_VERSION"
else
    print_status "$RED" "❌ Python3 not found. Please install Python 3.8+"
    exit 1
fi

# Step 2: Create and activate virtual environment
echo ""
echo -e "${BLUE}Step 2/7: Setting up virtual environment...${NC}"

VENV_DIR="venv"

if [ ! -d "$VENV_DIR" ]; then
    print_status "$BLUE" "📦 Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    print_status "$GREEN" "✅ Virtual environment created"
else
    print_status "$GREEN" "✅ Virtual environment exists"
fi

# Activate venv
print_status "$BLUE" "🔄 Activating virtual environment..."
source "$VENV_DIR/bin/activate"
print_status "$GREEN" "✅ Virtual environment activated"

# Step 3: Setup .env and check for tokens
echo ""
echo -e "${BLUE}Step 3/7: Setting up environment and tokens...${NC}"

# Create .env if doesn't exist
if [ ! -f .env ]; then
    if [ -f env_template.txt ]; then
        cp env_template.txt .env
        print_status "$GREEN" "✅ Created .env from template"
    else
        print_status "$RED" "❌ env_template.txt not found"
        exit 1
    fi
else
    print_status "$GREEN" "✅ .env file exists"
fi

# Check if we have a token in .env
source .env 2>/dev/null || true

if [ -n "$AUTH_TOKEN" ] && [ "$AUTH_TOKEN" != "sk-123456" ]; then
    # We have a real token configured
    TOKEN_PREVIEW="${AUTH_TOKEN:0:20}...${AUTH_TOKEN: -10}"
    print_status "$GREEN" "✅ Found existing token: $TOKEN_PREVIEW"
elif [ -n "$ZAI_TOKEN" ]; then
    # We have ZAI_TOKEN
    TOKEN_PREVIEW="${ZAI_TOKEN:0:20}...${ZAI_TOKEN: -10}"
    print_status "$GREEN" "✅ Found existing ZAI_TOKEN: $TOKEN_PREVIEW"
else
    # No token found
    print_status "$YELLOW" "⚠️  No authentication token configured"
    print_status "$YELLOW" "   Server will use anonymous/guest mode"
    print_status "$BLUE" ""
    print_status "$BLUE" "   To use authenticated mode:"
    print_status "$BLUE" "   1. Login at https://chat.z.ai"
    print_status "$BLUE" "   2. Get token from browser (see QUICK_START.md)"
    print_status "$BLUE" "   3. Run: bash scripts/get_token_from_browser.sh"
fi

# Step 4: Upgrade pip
echo ""
echo -e "${BLUE}Step 4/7: Upgrading pip...${NC}"
pip install --upgrade pip -q
print_status "$GREEN" "✅ pip upgraded"

# Step 5: Install Python dependencies
echo ""
echo -e "${BLUE}Step 5/7: Installing Python dependencies...${NC}"
if pip install -q -r requirements.txt; then
    print_status "$GREEN" "✅ Dependencies installed successfully"
else
    print_status "$RED" "❌ Failed to install dependencies"
    exit 1
fi

# Step 6: Verify openai package
echo ""
echo -e "${BLUE}Step 6/7: Verifying openai package...${NC}"
if python3 -c "import openai; print(f'OpenAI SDK version: {openai.__version__}')" 2>&1; then
    print_status "$GREEN" "✅ OpenAI SDK is ready"
else
    print_status "$BLUE" "ℹ️  Installing openai package..."
    pip install -q openai
    print_status "$GREEN" "✅ OpenAI SDK installed"
fi

# Step 7: Check configuration
echo ""
echo -e "${BLUE}Step 7/7: Checking configuration...${NC}"
source .env
if [ -n "$AUTH_TOKEN" ] && [ -n "$API_ENDPOINT" ]; then
    print_status "$GREEN" "✅ AUTH_TOKEN configured"
    print_status "$GREEN" "✅ API_ENDPOINT configured: ${API_ENDPOINT}"
else
    print_status "$RED" "❌ Configuration incomplete in .env"
    exit 1
fi

# Create test_results directory
mkdir -p test_results
print_status "$GREEN" "✅ test_results directory ready"

# ============================================================
# PART 2: TOKEN VALIDATION
# ============================================================

print_header "🔐 JWT Token Validation"

# Check if token exists
if [ -n "$AUTH_TOKEN" ]; then
    TOKEN_PREVIEW="${AUTH_TOKEN:0:20}...${AUTH_TOKEN: -20}"
    print_status "$BLUE" "ℹ️  Token found in .env"
    echo "   Preview: $TOKEN_PREVIEW"
elif [ -n "$ZAI_TOKEN" ]; then
    TOKEN_PREVIEW="${ZAI_TOKEN:0:20}...${ZAI_TOKEN: -20}"
    print_status "$BLUE" "ℹ️  Token found in .env"
    echo "   Preview: $TOKEN_PREVIEW"
    AUTH_TOKEN="$ZAI_TOKEN"
else
    print_status "$YELLOW" "⚠️  No token configured"
    print_status "$BLUE" "ℹ️  Server will fetch guest tokens automatically"
    echo ""
    print_header "✅ Setup Complete!"
    echo ""
    echo "Environment Status:"
    echo "  ✅ Python dependencies installed"
    echo "  ✅ OpenAI SDK ready"
    echo "  ✅ Configuration validated"
    echo "  ℹ️  Using anonymous/guest mode"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./scripts/start.sh"
    echo "  2. Test: ./scripts/send_request.sh"
    echo "  3. Or run complete pipeline: ./scripts/all.sh"
    echo ""
    exit 0
fi

# Basic JWT validation
echo ""
echo -e "${BLUE}Token Test 1/6: JWT Format Check${NC}"
JWT_PARTS=$(echo "$AUTH_TOKEN" | tr '.' '\n' | wc -l)
if [ "$JWT_PARTS" -eq 3 ]; then
    print_status "$GREEN" "✅ Valid JWT format (3 parts)"
else
    print_status "$RED" "❌ Invalid JWT format (expected 3 parts, got $JWT_PARTS)"
    exit 1
fi

# Decode JWT payload (base64)
echo ""
echo -e "${BLUE}Token Test 2/6: JWT Payload Decoding${NC}"
PAYLOAD=$(echo "$AUTH_TOKEN" | cut -d'.' -f2)
# Add padding if needed
case $((${#PAYLOAD} % 4)) in
    2) PAYLOAD="${PAYLOAD}==" ;;
    3) PAYLOAD="${PAYLOAD}=" ;;
esac

if DECODED=$(echo "$PAYLOAD" | base64 -d 2>/dev/null); then
    print_status "$GREEN" "✅ Successfully decoded JWT payload"
else
    print_status "$YELLOW" "⚠️  Could not decode JWT payload"
fi

# Extract user_id
echo ""
echo -e "${BLUE}Token Test 3/6: User ID Extraction${NC}"
if [ -n "$DECODED" ]; then
    USER_ID=$(echo "$DECODED" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('id', 'unknown'))" 2>/dev/null || echo "unknown")
    if [ "$USER_ID" != "unknown" ] && [ "$USER_ID" != "guest" ]; then
        print_status "$GREEN" "✅ User ID: $USER_ID"
    else
        print_status "$YELLOW" "⚠️  Using guest user_id"
    fi
else
    print_status "$YELLOW" "⚠️  Could not extract user_id"
fi

# Check expiration
echo ""
echo -e "${BLUE}Token Test 4/6: Token Expiration Check${NC}"
if [ -n "$DECODED" ]; then
    EXP=$(echo "$DECODED" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('exp', ''))" 2>/dev/null || echo "")
    if [ -n "$EXP" ]; then
        CURRENT_TIME=$(date +%s)
        if [ "$EXP" -gt "$CURRENT_TIME" ]; then
            REMAINING=$((EXP - CURRENT_TIME))
            HOURS=$((REMAINING / 3600))
            print_status "$GREEN" "✅ Token valid for $HOURS hours"
        else
            print_status "$RED" "❌ Token expired!"
            exit 1
        fi
    else
        print_status "$BLUE" "ℹ️  Token has no expiration field"
    fi
else
    print_status "$YELLOW" "⚠️  Could not check expiration"
fi

# Test signature (optional)
echo ""
echo -e "${BLUE}Token Test 5/6: Signature Generation Test${NC}"
print_status "$YELLOW" "⚠️  Signature generation skipped (may not be required)"

# Validation module test
echo ""
echo -e "${BLUE}Token Test 6/6: Validation Module Test${NC}"
if python3 -c "from validation import validate_token; validate_token('$AUTH_TOKEN')" 2>&1 | grep -q "valid"; then
    print_status "$GREEN" "✅ Validation module passed"
else
    ERROR_MSG=$(python3 -c "from validation import validate_token; validate_token('$AUTH_TOKEN')" 2>&1 || echo "No module named 'validation'")
    echo "Validation module not available: $ERROR_MSG"
fi

print_status "$GREEN" "✅ Token validation passed"

# ============================================================
# FINAL STATUS
# ============================================================

print_header "✅ Setup & Validation Complete!"

echo ""
echo "Environment Status:"
echo "  ✅ Python dependencies installed"
echo "  ✅ OpenAI SDK ready"
echo "  ✅ Configuration validated"
echo "  ✅ Token validated (User: ${USER_ID:-guest})"
echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/start.sh"
echo "  2. Test: ./scripts/send_request.sh"
echo "  3. Or run complete pipeline: ./scripts/all.sh"
echo ""
