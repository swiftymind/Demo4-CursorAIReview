#!/bin/bash

# 🚀 Swift Code Review - ONE Complete Script
# Analyzes uncommitted Swift changes and provides actionable fixes

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis for better output
ROCKET="🚀"
CHECK="✅"
WARNING="⚠️"
ERROR="❌"
INFO="ℹ️"
GEAR="🔧"
EYES="👀"
FIRE="🔥"

# Configuration
SWIFT_CONVENTIONS_FILE="${BASH_SOURCE%/*}/../swift-conventions.mdc"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE=".swift_review_${TIMESTAMP}.txt"
FIXES_FILE=".swift_fixes_actionable.md"

# Counters
SWIFTLINT_ISSUES=0
CONVENTION_ISSUES=0
ARCHITECTURE_ISSUES=0
IOS_ISSUES=0
TOTAL_ISSUES=0

echo -e "${CYAN}${ROCKET} Swift Code Review - Complete Analysis${NC}"
echo "============================================================"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${ERROR} Not a git repository!"
    exit 1
fi

# Find Swift conventions file
if [[ ! -f "$SWIFT_CONVENTIONS_FILE" ]]; then
    echo -e "${WARNING} Swift conventions file not found at: $SWIFT_CONVENTIONS_FILE"
    SWIFT_CONVENTIONS_FILE=""
fi

echo -e "${INFO} Analyzing uncommitted changes..."
if [[ -n "$SWIFT_CONVENTIONS_FILE" ]]; then
    echo "Rules file: $SWIFT_CONVENTIONS_FILE"
fi
echo

# Get uncommitted Swift files
SWIFT_FILES=()
CHANGED_FILES_OUTPUT=""

# Get unstaged files
while IFS= read -r file; do
    if [[ "$file" == *.swift ]]; then
        SWIFT_FILES+=("$file")
        CHANGED_FILES_OUTPUT+="  📄 $file (unstaged)\n"
    fi
done < <(git diff --name-only 2>/dev/null)

# Get staged files
while IFS= read -r file; do
    if [[ "$file" == *.swift ]]; then
        if [[ ! " ${SWIFT_FILES[@]} " =~ " ${file} " ]]; then
            SWIFT_FILES+=("$file")
            CHANGED_FILES_OUTPUT+="  📄 $file (staged)\n"
        fi
    fi
done < <(git diff --cached --name-only 2>/dev/null)

# Get untracked files
while IFS= read -r file; do
    if [[ "$file" == *.swift ]]; then
        SWIFT_FILES+=("$file")
        CHANGED_FILES_OUTPUT+="  📄 $file (untracked)\n"
    fi
done < <(git ls-files --others --exclude-standard 2>/dev/null)

echo -e "${EYES} Detecting Uncommitted Changes"
echo "============================================================"

if [[ ${#SWIFT_FILES[@]} -eq 0 ]]; then
    echo -e "${CHECK} No Swift file changes detected. Nothing to review!"
    exit 0
fi

echo -e "${INFO} Found changes in ${#SWIFT_FILES[@]} Swift files:"
echo -e "$CHANGED_FILES_OUTPUT"

# Function to analyze a Swift file
analyze_swift_file() {
    local file="$1"
    local issues_found=0
    
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    
    # SwiftLint check (if available)
    if command -v swiftlint >/dev/null 2>&1; then
        local swiftlint_output
        swiftlint_output=$(swiftlint lint --path "$file" --quiet 2>/dev/null || true)
        if [[ -n "$swiftlint_output" ]]; then
            local swiftlint_count
            swiftlint_count=$(echo "$swiftlint_output" | wc -l | tr -d ' ')
            SWIFTLINT_ISSUES=$((SWIFTLINT_ISSUES + swiftlint_count))
            issues_found=$((issues_found + swiftlint_count))
        fi
    fi
    
    # Swift conventions analysis
    while IFS= read -r line; do
        local line_num=1
        
        # Check naming conventions
        if [[ "$line" =~ ^[[:space:]]*class[[:space:]]+[a-z] ]]; then
            echo -e "${WARNING} File $file: Class name should start with uppercase (line $line_num)"
            CONVENTION_ISSUES=$((CONVENTION_ISSUES + 1))
            issues_found=$((issues_found + 1))
        fi
        
        # Check for XCTest (should use Swift Testing)
        if [[ "$line" =~ import[[:space:]]+XCTest ]]; then
            echo -e "${ERROR} File $file: Should use Swift Testing framework, not XCTest (line $line_num)"
            CONVENTION_ISSUES=$((CONVENTION_ISSUES + 1))
            issues_found=$((issues_found + 1))
        fi
        
        # Check for missing documentation on public methods
        if [[ "$line" =~ ^[[:space:]]*public[[:space:]]+func ]] && ! grep -q "///" <<< "$(head -n $((line_num-1)) "$file" | tail -n 1)"; then
            echo -e "${WARNING} File $file: Public method lacks documentation (line $line_num)"
            CONVENTION_ISSUES=$((CONVENTION_ISSUES + 1))
            issues_found=$((issues_found + 1))
        fi
        
        line_num=$((line_num + 1))
    done < "$file"
    
    # Architecture checks (MVVM)
    if [[ "$file" =~ ViewModel ]]; then
        if grep -q "import UIKit" "$file" || grep -q "import SwiftUI" "$file"; then
            echo -e "${ERROR} File $file: ViewModel should not import UI frameworks (MVVM violation)"
            ARCHITECTURE_ISSUES=$((ARCHITECTURE_ISSUES + 1))
            issues_found=$((issues_found + 1))
        fi
    fi
    
    if [[ "$file" =~ View\.swift$ ]]; then
        if grep -q "URLSession\|UserDefaults\|CoreData" "$file"; then
            echo -e "${ERROR} File $file: View contains business logic (MVVM violation)"
            ARCHITECTURE_ISSUES=$((ARCHITECTURE_ISSUES + 1))
            issues_found=$((issues_found + 1))
        fi
    fi
    
    # iOS Memory Management checks
    if grep -q "Timer\.scheduledTimer" "$file" && ! grep -q "\[weak self\]" "$file"; then
        echo -e "${WARNING} File $file: Timer might create retain cycle - consider using [weak self]"
        IOS_ISSUES=$((IOS_ISSUES + 1))
        issues_found=$((issues_found + 1))
    fi
    
    if grep -q "var delegate.*:" "$file" && ! grep -q "weak var delegate" "$file"; then
        echo -e "${WARNING} File $file: Delegate property should be weak to prevent retain cycles"
        IOS_ISSUES=$((IOS_ISSUES + 1))
        issues_found=$((issues_found + 1))
    fi
    
    if grep -q "as!" "$file"; then
        echo -e "${WARNING} File $file: Force casting (as!) can cause crashes - consider using guard let with as?"
        IOS_ISSUES=$((IOS_ISSUES + 1))
        issues_found=$((issues_found + 1))
    fi
    
    return $issues_found
}

# Analyze all files
echo -e "${GEAR} Running Comprehensive Analysis"
echo "============================================================"

for file in "${SWIFT_FILES[@]}"; do
    echo -e "📝 Analyzing: $file"
    analyze_swift_file "$file"
done

# Calculate totals
TOTAL_ISSUES=$((SWIFTLINT_ISSUES + CONVENTION_ISSUES + ARCHITECTURE_ISSUES + IOS_ISSUES))

echo
echo -e "${CYAN}📊 Analysis Summary${NC}"
echo "============================================================"
echo -e "📈 Total Issues Found: $TOTAL_ISSUES"
echo -e "   ${GEAR} SwiftLint: $SWIFTLINT_ISSUES"
echo -e "   📝 Conventions: $CONVENTION_ISSUES"
echo -e "   🏗️  Architecture: $ARCHITECTURE_ISSUES"
echo -e "   📱 iOS Issues: $IOS_ISSUES"
echo

# Generate actionable fixes file
if [[ $TOTAL_ISSUES -gt 0 ]]; then
    cat > "$FIXES_FILE" << EOF
# 🔧 Swift Code Review - Actionable Fixes

**Click the file:line links to jump directly to issues in Cursor!**

## 📊 Current Status
- **Files Analyzed:** ${#SWIFT_FILES[@]} Swift files
- **Issues Found:** $TOTAL_ISSUES total issues
- **Recommendation:** $(if [[ $TOTAL_ISSUES -le 3 ]]; then echo "🟡 Review recommended"; elif [[ $TOTAL_ISSUES -le 8 ]]; then echo "🟠 Proceed with caution"; else echo "🔴 Do not commit"; fi)

## 🎯 Quick Fixes Available

### Cursor Integration Tips:
- **Click any file:line link** to jump directly to the issue
- **Press F2** to rename symbols (great for class names)
- **Press Cmd+.** for Quick Fix suggestions
- **Right-click** → "Source Action" for automated refactoring

### Common Fixes:

1. **Naming Issues**: Use F2 to rename classes to PascalCase
2. **Retain Cycles**: Add \`[weak self]\` to closures
3. **Force Casting**: Replace \`as!\` with \`guard let ... as?\`
4. **Delegate Properties**: Add \`weak\` keyword
5. **Documentation**: Add \`///\` comments above public methods

## 🔄 Re-run Review
After fixes, re-run: \`./.cursor/rules/tools/swift-review.sh\`

EOF
    
    echo -e "${INFO} Generated actionable fixes file: $FIXES_FILE"
fi

# Provide recommendation
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}🎯 COMMIT RECOMMENDATION${NC}"
echo -e "${CYAN}============================================================${NC}"

if [[ $TOTAL_ISSUES -eq 0 ]]; then
    echo -e "${CHECK} ${GREEN}SAFE TO COMMIT${NC} - No issues found!"
    echo -e "${ROCKET} Happy coding!"
    exit 0
elif [[ $TOTAL_ISSUES -le 3 ]]; then
    echo -e "${WARNING} ${YELLOW}REVIEW RECOMMENDED${NC} - $TOTAL_ISSUES minor issues found"
    echo -e "${INFO} Consider fixing these issues before committing"
    exit 1
elif [[ $TOTAL_ISSUES -le 8 ]]; then
    echo -e "${WARNING} ${YELLOW}PROCEED WITH CAUTION${NC} - $TOTAL_ISSUES issues found"
    echo -e "${INFO} You should fix critical issues before committing"
    exit 1
else
    echo -e "${ERROR} ${RED}DO NOT COMMIT${NC} - $TOTAL_ISSUES issues found!"
    echo -e "${FIRE} Please fix issues before committing"
    exit 1
fi 