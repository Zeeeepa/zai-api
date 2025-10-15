#!/bin/bash
# Automatic Token Fetch Script - Get Z.AI token using EMAIL and PASSWORD

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "================================================================"
echo -e "${CYAN}🔐 Automatic Z.AI Token Fetch${NC}"
echo "================================================================"
echo ""

# Check if EMAIL and PASSWORD are set
if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
    echo -e "${RED}❌ ERROR: EMAIL and PASSWORD environment variables are required!${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  export EMAIL='your@email.com'"
    echo "  export PASSWORD='your_password'"
    echo "  bash scripts/fetch_token.sh"
    echo ""
    echo -e "${YELLOW}Or run in one line:${NC}"
    echo "  EMAIL='your@email.com' PASSWORD='your_password' bash scripts/fetch_token.sh"
    echo ""
    exit 1
fi

echo -e "${BLUE}📧 Email: ${EMAIL}${NC}"
echo -e "${BLUE}🔑 Password: $( echo "$PASSWORD" | sed 's/./*/g' )${NC}"
echo ""

# Create Python script to fetch token
echo -e "${BLUE}Creating token fetch script...${NC}"

cat > /tmp/fetch_zai_token.py << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
"""
Z.AI Token Fetcher
Automatically logs in to Z.AI and retrieves the authentication token
"""

import os
import sys
import json
import time
import requests
from datetime import datetime

def fetch_token_via_api(email: str, password: str) -> str:
    """
    Fetch Z.AI token using the authentication API
    
    Args:
        email: User email
        password: User password
        
    Returns:
        str: Authentication token
        
    Raises:
        Exception: If token fetch fails
    """
    
    # Z.AI authentication endpoint (same as used in token_pool.py)
    auth_url = "https://chat.z.ai/api/v1/auths/"
    
    # Request headers
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Origin": "https://chat.z.ai",
        "Referer": "https://chat.z.ai/",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
    }
    
    # Login payload
    payload = {
        "email": email,
        "password": password
    }
    
    print("📡 Sending login request to Z.AI...")
    
    try:
        response = requests.post(
            auth_url,
            headers=headers,
            json=payload,
            timeout=15
        )
        
        if response.status_code == 200:
            data = response.json()
            token = data.get("token") or data.get("access_token") or data.get("jwt")
            
            if token:
                return token
            else:
                raise Exception(f"Token not found in response: {json.dumps(data, indent=2)}")
        else:
            error_msg = response.text
            raise Exception(f"Login failed with status {response.status_code}: {error_msg}")
            
    except requests.exceptions.RequestException as e:
        raise Exception(f"Network error: {e}")
    except Exception as e:
        raise Exception(f"Failed to fetch token: {e}")


def save_token_to_env(token: str) -> None:
    """
    Save token to .env file
    
    Args:
        token: Authentication token to save
    """
    
    env_file = ".env"
    
    # Read existing .env
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            lines = f.readlines()
    else:
        lines = []
    
    # Update or add AUTH_TOKEN and ZAI_TOKEN
    auth_token_found = False
    zai_token_found = False
    new_lines = []
    
    for line in lines:
        if line.startswith("AUTH_TOKEN="):
            new_lines.append(f"AUTH_TOKEN={token}\n")
            auth_token_found = True
        elif line.startswith("ZAI_TOKEN="):
            new_lines.append(f"ZAI_TOKEN={token}\n")
            zai_token_found = True
        else:
            new_lines.append(line)
    
    # Add tokens if not found
    if not auth_token_found:
        new_lines.append(f"AUTH_TOKEN={token}\n")
    if not zai_token_found:
        new_lines.append(f"ZAI_TOKEN={token}\n")
    
    # Write back to .env
    with open(env_file, 'w') as f:
        f.writelines(new_lines)
    
    print(f"✅ Token saved to {env_file}")


def main():
    """Main function"""
    
    # Get credentials from environment
    email = os.getenv("EMAIL")
    password = os.getenv("PASSWORD")
    
    if not email or not password:
        print("❌ ERROR: EMAIL and PASSWORD environment variables are required!")
        sys.exit(1)
    
    print("=" * 60)
    print("🔐 Z.AI Token Fetcher")
    print("=" * 60)
    print(f"📧 Email: {email}")
    print(f"🔑 Password: {'*' * len(password)}")
    print("")
    
    try:
        # Fetch token
        print("🚀 Fetching token...")
        token = fetch_token_via_api(email, password)
        
        # Display token preview
        if len(token) > 40:
            token_preview = f"{token[:20]}...{token[-20:]}"
        else:
            token_preview = token
        
        print("")
        print("=" * 60)
        print("✅ SUCCESS!")
        print("=" * 60)
        print(f"🎉 Token retrieved: {token_preview}")
        print("")
        
        # Save to .env
        print("💾 Saving token to .env file...")
        save_token_to_env(token)
        
        print("")
        print("=" * 60)
        print("🎊 All Done!")
        print("=" * 60)
        print("Your token has been saved to .env file")
        print("You can now run: bash scripts/start.sh")
        print("=" * 60)
        
    except Exception as e:
        print("")
        print("=" * 60)
        print("❌ ERROR!")
        print("=" * 60)
        print(f"Failed to fetch token: {e}")
        print("")
        print("Troubleshooting:")
        print("  1. Check your email and password are correct")
        print("  2. Verify you can login at https://chat.z.ai")
        print("  3. Check your internet connection")
        print("  4. Try again in a few moments")
        print("=" * 60)
        sys.exit(1)


if __name__ == "__main__":
    main()
PYTHON_SCRIPT

# Make it executable
chmod +x /tmp/fetch_zai_token.py

# Run the Python script
echo -e "${BLUE}🚀 Fetching token from Z.AI...${NC}"
echo ""

if python3 /tmp/fetch_zai_token.py; then
    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}🎉 Token fetch completed successfully!${NC}"
    echo -e "${GREEN}================================================================${NC}"
else
    echo ""
    echo -e "${RED}================================================================${NC}"
    echo -e "${RED}❌ Token fetch failed!${NC}"
    echo -e "${RED}================================================================${NC}"
    exit 1
fi
