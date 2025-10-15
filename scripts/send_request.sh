#!/bin/bash
################################################################################
# send_request.sh - Test ZAI-API with OpenAI-Compatible Request
# 
# This script:
# 1. Sends an OpenAI-compatible API request
# 2. Asks "What is Graph-RAG?"
# 3. Prints the formatted response
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Testing ZAI-API with OpenAI Request             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set defaults
LISTEN_PORT=${LISTEN_PORT:-8080}
AUTH_TOKEN=${AUTH_TOKEN:-sk-123456}
API_URL="http://localhost:$LISTEN_PORT"

# Check if server is running
echo -e "${CYAN}🔍 Checking server status...${NC}"
if ! curl -s "$API_URL/health" > /dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: Server is not running!${NC}"
    echo -e "${YELLOW}Please run ./start.sh first${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Server is running${NC}"
echo ""

# Display request information
echo -e "${CYAN}📋 Request Configuration:${NC}"
echo "----------------------------------------"
echo -e "  ${BLUE}API URL:${NC} $API_URL"
echo -e "  ${BLUE}Auth Token:${NC} ${AUTH_TOKEN:0:10}..."
echo -e "  ${BLUE}Model:${NC} GLM-4.5"
echo -e "  ${BLUE}Question:${NC} What is Graph-RAG?"
echo "----------------------------------------"
echo ""

# Create request payload
REQUEST_PAYLOAD='{
  "model": "GLM-4.5",
  "messages": [
    {
      "role": "user",
      "content": "What is Graph-RAG? Please provide a comprehensive explanation in 3-4 paragraphs."
    }
  ],
  "stream": false,
  "temperature": 0.7,
  "max_tokens": 1000
}'

# Send request
echo -e "${MAGENTA}🚀 Sending OpenAI-compatible API request...${NC}"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/v1/chat/completions" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_PAYLOAD")

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

# Check HTTP status
if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}❌ ERROR: Request failed with HTTP $HTTP_CODE${NC}"
    echo -e "${YELLOW}Response:${NC}"
    echo "$RESPONSE_BODY" | jq . 2>/dev/null || echo "$RESPONSE_BODY"
    exit 1
fi

echo -e "${GREEN}✓ Request successful (HTTP $HTTP_CODE)${NC}"
echo ""

# Parse and display response
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      API RESPONSE                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Extract key information using jq
if command -v jq &> /dev/null; then
    # Extract fields
    RESPONSE_ID=$(echo "$RESPONSE_BODY" | jq -r '.id // "N/A"')
    MODEL=$(echo "$RESPONSE_BODY" | jq -r '.model // "N/A"')
    CREATED=$(echo "$RESPONSE_BODY" | jq -r '.created // "N/A"')
    CONTENT=$(echo "$RESPONSE_BODY" | jq -r '.choices[0].message.content // "No content"')
    FINISH_REASON=$(echo "$RESPONSE_BODY" | jq -r '.choices[0].finish_reason // "N/A"')
    PROMPT_TOKENS=$(echo "$RESPONSE_BODY" | jq -r '.usage.prompt_tokens // "N/A"')
    COMPLETION_TOKENS=$(echo "$RESPONSE_BODY" | jq -r '.usage.completion_tokens // "N/A"')
    TOTAL_TOKENS=$(echo "$RESPONSE_BODY" | jq -r '.usage.total_tokens // "N/A"')
    
    # Display metadata
    echo -e "${CYAN}📊 Response Metadata:${NC}"
    echo "----------------------------------------"
    echo -e "  ${BLUE}ID:${NC} $RESPONSE_ID"
    echo -e "  ${BLUE}Model:${NC} $MODEL"
    echo -e "  ${BLUE}Created:${NC} $CREATED"
    echo -e "  ${BLUE}Finish Reason:${NC} $FINISH_REASON"
    echo "----------------------------------------"
    echo ""
    
    # Display token usage
    echo -e "${CYAN}🔢 Token Usage:${NC}"
    echo "----------------------------------------"
    echo -e "  ${BLUE}Prompt Tokens:${NC} $PROMPT_TOKENS"
    echo -e "  ${BLUE}Completion Tokens:${NC} $COMPLETION_TOKENS"
    echo -e "  ${BLUE}Total Tokens:${NC} $TOTAL_TOKENS"
    echo "----------------------------------------"
    echo ""
    
    # Display answer
    echo -e "${GREEN}💬 Answer to \"What is Graph-RAG?\":${NC}"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "$CONTENT" | fold -s -w 60
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    # Save full response
    echo "$RESPONSE_BODY" | jq . > last_response.json
    echo -e "${CYAN}💾 Full response saved to: last_response.json${NC}"
    
else
    # Fallback if jq is not available
    echo -e "${YELLOW}⚠️  jq not installed, showing raw response:${NC}"
    echo ""
    echo "$RESPONSE_BODY"
    echo ""
    echo "$RESPONSE_BODY" > last_response.json
    echo -e "${CYAN}💾 Response saved to: last_response.json${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                ✅ REQUEST COMPLETED!                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Additional test suggestions
echo -e "${CYAN}💡 Try more examples:${NC}"
echo ""
echo "  # Streaming response:"
echo "  curl -N $API_URL/v1/chat/completions \\"
echo "    -H \"Authorization: Bearer $AUTH_TOKEN\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"model\":\"GLM-4.5\",\"messages\":[{\"role\":\"user\",\"content\":\"Count to 5\"}],\"stream\":true}'"
echo ""
echo "  # With function calling:"
echo "  curl $API_URL/v1/chat/completions \\"
echo "    -H \"Authorization: Bearer $AUTH_TOKEN\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"model\":\"GLM-4.5\",\"messages\":[{\"role\":\"user\",\"content\":\"What is the weather in Beijing?\"}],\"tools\":[{\"type\":\"function\",\"function\":{\"name\":\"get_weather\",\"description\":\"Get weather\"}}]}'"
echo ""
echo "  # Different model:"
echo "  curl $API_URL/v1/chat/completions \\"
echo "    -H \"Authorization: Bearer $AUTH_TOKEN\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"model\":\"GLM-4.6\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}]}'"
echo ""

