#!/usr/bin/env zsh

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FONT_NAME="JetBrainsMono"
FONT_PATTERNS=("*JetBrainsMono*.ttf" "*JetBrainsMono*.otf")
FONT_DIRS=(
    "$HOME/.local/share/fonts"
    "$HOME/.fonts"
    "/usr/share/fonts"
    "/usr/local/share/fonts"
)

# Logging function
log() {
    local level="$1"
    local message="$2"
    case "$level" in
        "info")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "warn")
            echo -e "${YELLOW}[WARNING]${NC} $message" >&2
            ;;
        "error")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
    esac
}

# Check if font is installed
is_font_installed() {
    fc-list | grep -qi "$FONT_NAME"
}

# Remove font from all potential directories
remove_font() {
    local found_fonts=0
    
    for dir in "${FONT_DIRS[@]}"; do
        for pattern in "${FONT_PATTERNS[@]}"; do
            local font_files=()
            if [[ -d "$dir" ]]; then
                font_files=($(find "$dir" -type f -iname "$pattern"))
                
                if [[ ${#font_files[@]} -gt 0 ]]; then
                    for file in "${font_files[@]}"; do
                        log "info" "${GREEN}Deleting font file:${NC} $file"
                        rm -f "$file"
                        ((found_fonts++))
                    done
                fi
            fi
        done
    done
    if [[ $found_fonts -eq 0 ]]; then
        log "warn" "No ${YELLOW}$FONT_NAME${NC} files found."
        return 1
    fi
    # Refresh font cache
    if command -v fc-cache &> /dev/null; then
        fc-cache -fv
        log "info" "${GREEN}$FONT_NAME removed successfully. Font cache updated.${NC}"
    else
        log "error" "fc-cache command not found. Manual font cache refresh may be needed."
        return 2
    fi
}

# Main execution
main() {
    if is_font_installed; then
        remove_font
    else
        log "info" "$FONT_NAME is not installed."
    fi
}

# Run the script
main