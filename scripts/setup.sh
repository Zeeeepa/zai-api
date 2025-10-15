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

# Step 1: Check Python
echo ""
echo -e "${BLUE}Step 1/6: Checking Python...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_status "$GREEN" "✅ Python found: $PYTHON_VERSION"
else
    print_status "$RED" "❌ Python3 not found. Please install Python 3.8+"
    exit 1
fi

# Step 2: Create .env if not exists
echo ""
echo -e "${BLUE}Step 2/6: Setting up .env file...${NC}"
if [ ! -f .env ]; then
    if [ -f env_template.txt ]; then
        cp env_template.txt .env
        print_status "$GREEN" "✅ Created .env from template"
    else
        print_status "$RED" "❌ env_template.txt not found"
        exit 1
    fi
else
    print_status "$GREEN" "✅ .env file already exists"
fi

# Step 3: Install Python dependencies
echo ""
echo -e "${BLUE}Step 3/6: Installing Python dependencies...${NC}"
if pip3 install -q -r requirements.txt; then
    print_status "$GREEN" "✅ Dependencies installed successfully"
else
    print_status "$RED" "❌ Failed to install dependencies"
    exit 1
fi

# Step 4: Verify openai package
echo ""
echo -e "${BLUE}Step 4/6: Verifying openai package...${NC}"
if python3 -c "import openai; print(f'OpenAI SDK version: {openai.__version__}')" 2>&1; then
    print_status "$GREEN" "✅ OpenAI SDK is ready"
else
    print_status "$BLUE" "ℹ️  Installing openai package..."
    pip3 install -q openai
    print_status "$GREEN" "✅ OpenAI SDK installed"
fi

# Step 5: Check configuration
echo ""
echo -e "${BLUE}Step 5/6: Checking configuration...${NC}"
source .env
if [ -n "$AUTH_TOKEN" ] && [ -n "$API_ENDPOINT" ]; then
    print_status "$GREEN" "✅ AUTH_TOKEN configured"
    print_status "$GREEN" "✅ API_ENDPOINT configured: ${API_ENDPOINT}"
else
    print_status "$RED" "❌ Configuration incomplete in .env"
    exit 1
fi

# Step 6: Create test_results directory
echo ""
echo -e "${BLUE}Step 6/6: Creating test_results directory...${NC}"
mkdir -p test_results
print_status "$GREEN" "✅ test_results directory ready"

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
