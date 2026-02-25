#!/bin/zsh

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurable variables
FONT_NAME="JetBrainsMono"
FONT_VERSION="v3.3.0"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/JetBrainsMono.zip"
FONT_DIR="${HOME}/.local/share/fonts/NerdFonts"

# Logging and error handling
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

error_exit() {
    echo -e "${RED}ERROR:${NC} $*" >&2
    exit 1
}

# Dependency check
check_dependencies() {
    local deps=("curl" "unzip" "fc-cache")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || error_exit "${YELLOW}Missing dependency:${NC} $dep"
    done
}

# Check if font is already installed
is_font_installed() {
    fc-list | grep -qi "$FONT_NAME"
}

# Install font
install_font() {
    log "${GREEN}Installing ${FONT_NAME}...${NC}"
    
    # Create font directory
    mkdir -p "$FONT_DIR" || error_exit "Failed to create font directory"
    
    # Create temporary download directory
    local temp_dir=$(mktemp -d)
    local font_zip="$temp_dir/JetBrainsMono.zip"
    
    # Download font
    curl -L -f -o "$font_zip" "$FONT_URL" || error_exit "Download failed"
    
    # Extract and install
    unzip -o "$font_zip" -d "$FONT_DIR" || error_exit "Font extraction failed"
    
    # Clear font cache
    fc-cache -fv || error_exit "Font cache refresh failed"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log "${GREEN}${FONT_NAME} installed successfully.${NC}"
}

# Main execution
main() {
    check_dependencies
    
    if is_font_installed; then
        log "${YELLOW}${FONT_NAME} is already installed.${NC}"
        exit 0
    fi
    
    install_font
}

# Run the script
main