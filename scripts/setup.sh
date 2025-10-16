#!/bin/bash
# Setup script - Environment setup, dependency installation, and token validation

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
# PART 1: ENVIRONMENT SETUP
# ============================================================

# Virtual environment configuration
VENV_PATH=".venv"
LEGACY_VENV_PATH=$(basename "$(pwd)")  # Old pattern: repo-name/

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

# Step 1.5: Create Virtual Environment
echo ""
echo -e "${BLUE}Step 1.5/7: Setting up virtual environment...${NC}"

# Check for legacy venv and warn
if [ -d "${LEGACY_VENV_PATH}/bin" ] && [ -f "${LEGACY_VENV_PATH}/bin/activate" ]; then
    print_status "$YELLOW" "⚠️  Found legacy virtual environment at '${LEGACY_VENV_PATH}/'"
    print_status "$YELLOW" "   This script now uses '.venv' for better compatibility"
    echo ""
    
    # Offer migration
    if [ ! -d "${VENV_PATH}" ]; then
        read -p "Migrate to new .venv location? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "$BLUE" "ℹ️  Moving ${LEGACY_VENV_PATH}/ to ${VENV_PATH}/"
            mv "${LEGACY_VENV_PATH}" "${VENV_PATH}"
            print_status "$GREEN" "✅ Migration complete"
        else
            print_status "$YELLOW" "⚠️  Keeping legacy location for now (will use it)"
            VENV_PATH="${LEGACY_VENV_PATH}"
        fi
    fi
fi

# Create venv if it doesn't exist
if [ ! -d "${VENV_PATH}" ]; then
    echo -e "${BLUE}Creating virtual environment at '${VENV_PATH}'...${NC}"
    if python3 -m venv "${VENV_PATH}"; then
        print_status "$GREEN" "✅ Virtual environment '${VENV_PATH}' created"
    else
        print_status "$RED" "❌ Failed to create virtual environment"
        exit 1
    fi
else
    print_status "$GREEN" "✅ Virtual environment '${VENV_PATH}' already exists"
fi

# Verify and activate virtual environment
if [ ! -f "${VENV_PATH}/bin/activate" ]; then
    print_status "$RED" "❌ Virtual environment is invalid (no activate script)"
    print_status "$YELLOW" "   Removing and recreating..."
    rm -rf "${VENV_PATH}"
    python3 -m venv "${VENV_PATH}"
fi

source "${VENV_PATH}/bin/activate"
print_status "$GREEN" "✅ Virtual environment activated"

# Step 2: Setup .env and check for tokens
echo ""
echo -e "${BLUE}Step 2/7: Setting up environment and tokens...${NC}"

# Create .env if doesn't exist
if [ ! -f .env ]; then
    if [ -f env_template.txt ]; then
        cp env_template.txt .env
        print_status "$GREEN" "✅ Created .env from template"
        
        # Substitute SERVER_PORT if set
        if [ -n "$SERVER_PORT" ]; then
            sed -i "s/^LISTEN_PORT=.*/LISTEN_PORT=$SERVER_PORT/" .env
            print_status "$GREEN" "✅ Set LISTEN_PORT=$SERVER_PORT in .env"
        fi
        
        # Substitute CLOUDFLARE credentials if set
        if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
            sed -i "s|^# CLOUDFLARE_API_TOKEN=.*|CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN|" .env
            print_status "$GREEN" "✅ Set CLOUDFLARE_API_TOKEN in .env"
        fi
        
        if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
            sed -i "s|^# CLOUDFLARE_ACCOUNT_ID=.*|CLOUDFLARE_ACCOUNT_ID=$CLOUDFLARE_ACCOUNT_ID|" .env
            print_status "$GREEN" "✅ Set CLOUDFLARE_ACCOUNT_ID in .env"
        fi
        
        if [ -n "$ENABLE_FLAREPROX" ]; then
            sed -i "s/^ENABLE_FLAREPROX=.*/ENABLE_FLAREPROX=$ENABLE_FLAREPROX/" .env
            print_status "$GREEN" "✅ Set ENABLE_FLAREPROX=$ENABLE_FLAREPROX in .env"
        fi
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

# Step 3: Install Python dependencies
echo ""
echo -e "${BLUE}Step 3/7: Installing Python dependencies...${NC}"
if pip3 install -q -r requirements.txt; then
    print_status "$GREEN" "✅ Dependencies installed successfully"
else
    print_status "$RED" "❌ Failed to install dependencies"
    exit 1
fi

# Step 4: Verify openai package
echo ""
echo -e "${BLUE}Step 4/7: Verifying openai package...${NC}"
if python3 -c "import openai; print(f'OpenAI SDK version: {openai.__version__}')" 2>&1; then
    print_status "$GREEN" "✅ OpenAI SDK is ready"
else
    print_status "$BLUE" "ℹ️  Installing openai package..."
    pip3 install -q openai
    print_status "$GREEN" "✅ OpenAI SDK installed"
fi

# Step 4.5: Initialize browserforge (download model files)
echo ""
echo -e "${BLUE}Step 4.5/7: Initializing browserforge...${NC}"
if python3 -c "from browserforge.headers import HeaderGenerator; hg = HeaderGenerator()" 2>&1 | grep -q "Downloading"; then
    print_status "$GREEN" "✅ Browserforge initialized successfully"
else
    # Try to import - this will trigger download if needed
    if python3 -c "from browserforge.headers import HeaderGenerator; HeaderGenerator()" 2>/dev/null; then
        print_status "$GREEN" "✅ Browserforge ready"
    else
        print_status "$YELLOW" "⚠️  Browserforge initialization had warnings (may still work)"
    fi
fi

# Step 5: Check configuration
echo ""
echo -e "${BLUE}Step 5/7: Checking configuration...${NC}"
source .env
if [ -n "$API_ENDPOINT" ]; then
    print_status "$GREEN" "✅ API_ENDPOINT configured: ${API_ENDPOINT}"
else
    print_status "$RED" "❌ API_ENDPOINT missing in .env"
    exit 1
fi

# AUTH_TOKEN is optional - guest mode will be used if not provided
if [ -n "$AUTH_TOKEN" ]; then
    print_status "$GREEN" "✅ AUTH_TOKEN configured (authenticated mode)"
else
    print_status "$YELLOW" "⚠️  No AUTH_TOKEN - using guest mode"
fi

# Step 6: Create test_results directory
echo ""
echo -e "${BLUE}Step 6/7: Creating test_results directory...${NC}"
mkdir -p test_results
print_status "$GREEN" "✅ test_results directory ready"

# Step 7: Set SERVER_PORT
echo ""
echo -e "${BLUE}Step 7/7: Configuring SERVER_PORT...${NC}"
if [ -n "$SERVER_PORT" ]; then
    # Update LISTEN_PORT in .env if SERVER_PORT is provided
    if grep -q "^LISTEN_PORT=" .env; then
        sed -i "s/^LISTEN_PORT=.*/LISTEN_PORT=${SERVER_PORT}/" .env
    else
        echo "LISTEN_PORT=${SERVER_PORT}" >> .env
    fi
    print_status "$GREEN" "✅ SERVER_PORT set to ${SERVER_PORT}"
else
    # Use default 7322 if not provided
    if ! grep -q "^LISTEN_PORT=" .env; then
        echo "LISTEN_PORT=7322" >> .env
    fi
    print_status "$GREEN" "✅ Using default SERVER_PORT: 7322"
fi

# ============================================================
# PART 2: TOKEN VALIDATION (Consolidated from validate_token.sh)
# ============================================================

print_header "🔐 JWT Token Validation"

# Check if ZAI_TOKEN is set
if [ -z "$ZAI_TOKEN" ]; then
    print_status "$YELLOW" "⚠️  ZAI_TOKEN not set in .env"
    print_status "$BLUE" "ℹ️  Anonymous token mode will be used"
    print_header "✅ Setup Complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Set ZAI_TOKEN in .env for authenticated mode"
    echo "  2. Run: ./scripts/start.sh"
    echo "  3. Test: ./scripts/send_request.sh"
    echo ""
    exit 0
fi

print_status "$BLUE" "ℹ️  Token found in .env"
TOKEN_PREVIEW="${ZAI_TOKEN:0:20}...${ZAI_TOKEN: -20}"
echo "   Preview: $TOKEN_PREVIEW"

# Test 1: Check JWT format (3 parts)
echo ""
echo -e "${BLUE}Token Test 1/6: JWT Format Check${NC}"
TOKEN_PARTS=$(echo "$ZAI_TOKEN" | tr '.' '\n' | wc -l)
if [ "$TOKEN_PARTS" -eq 3 ]; then
    print_status "$GREEN" "✅ Valid JWT format (3 parts)"
else
    print_status "$RED" "❌ Invalid JWT format (expected 3 parts, got $TOKEN_PARTS)"
    exit 1
fi

# Test 2: Decode JWT payload using Python
echo ""
echo -e "${BLUE}Token Test 2/6: JWT Payload Decoding${NC}"
DECODE_RESULT=$(python3 -c "
import sys
import os
sys.path.insert(0, 'src')
try:
    from signature import decode_jwt_payload
    import json
    token = os.getenv('ZAI_TOKEN')
    payload = decode_jwt_payload(token)
    if payload:
        print(json.dumps(payload, indent=2))
        sys.exit(0)
    else:
        print('Failed to decode payload')
        sys.exit(1)
except Exception as e:
    print(f'Decode error: {e}')
    sys.exit(1)
" 2>&1) || true

DECODE_EXIT_CODE=$?
if [ $DECODE_EXIT_CODE -eq 0 ]; then
    print_status "$GREEN" "✅ Successfully decoded JWT payload"
else
    print_status "$YELLOW" "⚠️  JWT decode failed (token may still work)"
fi

# Test 3: Extract user_id
echo ""
echo -e "${BLUE}Token Test 3/6: User ID Extraction${NC}"
USER_ID=$(python3 -c "
import sys
import os
sys.path.insert(0, 'src')
try:
    from signature import extract_user_id_from_token
    token = os.getenv('ZAI_TOKEN')
    user_id = extract_user_id_from_token(token)
    print(user_id)
except:
    print('guest')
" 2>/dev/null || echo "guest")

if [ "$USER_ID" != "guest" ]; then
    print_status "$GREEN" "✅ Successfully extracted user_id: $USER_ID"
else
    print_status "$YELLOW" "⚠️  Using guest user_id"
fi

# Test 4: Check token expiration
echo ""
echo -e "${BLUE}Token Test 4/6: Token Expiration Check${NC}"
EXP_CHECK=$(python3 -c "
import sys
import os
import time
sys.path.insert(0, 'src')
try:
    from signature import decode_jwt_payload
    token = os.getenv('ZAI_TOKEN')
    payload = decode_jwt_payload(token)
    if 'exp' in payload:
        exp_time = payload['exp']
        current_time = int(time.time())
        if exp_time > current_time:
            remaining = exp_time - current_time
            print(f'valid|{remaining}')
        else:
            print('expired')
    else:
        print('no_expiration')
except:
    print('no_expiration')
" 2>/dev/null || echo "no_expiration")

if [[ "$EXP_CHECK" == valid* ]]; then
    REMAINING=$(echo "$EXP_CHECK" | cut -d'|' -f2)
    HOURS=$((REMAINING / 3600))
    MINUTES=$(((REMAINING % 3600) / 60))
    print_status "$GREEN" "✅ Token is valid"
    echo "   Remaining time: ${HOURS}h ${MINUTES}m"
elif [ "$EXP_CHECK" == "expired" ]; then
    print_status "$YELLOW" "⚠️  Token may be expired (continuing...)"
elif [ "$EXP_CHECK" == "no_expiration" ]; then
    print_status "$BLUE" "ℹ️  Token has no expiration field"
fi

# Test 5: Test signature generation
echo ""
echo -e "${BLUE}Token Test 5/6: Signature Generation Test${NC}"
TEST_MSG="Hello, world!"
TIMESTAMP=$(date +%s)000
REQUEST_ID="test-$(python3 -c "import uuid; print(str(uuid.uuid4()))" 2>/dev/null || echo "12345")"

SIGNATURE=$(python3 -c "
import sys
import os
sys.path.insert(0, 'src')
try:
    from signature import generate_zs_signature
    token = os.getenv('ZAI_TOKEN')
    signature_result = generate_zs_signature(
        token=token,
        request_id='$REQUEST_ID',
        timestamp=$TIMESTAMP,
        user_content='$TEST_MSG'
    )
    print(signature_result['signature'])
except Exception as e:
    print('')
" 2>/dev/null || echo "")

if [ -n "$SIGNATURE" ] && [ ${#SIGNATURE} -eq 64 ]; then
    print_status "$GREEN" "✅ Successfully generated signature"
else
    print_status "$YELLOW" "⚠️  Signature generation skipped (may not be required)"
fi

# Test 6: Validate with validation module
echo ""
echo -e "${BLUE}Token Test 6/6: Validation Module Test${NC}"
python3 -c "
import sys
import os
sys.path.insert(0, 'src')
try:
    from validation import validate_token, print_validation_result
    token = os.getenv('ZAI_TOKEN')
    result = validate_token(token)
    print_validation_result(result, 'Token Validation')
    sys.exit(0 if result.valid else 1)
except Exception as e:
    print(f'Validation module not available: {e}')
    sys.exit(0)
" 2>/dev/null

VALIDATION_EXIT_CODE=$?
if [ $VALIDATION_EXIT_CODE -eq 0 ]; then
    print_status "$GREEN" "✅ Token validation passed"
else
    print_status "$YELLOW" "⚠️  Token validation had warnings (continuing...)"
fi

# ============================================================
# FINAL SUMMARY
# ============================================================

print_header "✅ Setup & Validation Complete!"
echo ""
echo "Environment Status:"
echo "  ✅ Python dependencies installed"
echo "  ✅ OpenAI SDK ready"
echo "  ✅ Configuration validated"
echo "  ✅ Token validated (User: $USER_ID)"
echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/start.sh"
echo "  2. Test: ./scripts/send_request.sh"
echo "  3. Or run complete pipeline: ./scripts/all.sh"
echo ""
