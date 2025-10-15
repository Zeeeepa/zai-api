#!/bin/bash
# Send request script - Use OpenAI Python SDK to send requests

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================================"
echo -e "${BLUE}📤 Sending Request via OpenAI SDK${NC}"
echo "================================================================"

# Load environment
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

source .env

# Configuration
LISTEN_PORT=${LISTEN_PORT:-8080}
BASE_URL="http://localhost:${LISTEN_PORT}/v1"
API_KEY=${AUTH_TOKEN:-"sk-123456"}

# Get question from argument or use default
QUESTION=${1:-"What is Graph-Sitter?"}

echo -e "${BLUE}Configuration:${NC}"
echo "  Base URL: ${BASE_URL}"
echo "  Question: ${QUESTION}"
echo ""

# Check if server is running
if ! curl -s http://localhost:${LISTEN_PORT}/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Server is not running on port ${LISTEN_PORT}${NC}"
    echo -e "${YELLOW}💡 Start the server first: ./scripts/start.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Server is running${NC}"
echo ""

# Create Python script to send request
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="test_results/result_${TIMESTAMP}.txt"

echo -e "${BLUE}Sending request using OpenAI SDK...${NC}"
echo ""

# Run Python script with OpenAI SDK
python3 << EOF
import openai
import json
import sys
from datetime import datetime

# Initialize OpenAI client pointing to local server
client = openai.OpenAI(
    base_url="${BASE_URL}",
    api_key="${API_KEY}"
)

try:
    print("📡 Sending request to ${BASE_URL}/chat/completions")
    print("")
    
    # Send chat completion request
    response = client.chat.completions.create(
        model="GLM-4.5",
        messages=[
            {"role": "user", "content": "${QUESTION}"}
        ],
        stream=False,
        max_tokens=500
    )
    
    # Extract response
    content = response.choices[0].message.content
    usage = response.usage
    
    # Print response
    print("=" * 60)
    print("✅ RESPONSE RECEIVED")
    print("=" * 60)
    print("")
    print(content)
    print("")
    print("=" * 60)
    print("📊 USAGE STATISTICS")
    print("=" * 60)
    print(f"Prompt tokens:     {usage.prompt_tokens}")
    print(f"Completion tokens: {usage.completion_tokens}")
    print(f"Total tokens:      {usage.total_tokens}")
    print("")
    
    # Save to file
    with open("${RESULT_FILE}", "w") as f:
        f.write("="*60 + "\n")
        f.write(f"Question: ${QUESTION}\n")
        f.write(f"Timestamp: {datetime.now().isoformat()}\n")
        f.write("="*60 + "\n\n")
        f.write(content + "\n\n")
        f.write("="*60 + "\n")
        f.write(f"Prompt tokens: {usage.prompt_tokens}\n")
        f.write(f"Completion tokens: {usage.completion_tokens}\n")
        f.write(f"Total tokens: {usage.total_tokens}\n")
        f.write("="*60 + "\n")
    
    print(f"💾 Result saved to: ${RESULT_FILE}")
    print("")
    
except Exception as e:
    print(f"❌ ERROR: {e}", file=sys.stderr)
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}================================================================"
    echo -e "✅ Request Completed Successfully!"
    echo -e "================================================================${NC}"
else
    echo -e "${RED}================================================================"
    echo -e "❌ Request Failed"
    echo -e "================================================================${NC}"
    exit 1
fi

