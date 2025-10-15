#!/bin/bash

# validate_token.sh - JWT Token Validation Script
# Tests JWT token format, decoding, expiration, and signature generation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    echo "================================================================"
    echo "$1"
    echo "================================================================"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_status "$RED" "❌ Error: .env file not found"
    print_status "$YELLOW" "Please create .env file with ZAI_TOKEN"
    exit 1
fi

# Load environment variables
source .env

print_header "🔐 JWT Token Validation"

# Check if ZAI_TOKEN is set
if [ -z "$ZAI_TOKEN" ]; then
    print_status "$YELLOW" "⚠️  ZAI_TOKEN not set in .env"
    print_status "$BLUE" "ℹ️  Anonymous token mode will be used"
    exit 0
fi

print_status "$BLUE" "ℹ️  Token found in .env"
TOKEN_PREVIEW="${ZAI_TOKEN:0:20}...${ZAI_TOKEN: -20}"
echo "   Preview: $TOKEN_PREVIEW"

# Test 1: Check JWT format (3 parts)
print_header "Test 1: JWT Format Check"
TOKEN_PARTS=$(echo "$ZAI_TOKEN" | tr '.' '\n' | wc -l)
if [ "$TOKEN_PARTS" -eq 3 ]; then
    print_status "$GREEN" "✅ Valid JWT format (3 parts)"
else
    print_status "$RED" "❌ Invalid JWT format (expected 3 parts, got $TOKEN_PARTS)"
    exit 1
fi

# Test 2: Decode JWT payload using Python
print_header "Test 2: JWT Payload Decoding"
DECODE_RESULT=$(python3 -c "
import sys
import os
sys.path.insert(0, 'src')
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
" 2>&1)

DECODE_EXIT_CODE=$?
if [ $DECODE_EXIT_CODE -eq 0 ]; then
    print_status "$GREEN" "✅ Successfully decoded JWT payload"
    echo "$DECODE_RESULT"
else
    print_status "$RED" "❌ Failed to decode JWT payload"
    echo "$DECODE_RESULT"
    exit 1
fi

# Test 3: Extract user_id
print_header "Test 3: User ID Extraction"
USER_ID=$(python3 -c "
import sys
import os
sys.path.insert(0, 'src')
from signature import extract_user_id_from_token

token = os.getenv('ZAI_TOKEN')
user_id = extract_user_id_from_token(token)
print(user_id)
")

if [ "$USER_ID" != "guest" ]; then
    print_status "$GREEN" "✅ Successfully extracted user_id: $USER_ID"
else
    print_status "$YELLOW" "⚠️  Using guest user_id (token may not have user_id field)"
fi

# Test 4: Check token expiration
print_header "Test 4: Token Expiration Check"
EXP_CHECK=$(python3 -c "
import sys
import os
import time
sys.path.insert(0, 'src')
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
")

if [[ "$EXP_CHECK" == valid* ]]; then
    REMAINING=$(echo "$EXP_CHECK" | cut -d'|' -f2)
    HOURS=$((REMAINING / 3600))
    MINUTES=$(((REMAINING % 3600) / 60))
    print_status "$GREEN" "✅ Token is valid"
    echo "   Remaining time: ${HOURS}h ${MINUTES}m"
elif [ "$EXP_CHECK" == "expired" ]; then
    print_status "$RED" "❌ Token has expired"
    exit 1
elif [ "$EXP_CHECK" == "no_expiration" ]; then
    print_status "$BLUE" "ℹ️  Token has no expiration field"
fi

# Test 5: Test signature generation
print_header "Test 5: Signature Generation Test"
TEST_MSG="Hello, world!"
TIMESTAMP=$(date +%s)000
REQUEST_ID="test-$(uuidgen | tr '[:upper:]' '[:lower:]')"

SIGNATURE=$(python3 -c "
import sys
import os
sys.path.insert(0, 'src')
from signature import generate_zs_signature

token = os.getenv('ZAI_TOKEN')
signature_result = generate_zs_signature(
    token=token,
    request_id='$REQUEST_ID',
    timestamp=$TIMESTAMP,
    user_content='$TEST_MSG'
)
print(signature_result['signature'])
")

if [ -n "$SIGNATURE" ] && [ ${#SIGNATURE} -eq 64 ]; then
    print_status "$GREEN" "✅ Successfully generated signature"
    echo "   Signature: ${SIGNATURE:0:32}..."
else
    print_status "$RED" "❌ Failed to generate valid signature"
    exit 1
fi

# Test 6: Validate with validation module
print_header "Test 6: Validation Module Test"
python3 -c "
import sys
import os
sys.path.insert(0, 'src')
from validation import validate_token, print_validation_result

token = os.getenv('ZAI_TOKEN')
result = validate_token(token)
print_validation_result(result, 'Token Validation via validation.py')

sys.exit(0 if result.valid else 1)
"

VALIDATION_EXIT_CODE=$?
if [ $VALIDATION_EXIT_CODE -eq 0 ]; then
    print_status "$GREEN" "✅ Token passed validation module checks"
else
    print_status "$RED" "❌ Token failed validation module checks"
    exit 1
fi

# Summary
print_header "📊 Validation Summary"
print_status "$GREEN" "✅ All token validation tests passed!"
echo ""
echo "Token Details:"
echo "  • Format: Valid JWT (3 parts)"
echo "  • User ID: $USER_ID"
echo "  • Signature Generation: Working"
echo "  • Validation Module: Passed"
echo ""
print_status "$GREEN" "🎉 Token is ready to use!"

exit 0

