#!/bin/bash
set -e

# =============================================================================
# ZAI-API Send Request Script - Test API with OpenAI SDK
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# =============================================================================
# PART 1: ENVIRONMENT SETUP
# =============================================================================

# Virtual environment activation
VENV_PATH=".venv"
LEGACY_VENV="zai-api"

if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
elif [ -f "$LEGACY_VENV/bin/activate" ]; then
    source "$LEGACY_VENV/bin/activate"
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set default port
if [ -z "$SERVER_PORT" ]; then
    export SERVER_PORT="${LISTEN_PORT:-8080}"
fi

# =============================================================================
# PART 2: SERVER CHECK
# =============================================================================

print_header "API Testing"

# Check if server is running
if ! curl -s http://localhost:$SERVER_PORT/health > /dev/null 2>&1; then
    print_error "Server is not running on port $SERVER_PORT"
    echo ""
    echo "Start the server first:"
    echo "  bash scripts/start.sh"
    exit 1
fi

print_status "Server is running on port $SERVER_PORT"

# =============================================================================
# PART 3: GET TEST QUESTION
# =============================================================================

# Get question from argument or use default
if [ -n "$1" ]; then
    QUESTION="$1"
else
    QUESTION="Write a haiku about code."
fi

echo ""
echo "Test Question: $QUESTION"
echo ""

# =============================================================================
# PART 4: RUN TESTS
# =============================================================================

print_header "Running Tests"

# Create Python test script
cat > /tmp/test_api.py << 'PYTHON_SCRIPT'
import sys
from openai import OpenAI

# Configuration
SERVER_PORT = sys.argv[1] if len(sys.argv) > 1 else "8080"
QUESTION = sys.argv[2] if len(sys.argv) > 2 else "Write a haiku about code."

client = OpenAI(
    api_key="sk-any",  # Any key works
    base_url=f"http://localhost:{SERVER_PORT}/v1"
)

print("━" * 60)
print("Test 1: Non-Streaming Request")
print("━" * 60)

try:
    response = client.chat.completions.create(
        model="GLM-4.6",
        messages=[{"role": "user", "content": QUESTION}],
        stream=False
    )
    
    print(f"\n✅ Status: Success")
    print(f"📝 Model: {response.model}")
    print(f"🔢 Tokens: {response.usage.total_tokens if hasattr(response, 'usage') else 'N/A'}")
    print(f"\n💬 Response:\n{response.choices[0].message.content}")
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    sys.exit(1)

print("\n" + "━" * 60)
print("Test 2: Streaming Request")
print("━" * 60 + "\n")

try:
    stream = client.chat.completions.create(
        model="GLM-4.6",
        messages=[{"role": "user", "content": "Say hello in 5 words"}],
        stream=True
    )
    
    print("💬 Streaming response: ", end="", flush=True)
    for chunk in stream:
        if chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end="", flush=True)
    print("\n")
    print("✅ Streaming test passed")
    
except Exception as e:
    print(f"\n❌ Streaming error: {str(e)}")
    sys.exit(1)

print("\n" + "━" * 60)
print("Test 3: Model Listing")
print("━" * 60 + "\n")

try:
    models = client.models.list()
    print("📚 Available models:")
    for model in models.data:
        print(f"  - {model.id}")
    print(f"\n✅ Found {len(models.data)} models")
    
except Exception as e:
    print(f"\n❌ Models error: {str(e)}")

print("\n" + "━" * 60)
print("🎉 All Tests Passed!")
print("━" * 60)
PYTHON_SCRIPT

# Run the test
python3 /tmp/test_api.py "$SERVER_PORT" "$QUESTION"
TEST_RESULT=$?

# Cleanup
rm -f /tmp/test_api.py

# =============================================================================
# TEST SUMMARY
# =============================================================================

echo ""
if [ $TEST_RESULT -eq 0 ]; then
    print_header "✅ Test Summary: SUCCESS"
    echo ""
    echo "All tests passed successfully!"
    echo ""
    echo "Your API is working correctly. You can now:"
    echo "  1. Integrate with your applications"
    echo "  2. Use with any OpenAI-compatible client"
    echo "  3. Test with different models and queries"
    echo ""
    echo "Example usage:"
    echo '  from openai import OpenAI'
    echo '  client = OpenAI('
    echo "      api_key=\"sk-any\","
    echo "      base_url=\"http://localhost:$SERVER_PORT/v1\""
    echo '  )'
    echo '  response = client.chat.completions.create('
    echo '      model="GLM-4.6",'
    echo '      messages=[{"role": "user", "content": "Hello!"}]'
    echo '  )'
    echo ""
else
    print_header "❌ Test Summary: FAILED"
    echo ""
    echo "Some tests failed. Please check:"
    echo "  1. Server logs: tail -f server.log"
    echo "  2. Configuration: cat .env"
    echo "  3. Server status: curl http://localhost:$SERVER_PORT/health"
    echo ""
    exit 1
fi

