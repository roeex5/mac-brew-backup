#!/bin/bash

# Mac Application Inventory Script
# Generates a comprehensive list of Homebrew packages and Mac applications
# for disaster recovery and quick setup on a new Mac

set -e

OUTPUT_FILE="mac_inventory_$(date +%Y%m%d_%H%M%S).txt"
BREWFILE="Brewfile_$(date +%Y%m%d_%H%M%S)"

echo "================================================"
echo "Mac Application Inventory"
echo "Generated: $(date)"
echo "================================================"
echo ""

# Function to check if brew is installed
check_brew() {
    if ! command -v brew &> /dev/null; then
        echo "ERROR: Homebrew is not installed!"
        echo "Install from: https://brew.sh"
        exit 1
    fi
}

# Check Homebrew installation
check_brew

# Start output file
{
    echo "================================================"
    echo "Mac Application Inventory"
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo "================================================"
    echo ""

    # Section 1: Homebrew Formulae (CLI tools)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "HOMEBREW FORMULAE (Command-line tools)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    FORMULA_COUNT=$(brew list --formula | wc -l | tr -d ' ')
    echo "Total: $FORMULA_COUNT packages"
    echo ""
    brew list --formula | sort
    echo ""

    # Section 2: Homebrew Casks (GUI applications)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "HOMEBREW CASKS (GUI Applications)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    CASK_COUNT=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
    echo "Total: $CASK_COUNT applications"
    echo ""
    if [ "$CASK_COUNT" -gt 0 ]; then
        brew list --cask | sort
    else
        echo "No casks installed"
    fi
    echo ""

    # Section 3: All /Applications folder apps
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "APPLICATIONS IN /Applications"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    APP_COUNT=$(ls -1 /Applications 2>/dev/null | grep "\.app$" | wc -l | tr -d ' ')
    echo "Total: $APP_COUNT applications"
    echo ""
    ls -1 /Applications 2>/dev/null | grep "\.app$" | sort
    echo ""

    # Section 4: Applications that COULD be Homebrew casks
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "APPLICATIONS AVAILABLE AS HOMEBREW CASKS"
    echo "(Not currently installed via Homebrew)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get list of installed casks
    INSTALLED_CASKS=$(brew list --cask 2>/dev/null | tr '\n' '|' | sed 's/|$//')

    # Check each app in /Applications
    AVAILABLE_COUNT=0
    echo "Checking applications... (this may take a moment)"
    echo ""

    for app in /Applications/*.app; do
        if [ -e "$app" ]; then
            APP_NAME=$(basename "$app" .app)
            # Convert app name to potential cask name (lowercase, remove spaces)
            CASK_SEARCH=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

            # Check if already installed via brew
            if echo "$INSTALLED_CASKS" | grep -q "$APP_NAME"; then
                continue
            fi

            # Search for available cask
            if brew search --cask "^${CASK_SEARCH}$" 2>/dev/null | grep -q "^${CASK_SEARCH}$"; then
                echo "✓ $APP_NAME"
                echo "  → brew install --cask $CASK_SEARCH"
                echo ""
                ((AVAILABLE_COUNT++))
            fi
        fi
    done

    if [ "$AVAILABLE_COUNT" -eq 0 ]; then
        echo "All applications are either:"
        echo "  - Already installed via Homebrew"
        echo "  - Not available as Homebrew casks"
        echo "  - System applications"
    else
        echo "Found $AVAILABLE_COUNT applications available as Homebrew casks"
    fi
    echo ""

    # Section 5: System Information
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "SYSTEM INFORMATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "macOS Version: $(sw_vers -productVersion)"
    echo "Homebrew Version: $(brew --version | head -1)"
    echo "Architecture: $(uname -m)"
    echo ""

} | tee "$OUTPUT_FILE"

# Generate Brewfile
echo "Generating Brewfile..."
brew bundle dump --file="$BREWFILE" --force
echo ""

echo "================================================"
echo "FILES GENERATED:"
echo "  - $OUTPUT_FILE (detailed inventory)"
echo "  - $BREWFILE (for 'brew bundle install')"
echo "================================================"
echo ""
echo "To restore on a new Mac:"
echo "  1. Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
echo "  2. Run: brew bundle install --file=$BREWFILE"
echo ""
