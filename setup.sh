#!/bin/bash
################################################################################
# setup.sh - Complete Environment Setup for ZAI-API
# 
# This script:
# 1. Installs Python dependencies
# 2. Installs Playwright and browsers
# 3. Uses Playwright to login to https://chat.qwen.ai/auth?action=signin
# 4. Extracts the JWT token from browser storage
# 5. Saves the token to .env file as ZAI_TOKEN
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ZAI-API Setup Script with Playwright            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables if .env exists
if [ -f .env ]; then
    echo -e "${YELLOW}📄 Loading existing .env file...${NC}"
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${YELLOW}📄 Creating .env from template...${NC}"
    cp env_template.txt .env
    export $(grep -v '^#' .env | xargs)
fi

# Check for required credentials
if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
    echo -e "${RED}❌ ERROR: QWEN_EMAIL and QWEN_PASSWORD must be set!${NC}"
    echo ""
    echo "Please set them in .env file:"
    echo "  QWEN_EMAIL=your_email@example.com"
    echo "  QWEN_PASSWORD=your_password"
    echo ""
    echo "Or export them as environment variables:"
    echo "  export QWEN_EMAIL=your_email@example.com"
    echo "  export QWEN_PASSWORD=your_password"
    exit 1
fi

echo -e "${GREEN}✓ Credentials found:${NC}"
echo "  Email: $QWEN_EMAIL"
echo "  Password: ***********"
echo ""

# Step 1: Install Python dependencies
echo -e "${BLUE}[1/5] Installing Python dependencies...${NC}"
pip3 install -q -r requirements.txt
pip3 install -q playwright
echo -e "${GREEN}✓ Python dependencies installed${NC}"
echo ""

# Step 2: Install Playwright browsers
echo -e "${BLUE}[2/5] Installing Playwright browsers...${NC}"
python3 -m playwright install chromium
echo -e "${GREEN}✓ Playwright browsers installed${NC}"
echo ""

# Step 3: Create Playwright automation script
echo -e "${BLUE}[3/5] Creating Playwright automation script...${NC}"

cat > get_qwen_token.py << 'PLAYWRIGHT_SCRIPT'
#!/usr/bin/env python3
"""
Playwright script to login to chat.qwen.ai and extract JWT token
"""
import os
import sys
import time
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout

def get_qwen_token():
    email = os.getenv('QWEN_EMAIL')
    password = os.getenv('QWEN_PASSWORD')
    
    if not email or not password:
        print("❌ ERROR: QWEN_EMAIL and QWEN_PASSWORD environment variables required!")
        sys.exit(1)
    
    print(f"🌐 Launching browser...")
    
    with sync_playwright() as p:
        # Launch browser in headless mode
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 1280, 'height': 720},
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        )
        page = context.new_page()
        
        try:
            # Navigate to Qwen login page
            print(f"🔐 Navigating to https://chat.qwen.ai/auth?action=signin")
            page.goto('https://chat.qwen.ai/auth?action=signin', wait_until='networkidle')
            time.sleep(2)
            
            # Fill in email
            print(f"📧 Entering email: {email}")
            email_input = page.wait_for_selector('input[type="email"], input[name="email"], input[placeholder*="mail"], input[placeholder*="Email"]', timeout=10000)
            email_input.fill(email)
            time.sleep(1)
            
            # Fill in password
            print(f"🔑 Entering password...")
            password_input = page.wait_for_selector('input[type="password"]', timeout=10000)
            password_input.fill(password)
            time.sleep(1)
            
            # Click login button
            print(f"🚀 Clicking login button...")
            login_button = page.wait_for_selector('button[type="submit"], button:has-text("Sign in"), button:has-text("Login"), button:has-text("登录")', timeout=10000)
            login_button.click()
            
            # Wait for navigation after login
            print(f"⏳ Waiting for login to complete...")
            page.wait_for_url('https://chat.qwen.ai/**', timeout=30000)
            time.sleep(3)
            
            # Extract token from localStorage or cookies
            print(f"🔍 Extracting JWT token...")
            
            # Try localStorage first
            token = page.evaluate("""() => {
                // Try different possible storage keys
                const keys = ['token', 'access_token', 'jwt', 'authToken', 'auth_token', 'qwen_token'];
                for (let key of keys) {
                    const value = localStorage.getItem(key);
                    if (value) return value;
                }
                return null;
            }""")
            
            # If not in localStorage, try cookies
            if not token:
                cookies = context.cookies()
                for cookie in cookies:
                    if 'token' in cookie['name'].lower() or 'auth' in cookie['name'].lower():
                        token = cookie['value']
                        break
            
            # If still not found, try sessionStorage
            if not token:
                token = page.evaluate("""() => {
                    const keys = ['token', 'access_token', 'jwt', 'authToken', 'auth_token'];
                    for (let key of keys) {
                        const value = sessionStorage.getItem(key);
                        if (value) return value;
                    }
                    return null;
                }""")
            
            if token:
                print(f"✅ Token extracted successfully!")
                print(f"Token preview: {token[:50]}...")
                
                # Save to file
                with open('.qwen_token', 'w') as f:
                    f.write(token)
                print(f"💾 Token saved to .qwen_token file")
                return token
            else:
                print("❌ ERROR: Could not find token in browser storage!")
                print("📸 Taking screenshot for debugging...")
                page.screenshot(path='login_error.png')
                print("Screenshot saved to: login_error.png")
                sys.exit(1)
                
        except PlaywrightTimeout as e:
            print(f"❌ ERROR: Timeout during login process!")
            print(f"Details: {e}")
            page.screenshot(path='timeout_error.png')
            print("Screenshot saved to: timeout_error.png")
            sys.exit(1)
        except Exception as e:
            print(f"❌ ERROR: {e}")
            page.screenshot(path='error.png')
            print("Screenshot saved to: error.png")
            sys.exit(1)
        finally:
            browser.close()

if __name__ == "__main__":
    token = get_qwen_token()
    print(f"\n🎉 Success! Token ready for use.")
PLAYWRIGHT_SCRIPT

chmod +x get_qwen_token.py
echo -e "${GREEN}✓ Playwright script created${NC}"
echo ""

# Step 4: Run Playwright to get token
echo -e "${BLUE}[4/5] Running Playwright to extract Qwen token...${NC}"
python3 get_qwen_token.py

if [ ! -f .qwen_token ]; then
    echo -e "${RED}❌ Failed to extract token!${NC}"
    exit 1
fi

TOKEN=$(cat .qwen_token)
echo -e "${GREEN}✓ Token extracted successfully${NC}"
echo ""

# Step 5: Update .env file with token
echo -e "${BLUE}[5/5] Updating .env file with extracted token...${NC}"

# Backup existing .env
cp .env .env.backup

# Update or add ZAI_TOKEN
if grep -q "^ZAI_TOKEN=" .env; then
    # Replace existing token
    sed -i "s|^ZAI_TOKEN=.*|ZAI_TOKEN=$TOKEN|" .env
else
    # Add new token
    echo "" >> .env
    echo "# Qwen Token (auto-extracted by setup.sh)" >> .env
    echo "ZAI_TOKEN=$TOKEN" >> .env
fi

echo -e "${GREEN}✓ .env file updated with token${NC}"
echo ""

# Verify .env file
echo -e "${BLUE}📋 Final .env configuration:${NC}"
echo "----------------------------------------"
grep -E "^(LISTEN_PORT|AUTH_TOKEN|ZAI_TOKEN|QWEN_EMAIL)" .env | sed 's/ZAI_TOKEN=.*/ZAI_TOKEN=***TOKEN_HIDDEN***/' | sed 's/QWEN_PASSWORD=.*/QWEN_PASSWORD=***HIDDEN***/'
echo "----------------------------------------"
echo ""

# Clean up
rm -f .qwen_token
rm -f get_qwen_token.py

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ SETUP COMPLETE!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Python dependencies installed${NC}"
echo -e "${GREEN}✓ Playwright browsers installed${NC}"
echo -e "${GREEN}✓ Qwen token extracted and saved${NC}"
echo -e "${GREEN}✓ .env file configured${NC}"
echo ""
echo -e "${BLUE}Next step: Run ${YELLOW}./start.sh${BLUE} to start the API server${NC}"
echo ""

