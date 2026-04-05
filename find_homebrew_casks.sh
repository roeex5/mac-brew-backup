#!/bin/bash

# Find Applications That Could Be Homebrew Casks
# Identifies apps in /Applications that are available as Homebrew casks
# but weren't installed via Homebrew
#
# Usage:
#   ./find_homebrew_casks.sh [--format json|csv|text|all]
#
# Options:
#   --format json    Output as JSON
#   --format csv     Output as CSV
#   --format text    Output as human-readable text (default)
#   --format all     Output all formats

set -e

# Parse arguments
FORMAT="text"
if [ "$1" = "--format" ] && [ -n "$2" ]; then
    FORMAT="$2"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🔍 Scanning /Applications for Homebrew-available apps..."
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ ERROR: Homebrew is not installed!"
    echo "Install from: https://brew.sh"
    exit 1
fi

# Get list of currently installed casks
echo "📦 Getting list of Homebrew-installed casks..."
INSTALLED_CASKS=$(brew list --cask 2>/dev/null)
echo ""

# Arrays to store results
declare -a ALREADY_BREW_APPS
declare -a AVAILABLE_APPS
declare -a AVAILABLE_CASKS
declare -a NOT_AVAILABLE_APPS
declare -a ALL_APPS

# Counters
TOTAL_APPS=0
AVAILABLE_COUNT=0
ALREADY_BREW=0
NOT_AVAILABLE=0

echo "🔎 Analyzing applications..."
echo ""

# Process each app
for app in /Applications/*.app; do
    if [ -e "$app" ]; then
        ((TOTAL_APPS++))
        APP_NAME=$(basename "$app" .app")
        ALL_APPS+=("$APP_NAME")

        # Get app info
        APP_VERSION=""
        if [ -f "$app/Contents/Info.plist" ]; then
            APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app/Contents/Info.plist" 2>/dev/null || echo "unknown")
        fi

        # Skip if already installed via Homebrew
        if echo "$INSTALLED_CASKS" | grep -qi "$APP_NAME"; then
            ALREADY_BREW_APPS+=("$APP_NAME")
            ((ALREADY_BREW++))
            continue
        fi

        # Convert app name to potential cask search terms
        SEARCH_TERMS=(
            "$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
            "$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '')"
            "$(echo "$APP_NAME" | tr ' ' '-')"
            "$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')"
        )

        FOUND=false
        CASK_NAME=""

        # Try each search term
        for term in "${SEARCH_TERMS[@]}"; do
            if brew search --cask "$term" 2>/dev/null | grep -q "^${term}$"; then
                FOUND=true
                CASK_NAME="$term"
                break
            fi
        done

        if [ "$FOUND" = true ]; then
            AVAILABLE_APPS+=("$APP_NAME")
            AVAILABLE_CASKS+=("$CASK_NAME")
            ((AVAILABLE_COUNT++))
        else
            NOT_AVAILABLE_APPS+=("$APP_NAME")
            ((NOT_AVAILABLE++))
        fi
    fi
done

# Function to generate JSON
generate_json() {
    local filename="homebrew_analysis_${TIMESTAMP}.json"

    cat > "$filename" << EOF
{
  "generated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$(hostname)",
  "summary": {
    "total_apps": $TOTAL_APPS,
    "already_homebrew": $ALREADY_BREW,
    "available_as_cask": $AVAILABLE_COUNT,
    "not_available": $NOT_AVAILABLE
  },
  "already_homebrew": [
EOF

    # Already Homebrew apps
    for i in "${!ALREADY_BREW_APPS[@]}"; do
        echo -n "    \"${ALREADY_BREW_APPS[$i]}\"" >> "$filename"
        if [ $i -lt $((${#ALREADY_BREW_APPS[@]} - 1)) ]; then
            echo "," >> "$filename"
        else
            echo "" >> "$filename"
        fi
    done

    cat >> "$filename" << EOF
  ],
  "available_as_cask": [
EOF

    # Available as cask
    for i in "${!AVAILABLE_APPS[@]}"; do
        cat >> "$filename" << EOF
    {
      "app_name": "${AVAILABLE_APPS[$i]}",
      "cask_name": "${AVAILABLE_CASKS[$i]}",
      "install_command": "brew install --cask ${AVAILABLE_CASKS[$i]}"
    }
EOF
        if [ $i -lt $((${#AVAILABLE_APPS[@]} - 1)) ]; then
            echo "," >> "$filename"
        else
            echo "" >> "$filename"
        fi
    done

    cat >> "$filename" << EOF
  ],
  "not_available": [
EOF

    # Not available
    for i in "${!NOT_AVAILABLE_APPS[@]}"; do
        echo -n "    \"${NOT_AVAILABLE_APPS[$i]}\"" >> "$filename"
        if [ $i -lt $((${#NOT_AVAILABLE_APPS[@]} - 1)) ]; then
            echo "," >> "$filename"
        else
            echo "" >> "$filename"
        fi
    done

    cat >> "$filename" << EOF
  ]
}
EOF

    echo "📄 JSON output: $filename"
}

# Function to generate CSV
generate_csv() {
    local filename="homebrew_analysis_${TIMESTAMP}.csv"

    # Header
    echo "App Name,Status,Cask Name,Install Command" > "$filename"

    # Already Homebrew
    for app in "${ALREADY_BREW_APPS[@]}"; do
        echo "\"$app\",Already Homebrew,N/A,N/A" >> "$filename"
    done

    # Available as cask
    for i in "${!AVAILABLE_APPS[@]}"; do
        echo "\"${AVAILABLE_APPS[$i]}\",Available as Cask,\"${AVAILABLE_CASKS[$i]}\",\"brew install --cask ${AVAILABLE_CASKS[$i]}\"" >> "$filename"
    done

    # Not available
    for app in "${NOT_AVAILABLE_APPS[@]}"; do
        echo "\"$app\",Not Available,N/A,N/A" >> "$filename"
    done

    echo "📄 CSV output: $filename"
}

# Function to generate text report
generate_text() {
    local filename="homebrew_analysis_${TIMESTAMP}.txt"

    {
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "HOMEBREW APPLICATION ANALYSIS"
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        echo "SUMMARY"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Total apps in /Applications: $TOTAL_APPS"
        echo "Already installed via Homebrew: $ALREADY_BREW"
        echo "Available as Homebrew casks: $AVAILABLE_COUNT"
        echo "Not available in Homebrew: $NOT_AVAILABLE"
        echo ""

        if [ ${#ALREADY_BREW_APPS[@]} -gt 0 ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "ALREADY INSTALLED VIA HOMEBREW ($ALREADY_BREW)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            for app in "${ALREADY_BREW_APPS[@]}"; do
                echo "  ✓ $app"
            done
            echo ""
        fi

        if [ ${#AVAILABLE_APPS[@]} -gt 0 ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "AVAILABLE AS HOMEBREW CASKS ($AVAILABLE_COUNT)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            for i in "${!AVAILABLE_APPS[@]}"; do
                echo "  ✅ ${AVAILABLE_APPS[$i]}"
                echo "     brew install --cask ${AVAILABLE_CASKS[$i]}"
                echo ""
            done
        fi

        if [ ${#NOT_AVAILABLE_APPS[@]} -gt 0 ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "NOT AVAILABLE IN HOMEBREW ($NOT_AVAILABLE)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            for app in "${NOT_AVAILABLE_APPS[@]}"; do
                echo "  ❌ $app"
            done
            echo ""
        fi

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "NEXT STEPS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "To migrate an app to Homebrew:"
        echo "  1. Remove: rm -rf '/Applications/App Name.app'"
        echo "  2. Install: brew install --cask app-name"
        echo "  3. Update: brew bundle dump --force"
        echo ""

    } | tee "$filename"

    echo "📄 Text output: $filename"
}

# Generate output based on format
case $FORMAT in
    json)
        generate_json
        ;;
    csv)
        generate_csv
        ;;
    text)
        generate_text
        ;;
    all)
        generate_json
        echo ""
        generate_csv
        echo ""
        generate_text
        ;;
    *)
        echo "❌ Invalid format: $FORMAT"
        echo "Usage: $0 [--format json|csv|text|all]"
        exit 1
        ;;
esac

echo ""
echo "✅ Analysis complete!"
