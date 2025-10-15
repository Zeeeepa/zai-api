#!/bin/bash
# Get Z.AI token from browser - THE CORRECT WAY
# Note: This script does NOT require virtual environment activation
# It only needs Python3 (standard library only - no external dependencies)

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "================================================================"
echo -e "${CYAN}🔐 Get Z.AI Token from Browser${NC}"
echo "================================================================"
echo ""

echo -e "${YELLOW}📋 INSTRUCTIONS:${NC}"
echo ""
echo "1. Open https://chat.z.ai in your browser"
echo "2. Login with your email and password"
echo "3. Open Developer Tools (F12 or Ctrl+Shift+I)"
echo "4. Go to 'Application' tab (or 'Storage' in Firefox)"
echo "5. Click 'Local Storage' -> 'https://chat.z.ai'"
echo "6. Find 'token' key and copy its value"
echo ""
echo -e "${BLUE}OR use this JavaScript in Console:${NC}"
echo -e "${GREEN}localStorage.getItem('token')${NC}"
echo ""
echo "7. Paste the token below:"
echo ""

# Read token from user
read -p "Token: " TOKEN

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ No token provided!${NC}"
    exit 1
fi

# Validate token format (JWT)
if [[ ! "$TOKEN" =~ ^eyJ ]]; then
    echo -e "${RED}❌ Invalid token format! Token should start with 'eyJ'${NC}"
    exit 1
fi

# Save to .env
ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
    if [ -f "env_template.txt" ]; then
        cp env_template.txt "$ENV_FILE"
    else
        touch "$ENV_FILE"
    fi
fi

# Update or add tokens
python3 << PYTHON_CODE
import os

token = """$TOKEN"""
env_file = "$ENV_FILE"

# Read existing
if os.path.exists(env_file):
    with open(env_file, 'r') as f:
        lines = f.readlines()
else:
    lines = []

# Update
auth_found = False
zai_found = False
new_lines = []

for line in lines:
    if line.startswith("AUTH_TOKEN="):
        new_lines.append(f"AUTH_TOKEN={token}\n")
        auth_found = True
    elif line.startswith("ZAI_TOKEN="):
        new_lines.append(f"ZAI_TOKEN={token}\n")
        zai_found = True
    else:
        new_lines.append(line)

if not auth_found:
    new_lines.append(f"AUTH_TOKEN={token}\n")
if not zai_found:
    new_lines.append(f"ZAI_TOKEN={token}\n")

# Write
with open(env_file, 'w') as f:
    f.writelines(new_lines)

print(f"✅ Token saved to {env_file}")
PYTHON_CODE

if [ $? -eq 0 ]; then
    # Show preview
    PREVIEW="${TOKEN:0:20}...${TOKEN: -20}"
    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}✅ SUCCESS!${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}Token saved: $PREVIEW${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run: bash scripts/start.sh"
    echo "  2. Test: bash scripts/send_request.sh"
    echo "================================================================"
else
    echo -e "${RED}❌ Failed to save token${NC}"
    exit 1
fi
