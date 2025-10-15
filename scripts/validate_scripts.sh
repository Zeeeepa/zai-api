#!/bin/bash
# Validation script - Smoke test all scripts after upgrade
# Run this to verify all scripts work correctly

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "================================================================"
echo -e "${CYAN}🧪 ZAI-API Scripts Validation Suite${NC}"
echo "================================================================"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}Test $TOTAL_TESTS: $test_name${NC}"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# Test 1: Check Python availability
run_test "Python3 availability" "command -v python3"

# Test 2: Check all script files exist
run_test "setup.sh exists" "[ -f scripts/setup.sh ]"
run_test "start.sh exists" "[ -f scripts/start.sh ]"
run_test "send_request.sh exists" "[ -f scripts/send_request.sh ]"
run_test "all.sh exists" "[ -f scripts/all.sh ]"
run_test "fetch_token.sh exists" "[ -f scripts/fetch_token.sh ]"
run_test "get_token_from_browser.sh exists" "[ -f scripts/get_token_from_browser.sh ]"

# Test 3: Check all scripts are executable
run_test "setup.sh is executable" "[ -x scripts/setup.sh ]"
run_test "start.sh is executable" "[ -x scripts/start.sh ]"
run_test "send_request.sh is executable" "[ -x scripts/send_request.sh ]"
run_test "all.sh is executable" "[ -x scripts/all.sh ]"

# Test 4: Check scripts use .venv pattern
run_test "setup.sh uses .venv" "grep -q 'VENV_PATH=\".venv\"' scripts/setup.sh"
run_test "start.sh uses .venv" "grep -q 'VENV_PATH=\".venv\"' scripts/start.sh"
run_test "send_request.sh uses .venv" "grep -q 'VENV_PATH=\".venv\"' scripts/send_request.sh"

# Test 5: Check legacy fallback exists
run_test "setup.sh has legacy fallback" "grep -q 'LEGACY_VENV_PATH' scripts/setup.sh"
run_test "start.sh has legacy fallback" "grep -q 'LEGACY_VENV_PATH' scripts/start.sh"
run_test "send_request.sh has legacy fallback" "grep -q 'LEGACY_VENV_PATH' scripts/send_request.sh"

# Test 6: Check .gitignore is updated
run_test ".gitignore includes .venv" "grep -q '^\\.venv/' .gitignore"
run_test ".gitignore includes legacy pattern" "grep -q '^zai-api/' .gitignore"

# Test 7: Check requirements.txt exists
run_test "requirements.txt exists" "[ -f requirements.txt ]"

# Test 8: Check env_template.txt exists
run_test "env_template.txt exists" "[ -f env_template.txt ]"

# Test 9: Verify Python can create venv
echo -e "${BLUE}Test $((TOTAL_TESTS + 1)): Python venv module works${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if python3 -m venv /tmp/test_venv_$$ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    rm -rf /tmp/test_venv_$$
else
    echo -e "${RED}❌ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
echo ""

# Test 10: Check main.py exists
run_test "main.py exists" "[ -f main.py ]"

# Final Summary
echo "================================================================"
echo -e "${CYAN}Validation Summary${NC}"
echo "================================================================"
echo -e "Total Tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed:       $FAILED_TESTS${NC}"
else
    echo -e "Failed:       $FAILED_TESTS"
fi
echo "================================================================"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All validation tests passed!${NC}"
    echo ""
    echo "You can now run:"
    echo "  bash scripts/setup.sh    # Set up environment"
    echo "  bash scripts/all.sh      # Run complete pipeline"
    exit 0
else
    echo -e "${RED}⚠️  Some validation tests failed!${NC}"
    echo ""
    echo "Please fix the issues above before running the scripts."
    exit 1
fi

