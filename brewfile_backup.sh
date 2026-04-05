#!/bin/bash

# Clean Brewfile Backup Script
# Generates a Brewfile with only explicitly installed packages (not dependencies)
# Uses 'brew leaves' to filter out auto-installed dependencies

set -e

BREWFILE="Brewfile"

echo "Generating clean Brewfile (explicitly installed packages only)..."
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "ERROR: Homebrew is not installed!"
    echo "Install from: https://brew.sh"
    exit 1
fi

# Write Brewfile header
{
    echo "# Brewfile - explicitly installed Homebrew packages"
    echo "# Generated: $(date)"
    echo "# Formulae filtered with 'brew leaves' (top-level only, no auto-dependencies)"
    echo ""

    # Taps
    while IFS= read -r tap; do
        echo "tap \"$tap\""
    done < <(brew tap)
    echo ""

    # Formulae — only top-level (leaves), not dependencies
    while IFS= read -r formula; do
        echo "brew \"$formula\""
    done < <(brew leaves | sort)
    echo ""

    # Casks
    while IFS= read -r cask; do
        echo "cask \"$cask\""
    done < <(brew list --cask 2>/dev/null | sort)
    echo ""

    # Mac App Store apps (if mas is installed)
    if command -v mas &> /dev/null; then
        while IFS= read -r line; do
            id=$(echo "$line" | awk '{print $1}')
            name=$(echo "$line" | cut -d' ' -f2- | sed 's/ ([^)]*)//')
            echo "mas \"$name\", id: $id"
        done < <(mas list)
    fi

} > "$BREWFILE"

echo "Brewfile generated: $BREWFILE"
echo ""

# Show summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TAP_COUNT=$(grep -c "^tap" "$BREWFILE" 2>/dev/null || echo "0")
BREW_COUNT=$(grep -c "^brew" "$BREWFILE" 2>/dev/null || echo "0")
CASK_COUNT=$(grep -c "^cask" "$BREWFILE" 2>/dev/null || echo "0")
MAS_COUNT=$(grep -c "^mas" "$BREWFILE" 2>/dev/null || echo "0")

echo "Taps: $TAP_COUNT"
echo "Formulae (top-level only): $BREW_COUNT"
echo "Casks: $CASK_COUNT"
echo "Mac App Store: $MAS_COUNT"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TO RESTORE ON A NEW MAC:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Install Homebrew:"
echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
echo ""
echo "2. Run: brew bundle install --file=Brewfile"
echo ""
