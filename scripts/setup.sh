#!/bin/bash
set -e

# =============================================================================
# ZAI-API Setup Script - Complete Environment Setup
# =============================================================================
# This script handles:
# - Virtual environment creation
# - Dependency installation
# - Environment configuration
# - Token validation
# - FlareProx integration (optional)
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
# PART 4: TOKEN CONFIGURATION (OPTIONAL)
# =============================================================================

print_header "Step 4: Token Configuration (Optional)"

# Check if ZAI_TOKEN is already set
if [ -n "$ZAI_TOKEN" ] && [ "$ZAI_TOKEN" != "" ]; then
    print_status "ZAI_TOKEN already configured"
    
    # Validate token format (JWT)
    if [[ "$ZAI_TOKEN" =~ ^eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*$ ]]; then
        print_status "Token format validated"
    else
        print_warning "Token format looks invalid (not a JWT)"
    fi
else
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}No ZAI_TOKEN configured - Anonymous mode will be used${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Anonymous mode:"
    echo "  ✅ Works immediately"
    echo "  ✅ No login required"
    echo "  ⚠️  Some features may be limited"
    echo ""
    echo "To use authenticated mode (full features):"
    echo "  1. Go to https://chat.z.ai and login"
    echo "  2. Open DevTools (F12) → Application → Local Storage"
    echo "  3. Copy the 'token' value"
    echo "  4. Add to .env: ZAI_TOKEN=your_token_here"
    echo ""
    echo -e "${YELLOW}Continue with anonymous mode? [Y/n]${NC}"
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        echo ""
        echo "Paste your ZAI_TOKEN (or press Enter to skip):"
        read -r token_input
        
        if [ -n "$token_input" ]; then
            # Validate token format
            if [[ "$token_input" =~ ^eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*$ ]]; then
                # Save to .env
                if grep -q "^ZAI_TOKEN=" .env 2>/dev/null; then
                    sed -i.bak "s|^ZAI_TOKEN=.*|ZAI_TOKEN=$token_input|" .env
                else
                    echo "ZAI_TOKEN=$token_input" >> .env
                fi
                print_status "Token saved to .env"
            else
                print_error "Invalid token format (not a JWT)"
                print_warning "Continuing with anonymous mode"
            fi
        else
            print_status "Using anonymous mode"
        fi
    else
        print_status "Using anonymous mode"
    fi
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

