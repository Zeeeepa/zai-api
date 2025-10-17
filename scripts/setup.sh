#!/bin/bash
set -e

# =============================================================================
# ZAI-API Setup Script - Complete Environment Setup
# =============================================================================
# This script handles:
# - Virtual environment creation
# - Dependency installation
# - Environment configuration
# - Token validation (automatic fetch via API or manual browser paste)
# - FlareProx integration (optional)
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
# TOKEN FETCHING FUNCTIONS (from fetch_token.sh)
# =============================================================================

fetch_token_via_api() {
    local email="$1"
    local password="$2"
    
    # Create Python script for token fetching
    cat > /tmp/fetch_zai_token.py << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
"""Z.AI Token Fetcher - Automatically fetch token via API"""
import os, sys, json, requests

def fetch_token(email, password):
    """Fetch Z.AI token using authentication API"""
    auth_url = "https://chat.z.ai/api/v1/auths/"
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Origin": "https://chat.z.ai",
        "Referer": "https://chat.z.ai/",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }
    payload = {"email": email, "password": password}
    
    try:
        response = requests.post(auth_url, headers=headers, json=payload, timeout=15)
        if response.status_code == 200:
            data = response.json()
            token = data.get("token") or data.get("access_token") or data.get("jwt")
            if token:
                return token
            raise Exception("Token not found in response")
        else:
            raise Exception(f"Login failed: {response.status_code}")
    except Exception as e:
        raise Exception(f"Failed: {e}")

if __name__ == "__main__":
    email = sys.argv[1] if len(sys.argv) > 1 else os.getenv("ZAI_EMAIL")
    password = sys.argv[2] if len(sys.argv) > 2 else os.getenv("ZAI_PASSWORD")
    
    if not email or not password:
        print("ERROR: Email and password required", file=sys.stderr)
        sys.exit(1)
    
    try:
        token = fetch_token(email, password)
        print(token)  # Output token to stdout
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
PYTHON_SCRIPT

    # Run the token fetcher
    local token
    token=$(python3 /tmp/fetch_zai_token.py "$email" "$password" 2>&1)
    local exit_code=$?
    
    # Cleanup
    rm -f /tmp/fetch_zai_token.py
    
    if [ $exit_code -eq 0 ] && [ -n "$token" ]; then
        echo "$token"
        return 0
    else
        return 1
    fi
}

save_token_to_env() {
    local token="$1"
    
    # Create .env if it doesn't exist
    if [ ! -f ".env" ]; then
        if [ -f "env_template.txt" ]; then
            cp env_template.txt .env
        else
            touch .env
        fi
    fi
    
    # Update or add tokens using Python
    python3 << PYTHON_CODE
import os

token = """$token"""
env_file = ".env"

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
        new_lines.append(f"AUTH_TOKEN={token}\\n")
        auth_found = True
    elif line.startswith("ZAI_TOKEN="):
        new_lines.append(f"ZAI_TOKEN={token}\\n")
        zai_found = True
    else:
        new_lines.append(line)

if not auth_found:
    new_lines.append(f"AUTH_TOKEN={token}\\n")
if not zai_found:
    new_lines.append(f"ZAI_TOKEN={token}\\n")

# Write
with open(env_file, 'w') as f:
    f.writelines(new_lines)

print("Token saved successfully")
PYTHON_CODE
}

# =============================================================================
# PART 1: PYTHON & VIRTUAL ENVIRONMENT SETUP
# =============================================================================

print_header "Step 1: Python & Virtual Environment Setup"

# Check Python availability
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
print_status "Python $PYTHON_VERSION found"

# Virtual environment configuration
VENV_PATH=".venv"
LEGACY_VENV="zai-api"

# Check for legacy venv
if [ -d "$LEGACY_VENV" ] && [ ! -d "$VENV_PATH" ]; then
    print_warning "Legacy virtual environment detected at '$LEGACY_VENV/'"
    echo -e "${YELLOW}Would you like to migrate to '.venv/'? (recommended) [Y/n]${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        mv "$LEGACY_VENV" "$VENV_PATH"
        print_status "Migrated $LEGACY_VENV -> $VENV_PATH"
    fi
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_PATH" ]; then
    echo "Creating virtual environment at $VENV_PATH..."
    python3 -m venv "$VENV_PATH"
    print_status "Virtual environment created at $VENV_PATH"
else
    print_status "Virtual environment already exists at $VENV_PATH"
fi

# Activate virtual environment
source "$VENV_PATH/bin/activate"
print_status "Virtual environment activated"

# =============================================================================
# PART 2: DEPENDENCY INSTALLATION
# =============================================================================

print_header "Step 2: Installing Dependencies"

# Upgrade pip
echo "Upgrading pip..."
python3 -m pip install --upgrade pip > /dev/null 2>&1
print_status "pip upgraded"

# Install requirements
if [ -f "requirements.txt" ]; then
    echo "Installing Python dependencies..."
    pip install -r requirements.txt > /dev/null 2>&1
    print_status "Dependencies installed"
else
    print_error "requirements.txt not found!"
    exit 1
fi

# =============================================================================
# PART 3: ENVIRONMENT CONFIGURATION
# =============================================================================

print_header "Step 3: Environment Configuration"

# Create .env from template if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f "env_template.txt" ]; then
        cp env_template.txt .env
        print_status ".env file created from template"
    else
        print_error "env_template.txt not found!"
        exit 1
    fi
else
    print_status ".env file already exists"
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check if SERVER_PORT is set, if not use default
if [ -z "$SERVER_PORT" ]; then
    export SERVER_PORT="${LISTEN_PORT:-8080}"
fi

# Update .env with SERVER_PORT if needed
if ! grep -q "^SERVER_PORT=" .env 2>/dev/null; then
    echo "SERVER_PORT=${SERVER_PORT}" >> .env
    print_status "SERVER_PORT set to ${SERVER_PORT}"
fi

# =============================================================================
# PART 4: TOKEN CONFIGURATION
# =============================================================================

print_header "Step 4: Token Configuration"

# Check if ZAI_TOKEN is already configured
if [ -n "$ZAI_TOKEN" ] && [ "$ZAI_TOKEN" != "" ]; then
    print_status "ZAI_TOKEN already configured"
    
    # Validate token format (JWT)
    if [[ "$ZAI_TOKEN" =~ ^eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*$ ]]; then
        print_status "Token format validated (JWT)"
    else
        print_warning "Token format looks invalid (not a JWT)"
    fi
else
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}          🔐 Token Configuration Options${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Choose how to configure your authentication token:"
    echo ""
    echo "  1) 🤖 Automatic fetch (using email & password)"
    echo "  2) 📋 Manual paste (from browser)"
    echo "  3) 🆓 Anonymous mode (no token needed)"
    echo ""
    echo -e "${YELLOW}Which option? [1/2/3]:${NC} "
    read -r token_option
    
    case $token_option in
        1)
            # ===================================================================
            # OPTION 1: AUTOMATIC TOKEN FETCH (from fetch_token.sh)
            # ===================================================================
            echo ""
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BLUE}          🤖 Automatic Token Fetch${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            # Check if EMAIL and PASSWORD are in environment
            if [ -z "$ZAI_EMAIL" ]; then
                echo -n "Enter your Z.AI email: "
                read -r ZAI_EMAIL
            fi
            
            if [ -z "$ZAI_PASSWORD" ]; then
                echo -n "Enter your Z.AI password: "
                read -s ZAI_PASSWORD
                echo ""
            fi
            
            if [ -z "$ZAI_EMAIL" ] || [ -z "$ZAI_PASSWORD" ]; then
                print_error "Email and password are required"
                print_status "Falling back to anonymous mode"
            else
                echo ""
                echo "📧 Email: $ZAI_EMAIL"
                echo "🔑 Password: $(echo "$ZAI_PASSWORD" | sed 's/./*/g')"
                echo ""
                echo "🚀 Fetching token from Z.AI..."
                
                # Fetch token
                FETCHED_TOKEN=$(fetch_token_via_api "$ZAI_EMAIL" "$ZAI_PASSWORD")
                
                if [ -n "$FETCHED_TOKEN" ]; then
                    # Show preview
                    TOKEN_PREVIEW="${FETCHED_TOKEN:0:20}...${FETCHED_TOKEN: -20}"
                    echo ""
                    print_status "Token fetched successfully!"
                    echo -e "${GREEN}Token preview: $TOKEN_PREVIEW${NC}"
                    
                    # Save to .env
                    echo ""
                    echo "💾 Saving token to .env..."
                    save_token_to_env "$FETCHED_TOKEN"
                    print_status "Token saved to .env"
                    
                    # Update environment
                    export ZAI_TOKEN="$FETCHED_TOKEN"
                    export AUTH_TOKEN="$FETCHED_TOKEN"
                else
                    print_error "Failed to fetch token"
                    echo ""
                    echo "Troubleshooting:"
                    echo "  1. Verify email and password are correct"
                    echo "  2. Check you can login at https://chat.z.ai"
                    echo "  3. Check internet connection"
                    echo ""
                    print_warning "Falling back to anonymous mode"
                fi
            fi
            ;;
            
        2)
            # ===================================================================
            # OPTION 2: MANUAL BROWSER TOKEN (from get_token_from_browser.sh)
            # ===================================================================
            echo ""
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BLUE}          📋 Manual Token from Browser${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo -e "${YELLOW}📝 INSTRUCTIONS:${NC}"
            echo ""
            echo "1. Open https://chat.z.ai in your browser"
            echo "2. Login with your email and password"
            echo "3. Open Developer Tools (F12 or Ctrl+Shift+I)"
            echo "4. Go to 'Application' tab (or 'Storage' in Firefox)"
            echo "5. Click 'Local Storage' → 'https://chat.z.ai'"
            echo "6. Find 'token' key and copy its value"
            echo ""
            echo -e "${BLUE}OR use this JavaScript in Console:${NC}"
            echo -e "${GREEN}localStorage.getItem('token')${NC}"
            echo ""
            echo "7. Paste the token below:"
            echo ""
            echo -n "Token: "
            read -r MANUAL_TOKEN
            
            if [ -z "$MANUAL_TOKEN" ]; then
                print_error "No token provided"
                print_status "Falling back to anonymous mode"
            else
                # Validate token format (JWT)
                if [[ ! "$MANUAL_TOKEN" =~ ^eyJ ]]; then
                    print_error "Invalid token format! Token should start with 'eyJ'"
                    print_status "Falling back to anonymous mode"
                else
                    # Show preview
                    TOKEN_PREVIEW="${MANUAL_TOKEN:0:20}...${MANUAL_TOKEN: -20}"
                    echo ""
                    print_status "Token validated!"
                    echo -e "${GREEN}Token preview: $TOKEN_PREVIEW${NC}"
                    
                    # Save to .env
                    echo ""
                    echo "💾 Saving token to .env..."
                    save_token_to_env "$MANUAL_TOKEN"
                    print_status "Token saved to .env"
                    
                    # Update environment
                    export ZAI_TOKEN="$MANUAL_TOKEN"
                    export AUTH_TOKEN="$MANUAL_TOKEN"
                fi
            fi
            ;;
            
        3|*)
            # ===================================================================
            # OPTION 3: ANONYMOUS MODE
            # ===================================================================
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}          🆓 Anonymous Mode${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo "Anonymous mode:"
            echo "  ✅ Works immediately"
            echo "  ✅ No login required"
            echo "  ⚠️  Some features may be limited"
            echo ""
            print_status "Using anonymous mode"
            ;;
    esac
fi

# =============================================================================
# PART 5: FLAREPROX INTEGRATION (OPTIONAL)
# =============================================================================

print_header "Step 5: FlareProx Integration (Optional)"

# Check if ENABLE_FLAREPROX is set
if [ "$ENABLE_FLAREPROX" = "true" ]; then
    echo "FlareProx is enabled - checking requirements..."
    
    # Check if Cloudflare credentials are set
    if [ -n "$CLOUDFLARE_API_TOKEN" ] && [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
        print_status "Cloudflare credentials found"
        
        # Check if flareprox is installed
        if command -v flareprox &> /dev/null; then
            print_status "FlareProx already installed"
        else
            echo "Installing FlareProx..."
            pip install git+https://github.com/serversideup/flareprox.git > /dev/null 2>&1
            print_status "FlareProx installed"
        fi
        
        # Deploy FlareProx workers
        echo "Deploying FlareProx Cloudflare Workers..."
        flareprox deploy --account-id "$CLOUDFLARE_ACCOUNT_ID" --api-token "$CLOUDFLARE_API_TOKEN" > /dev/null 2>&1
        print_status "FlareProx workers deployed"
        
        # Get FlareProx URL
        FLAREPROX_URL=$(flareprox list --account-id "$CLOUDFLARE_ACCOUNT_ID" --api-token "$CLOUDFLARE_API_TOKEN" 2>/dev/null | grep -oP 'https://[^[:space:]]+' | head -1)
        
        if [ -n "$FLAREPROX_URL" ]; then
            # Update .env with FlareProx URL
            if grep -q "^FLAREPROX_URL=" .env 2>/dev/null; then
                sed -i.bak "s|^FLAREPROX_URL=.*|FLAREPROX_URL=$FLAREPROX_URL|" .env
            else
                echo "FLAREPROX_URL=$FLAREPROX_URL" >> .env
            fi
            print_status "FlareProx URL configured: $FLAREPROX_URL"
        else
            print_warning "Could not get FlareProx URL automatically"
        fi
    else
        print_warning "Cloudflare credentials not found - FlareProx disabled"
        echo "To enable FlareProx, set:"
        echo "  CLOUDFLARE_API_TOKEN=your_token"
        echo "  CLOUDFLARE_ACCOUNT_ID=your_account_id"
    fi
else
    print_status "FlareProx integration skipped (ENABLE_FLAREPROX not set to 'true')"
fi

# =============================================================================
# PART 6: VALIDATION
# =============================================================================

print_header "Step 6: Configuration Validation"

# Check critical files
for file in "main.py" "src/config.py" "requirements.txt"; do
    if [ -f "$file" ]; then
        print_status "$file exists"
    else
        print_error "$file not found!"
        exit 1
    fi
done

# Check Python imports
echo "Validating Python dependencies..."
python3 -c "import fastapi, httpx, dotenv" 2>/dev/null
if [ $? -eq 0 ]; then
    print_status "Python dependencies validated"
else
    print_error "Python dependency validation failed"
    exit 1
fi

# =============================================================================
# SETUP COMPLETE
# =============================================================================

echo ""
print_header "🎉 Setup Complete!"
echo ""
echo "Configuration Summary:"
echo "  📁 Virtual Environment: $VENV_PATH"
echo "  🐍 Python Version: $PYTHON_VERSION"
echo "  🔧 Server Port: $SERVER_PORT"
echo "  🔐 Authentication: $([ -n "$ZAI_TOKEN" ] && echo "Configured (Token)" || echo "Anonymous Mode")"
echo "  🌐 FlareProx: $([ "$ENABLE_FLAREPROX" = "true" ] && echo "Enabled" || echo "Disabled")"
echo ""
echo "Next steps:"
echo "  1. Start server: bash scripts/start.sh"
echo "  2. Test API: bash scripts/send_request.sh"
echo "  3. Or run all: bash scripts/all.sh"
echo ""

