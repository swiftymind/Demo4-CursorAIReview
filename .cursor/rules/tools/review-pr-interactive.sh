#!/bin/bash

# Interactive PR Review Script - Portable & Scalable for Any iOS Project
# Usage: ./review-pr-interactive.sh <PR_NUMBER>

set -e

PR_NUMBER=$1

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🎯 Interactive PR Review System v2.0${NC}"
echo -e "${CYAN}✨ Portable & Scalable for Any iOS Project${NC}"
echo ""

# Auto-detect repository from git remote
REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REPO_URL" ]; then
    echo -e "${RED}❌ Error: Could not detect GitHub repository. Make sure you're in a git repository with a GitHub remote.${NC}"
    exit 1
fi

# Extract owner/repo from GitHub URL (supports both SSH and HTTPS)
REPO_PATH=$(echo "$REPO_URL" | sed -E 's|^.*github\.com[:/]||' | sed 's|\.git$||')
if [ -z "$REPO_PATH" ]; then
    echo -e "${RED}❌ Error: Could not parse GitHub repository from URL: $REPO_URL${NC}"
    exit 1
fi

echo -e "${CYAN}🔍 Repository: $REPO_PATH${NC}"

if [ -z "$PR_NUMBER" ]; then
    echo -e "${RED}❌ Error: Please provide a PR number${NC}"
    echo "Usage: $0 <PR_NUMBER>"
    echo ""
    echo -e "${YELLOW}📋 Available open PRs:${NC}"
    curl -s "https://api.github.com/repos/$REPO_PATH/pulls?state=open" | grep -E '"number"|"title"' | sed 'N;s/\n/ /' | sed 's/.*"number": \([0-9]*\),.*"title": "\([^"]*\)".*/  PR #\1: \2/'
    exit 1
fi

echo -e "${BLUE}🔍 Interactive Review for PR #$PR_NUMBER...${NC}"
echo ""

# Check GitHub CLI authentication
if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
    else
        echo -e "${YELLOW}⚠️  GitHub CLI not authenticated. Run 'gh auth login' for better experience${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  GitHub CLI not found. Install with 'brew install gh' for better experience${NC}"
fi

# Get PR details
PR_INFO=$(curl -s "https://api.github.com/repos/$REPO_PATH/pulls/$PR_NUMBER")
PR_TITLE=$(echo "$PR_INFO" | grep '"title"' | cut -d'"' -f4)
PR_STATE=$(echo "$PR_INFO" | grep '"state"' | cut -d'"' -f4)

if [ "$PR_STATE" != "open" ]; then
    echo -e "${RED}❌ Error: PR #$PR_NUMBER is not open (state: $PR_STATE)${NC}"
    exit 1
fi

echo -e "${GREEN}📝 PR #$PR_NUMBER: $PR_TITLE${NC}"
echo -e "${BLUE}🔄 State: $PR_STATE${NC}"
echo ""

# Script directory (portable - works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load Swift conventions (flexible - multiple possible locations)
SWIFT_CONVENTIONS=""
SWIFT_CONVENTIONS_LOADED=false

# Try multiple possible locations for Swift conventions
POSSIBLE_CONVENTIONS_PATHS=(
    "$SCRIPT_DIR/../swift-conventions.mdc"
    "$SCRIPT_DIR/swift-conventions.mdc"
    "$(pwd)/.cursor/rules/swift-conventions.mdc"
    "$(pwd)/swift-conventions.mdc"
    "$(pwd)/docs/swift-conventions.mdc"
)

for conv_path in "${POSSIBLE_CONVENTIONS_PATHS[@]}"; do
    if [ -f "$conv_path" ]; then
        echo -e "${GREEN}📚 Loading Swift conventions from: $(basename "$conv_path")${NC}"
        SWIFT_CONVENTIONS=$(cat "$conv_path")
        SWIFT_CONVENTIONS_LOADED=true
        echo -e "${GREEN}✅ Swift conventions loaded successfully${NC}"
        break
    fi
done

if [ "$SWIFT_CONVENTIONS_LOADED" = false ]; then
    echo -e "${YELLOW}⚠️  Swift conventions file not found, using built-in iOS best practices${NC}"
fi

echo ""

# Fetch PR file changes
echo -e "${BLUE}🔍 Fetching changed files...${NC}"
PR_FILES=$(curl -s "https://api.github.com/repos/$REPO_PATH/pulls/$PR_NUMBER/files")

# Count files changed
FILES_COUNT=$(echo "$PR_FILES" | jq '. | length')
echo -e "${GREEN}📁 Found $FILES_COUNT changed files${NC}"
echo ""

# Array to store pending review comments
declare -a PENDING_COMMENTS=()

# Function to add review comment to pending list
add_pending_comment() {
    local file_path="$1"
    local line_num="$2"
    local comment="$3"
    
    PENDING_COMMENTS+=("$file_path|$line_num|$comment")
}

# Function to try opening file in Cursor IDE (enhanced for portability)
try_open_in_cursor() {
    local file_path="$1"
    local line_num="$2"
    
    # Try multiple ways to open Cursor
    if command -v cursor &> /dev/null; then
        echo -e "${CYAN}🎯 Opening file in Cursor IDE...${NC}"
        if cursor "$file_path:$line_num" 2>/dev/null; then
            echo -e "${GREEN}✅ File opened successfully${NC}"
        else
            # Fallback: try without line number
            cursor "$file_path" 2>/dev/null || {
                echo -e "${YELLOW}⚠️  Could not open in Cursor IDE${NC}"
            }
        fi
    elif command -v code &> /dev/null; then
        echo -e "${CYAN}🎯 Opening file in VS Code...${NC}"
        code -g "$file_path:$line_num" 2>/dev/null || {
            echo -e "${YELLOW}⚠️  Could not open in VS Code${NC}"
        }
    else
        echo -e "${YELLOW}⚠️  No supported editor (cursor/code) found${NC}"
        echo -e "${CYAN}💡 Install Cursor CLI: Add Cursor to PATH or install 'code' command${NC}"
    fi
}

# Function to show file context around the line
show_file_context() {
    local file_path="$1"
    local line_num="$2"
    
    if [ -f "$file_path" ]; then
        echo -e "${CYAN}📄 File Context:${NC}"
        echo -e "${PURPLE}───────────────────────────────────────${NC}"
        
        # Show 3 lines before and after the target line
        local start_line=$((line_num - 3))
        local end_line=$((line_num + 3))
        
        if [ $start_line -lt 1 ]; then
            start_line=1
        fi
        
        sed -n "${start_line},${end_line}p" "$file_path" | nl -ba -v$start_line | while IFS= read -r line; do
            local current_line=$(echo "$line" | awk '{print $1}')
            if [ "$current_line" -eq "$line_num" ]; then
                echo -e "${RED}➤ $line${NC}"
            else
                echo -e "${CYAN}  $line${NC}"
            fi
        done
        
        echo -e "${PURPLE}───────────────────────────────────────${NC}"
    else
        echo -e "${YELLOW}⚠️  File not found locally: $file_path${NC}"
    fi
}

# Enhanced function to extract actual line numbers from diff patch
extract_line_numbers_from_patch() {
    local patch="$1"
    local pattern="$2"
    
    local line_numbers=()
    local current_line=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ @@.*\+([0-9]+) ]]; then
            current_line="${BASH_REMATCH[1]}"
            continue
        fi
        
        if [[ "$line" =~ ^(\+)(.*) ]]; then
            local added_line="${BASH_REMATCH[2]}"
            if echo "$added_line" | grep -q "$pattern"; then
                line_numbers+=("$current_line")
            fi
            ((current_line++))
        elif [[ "$line" =~ ^\ .* ]]; then
            ((current_line++))
        fi
    done <<< "$patch"
    
    if [ ${#line_numbers[@]} -gt 0 ]; then
        echo "${line_numbers[0]}"
    fi
}

# Enhanced function to check Swift conventions with comprehensive iOS best practices
check_swift_conventions() {
    local filename="$1"
    local patch="$2"
    
    # iOS Framework and Architecture Checks
    
    # Check for XCTest usage (should use Swift Testing instead)
    if echo "$patch" | grep -q "import XCTest\|XCTestCase\|XCTest"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "import XCTest\|XCTestCase\|XCTest")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "⚠️ **Swift Testing Convention**: Use Swift Testing framework instead of XCTest. Import 'Testing' and use '@Suite' and '@Test' annotations for modern iOS development."
        fi
    fi
    
    # Check for force unwrapping (critical for iOS stability)
    if echo "$patch" | grep -q "!"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "!")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "⚠️ **iOS Safety**: Avoid force unwrapping which can cause crashes. Use optional binding (\`if let\`, \`guard let\`), nil coalescing operator (\`??\`), or optional chaining (\`?.\`) for safer iOS apps."
        fi
    fi
    
    # Check for proper error handling (essential for iOS apps)
    if echo "$patch" | grep -q "try!" || echo "$patch" | grep -q "try?"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "try!\|try?")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "🛡️ **iOS Error Handling**: Consider proper error handling with do-catch blocks instead of force try or optional try. This prevents unexpected crashes in production iOS apps."
        fi
    fi
    
    # Check for ViewModels without @MainActor (SwiftUI/UIKit best practice)
    if echo "$patch" | grep -q "ViewModel\|ViewController"; then
        if ! echo "$patch" | grep -q "@MainActor"; then
            local line_num=$(extract_line_numbers_from_patch "$patch" "ViewModel\|ViewController")
            if [ -n "$line_num" ]; then
                add_pending_comment "$filename" "$line_num" "🎯 **iOS Architecture**: ViewModels and ViewControllers should be marked with @MainActor to ensure UI updates happen on the main thread. This prevents common iOS threading issues."
            fi
        fi
    fi
    
    # Check for ObservableObject without @MainActor (SwiftUI specific)
    if echo "$patch" | grep -q "ObservableObject" && ! echo "$patch" | grep -q "@MainActor"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "ObservableObject")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "📱 **SwiftUI Best Practice**: ObservableObject classes should be marked with @MainActor for thread safety and to ensure UI updates occur on the main thread."
        fi
    fi
    
    # Check for weak delegate pattern (iOS memory management)
    if echo "$patch" | grep -q "var.*delegate.*:" && ! echo "$patch" | grep -q "weak"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "var.*delegate.*:")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "🔗 **iOS Memory Management**: Delegate properties should be declared as 'weak' to prevent retain cycles and memory leaks in iOS apps."
        fi
    fi
    
    # Check for missing ARC annotations on closures
    if echo "$patch" | grep -qE "\{.*self\." && ! echo "$patch" | grep -q "\[weak self\]\|\[unowned self\]"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "\{.*self\.")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "♻️ **iOS Memory Management**: Consider using [weak self] or [unowned self] in closures to prevent retain cycles. This is crucial for iOS memory management."
        fi
    fi
    
    # Check for proper iOS API usage
    if echo "$patch" | grep -q "DispatchQueue.main.async" && echo "$patch" | grep -q "@MainActor"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "DispatchQueue.main.async")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "🚀 **iOS Modernization**: Consider using async/await with @MainActor instead of DispatchQueue.main.async for cleaner, modern iOS code."
        fi
    fi
    
    # Check for Swift Testing best practices
    if echo "$patch" | grep -q "@Test"; then
        if ! echo "$patch" | grep -q '".*"'; then
            local line_num=$(extract_line_numbers_from_patch "$patch" "@Test")
            if [ -n "$line_num" ]; then
                add_pending_comment "$filename" "$line_num" "💡 **iOS Testing Best Practice**: Consider adding descriptive test names using @Test(\"Description\") format for better readability and maintainability."
            fi
        fi
    fi
    
    # Check for proper iOS naming conventions
    if echo "$patch" | grep -qE "func [a-z][A-Z]|var [a-z][A-Z]|let [a-z][A-Z]"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "func [a-z][A-Z]\|var [a-z][A-Z]\|let [a-z][A-Z]")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "📝 **iOS Naming Convention**: Use camelCase for functions and variables. Start with lowercase letter following Apple's Swift style guide."
        fi
    fi
    
    # Check for dependency injection patterns (iOS architecture)
    if echo "$patch" | grep -q "init.*:.*=" && ! echo "$patch" | grep -q "Container\|Resolver\|@Injected"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "init.*:.*=")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "🔧 **iOS Architecture**: Consider using dependency injection (like Swinject) to improve testability and follow SOLID principles in iOS development."
        fi
    fi
    
    # Check for missing documentation on public APIs
    if echo "$patch" | grep -qE "public\s+(class|struct|func|var|let)" && ! echo "$patch" | grep -qB3 "///"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "public\s+(class|struct|func|var|let)")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "📖 **iOS Documentation**: Public APIs should have comprehensive documentation using /// comments. This is especially important for iOS frameworks and shared components."
        fi
    fi
    
    # Check for hardcoded strings (iOS localization)
    if echo "$patch" | grep -qE '"[A-Za-z ]{4,}"' && ! echo "$patch" | grep -q "NSLocalizedString\|String(localized:"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" '"[A-Za-z ]{4,}"')
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "🌍 **iOS Localization**: Consider using NSLocalizedString or String(localized:) for user-facing strings to support internationalization in iOS apps."
        fi
    fi
    
    # Check for async/await best practices
    if echo "$patch" | grep -q "async" && echo "$patch" | grep -q "throws"; then
        if ! echo "$patch" | grep -q "async throws"; then
            local line_num=$(extract_line_numbers_from_patch "$patch" "async.*throws")
            if [ -n "$line_num" ]; then
                add_pending_comment "$filename" "$line_num" "⚡ **iOS Async/Await**: When a function is both async and throws, use 'async throws' order for consistency with iOS conventions."
            fi
        fi
    fi
    
    # Check for UIKit on background thread (common iOS issue)
    if echo "$patch" | grep -q "UI.*\." && echo "$patch" | grep -q "DispatchQueue.global\|Task.detached"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "UI.*\.")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "⚠️ **iOS Threading**: UIKit operations must be performed on the main thread. Ensure UI updates are wrapped with DispatchQueue.main.async or @MainActor."
        fi
    fi
    
    # Check for Core Data context usage
    if echo "$patch" | grep -q "NSManagedObjectContext" && ! echo "$patch" | grep -q "performAndWait\|perform"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "NSManagedObjectContext")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "💾 **iOS Core Data**: Consider using performAndWait or perform methods when working with NSManagedObjectContext for thread safety."
        fi
    fi
    
    # Check for proper iOS app lifecycle handling
    if echo "$patch" | grep -q "@UIApplicationMain\|@main" && ! echo "$patch" | grep -q "App.*:\s*App"; then
        local line_num=$(extract_line_numbers_from_patch "$patch" "@UIApplicationMain\|@main")
        if [ -n "$line_num" ]; then
            add_pending_comment "$filename" "$line_num" "📱 **iOS App Structure**: Consider using SwiftUI App protocol with @main for modern iOS app structure instead of UIApplicationMain."
        fi
    fi
}

# Function to analyze and review code
analyze_and_review() {
    local filename="$1"
    local patch="$2"
    local additions="$3"
    local deletions="$4"
    
    echo -e "${BLUE}🔍 Analyzing: $filename${NC}"
    
    # Apply Swift-specific conventions if it's a Swift file
    if [[ "$filename" == *.swift ]]; then
        echo -e "${YELLOW}🐦 Applying Swift conventions analysis...${NC}"
        check_swift_conventions "$filename" "$patch"
        
    elif [[ "$filename" == *Test*.swift || "$filename" == *Tests.swift ]]; then
        echo -e "${YELLOW}🧪 Applying Swift Testing conventions...${NC}"
        
        # Check for proper test structure
        if ! echo "$patch" | grep -q "@Suite\|@Test"; then
            local line_num=$(extract_line_numbers_from_patch "$patch" "import.*XCTest\|class.*XCTestCase")
            if [ -z "$line_num" ]; then line_num=1; fi
            add_pending_comment "$filename" "$line_num" "🧪 **Swift Testing Framework**: Use Swift Testing framework with @Suite and @Test annotations instead of XCTest."
        fi
        
        check_swift_conventions "$filename" "$patch"
        
    elif [[ "$filename" == *.md ]]; then
        # Markdown documentation review
        if echo "$patch" | grep -q "token\|password\|secret"; then
            add_pending_comment "$filename" "1" "⚠️ **Security Alert**: This documentation contains references to tokens/passwords. Consider using placeholders or environment variables instead."
        fi
        
        if [[ $additions -gt 100 ]]; then
            add_pending_comment "$filename" "1" "📖 **Documentation Review**: This is a substantial documentation addition ($additions lines). Great work on comprehensive documentation! Consider breaking it into smaller sections for better readability."
        fi
        
    elif [[ "$filename" == *.sh ]]; then
        # Shell script review
        if echo "$patch" | grep -q "curl.*-s"; then
            local line_num=$(extract_line_numbers_from_patch "$patch" "curl.*-s")
            if [ -z "$line_num" ]; then line_num=1; fi
            add_pending_comment "$filename" "$line_num" "🔒 **Security**: Consider adding timeout and retry logic to curl commands. Also validate API responses before processing."
        fi
        
        if ! echo "$patch" | grep -q "set -e"; then
            add_pending_comment "$filename" "1" "💡 **Best Practice**: Consider adding 'set -e' at the top of the script to exit on errors."
        fi
        
        if echo "$patch" | grep -q "echo.*\$"; then
            local line_num=$(extract_line_numbers_from_patch "$patch" "echo.*\$")
            if [ -z "$line_num" ]; then line_num=1; fi
            add_pending_comment "$filename" "$line_num" "🐛 **Potential Issue**: Unquoted variables in echo statements can cause issues. Consider using double quotes around variables."
        fi
    fi
    
    # Generic code quality checks
    if [[ $additions -gt 50 && $deletions -eq 0 ]]; then
        add_pending_comment "$filename" "1" "📏 **Code Size**: This is a large addition ($additions lines) with no deletions. Consider if this could be broken into smaller, more focused changes."
    fi
}

# Function to show and get approval for a comment
get_comment_approval() {
    local file_path="$1"
    local line_num="$2"
    local comment="$3"
    
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 Review Comment Approval${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}📁 File: ${GREEN}$file_path${NC}"
    echo -e "${CYAN}📍 Line: ${GREEN}$line_num${NC}"
    echo ""
    echo -e "${YELLOW}💬 Proposed Comment:${NC}"
    echo -e "${GREEN}$comment${NC}"
    echo ""
    
    # Try to open file in Cursor IDE
    try_open_in_cursor "$file_path" "$line_num"
    
    # Show file context
    show_file_context "$file_path" "$line_num"
    
    echo ""
    echo -e "${CYAN}What would you like to do?${NC}"
    echo -e "${GREEN}[a]pprove${NC} - Post this comment"
    echo -e "${YELLOW}[e]dit${NC}   - Edit the comment before posting"
    echo -e "${RED}[s]kip${NC}    - Skip this comment"
    echo -e "${BLUE}[q]uit${NC}    - Stop review process"
    echo ""
    
    while true; do
        read -p "Your choice [a/e/s/q]: " choice
        case $choice in
            [Aa]* )
                echo -e "${GREEN}✅ Comment approved!${NC}"
                return 0
                ;;
            [Ee]* )
                echo ""
                echo -e "${YELLOW}✏️  Edit comment (press Enter to keep original):${NC}"
                read -p "New comment: " new_comment
                if [ -n "$new_comment" ]; then
                    comment="$new_comment"
                    echo -e "${GREEN}✅ Comment updated and approved!${NC}"
                fi
                return 0
                ;;
            [Ss]* )
                echo -e "${YELLOW}⏭️  Comment skipped${NC}"
                return 1
                ;;
            [Qq]* )
                echo -e "${RED}🚪 Exiting review process...${NC}"
                exit 0
                ;;
            * )
                echo -e "${RED}Please answer [a]pprove, [e]dit, [s]kip, or [q]uit.${NC}"
                ;;
        esac
    done
}

# Function to post approved comment
post_approved_comment() {
    local file_path="$1"
    local line_num="$2"
    local comment="$3"
    
    echo -e "${BLUE}📤 Posting comment to GitHub...${NC}"
    
    if "$SCRIPT_DIR/gh-pr-comment.sh" pr review "$PR_NUMBER" \
        --comment -b "$comment" \
        --path "$file_path" \
        --line "$line_num" 2>/dev/null; then
        echo -e "${GREEN}✅ Comment posted successfully!${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to post comment${NC}"
        return 1
    fi
}

# Start interactive review
echo -e "${PURPLE}🤖 Starting Interactive Code Review...${NC}"
echo -e "${CYAN}🎯 Analyzing code patterns, security, Swift conventions, and best practices${NC}"
echo ""

# Process each changed file to collect pending comments
echo "$PR_FILES" | jq -c '.[]' > /tmp/pr_files.json

while IFS= read -r file_data; do
    filename=$(echo "$file_data" | jq -r '.filename')
    patch=$(echo "$file_data" | jq -r '.patch // ""')
    additions=$(echo "$file_data" | jq -r '.additions')
    deletions=$(echo "$file_data" | jq -r '.deletions')
    
    # Skip if no patch (binary files, etc.)
    if [ "$patch" = "null" ] || [ -z "$patch" ]; then
        echo -e "${YELLOW}⏭️  Skipping $filename (no diff available)${NC}"
        continue
    fi
    
    analyze_and_review "$filename" "$patch" "$additions" "$deletions"
done < /tmp/pr_files.json

# Clean up temp file
rm -f /tmp/pr_files.json

# Show summary and process pending comments
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 Review Analysis Complete${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ ${#PENDING_COMMENTS[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 No review comments found! The code looks good.${NC}"
    exit 0
fi

echo -e "${CYAN}Found ${GREEN}${#PENDING_COMMENTS[@]}${CYAN} potential review comments${NC}"
echo -e "${YELLOW}Let's go through them one by one...${NC}"

# Process each pending comment
approved_count=0
skipped_count=0
failed_count=0

for comment_data in "${PENDING_COMMENTS[@]}"; do
    IFS='|' read -r file_path line_num comment <<< "$comment_data"
    
    if get_comment_approval "$file_path" "$line_num" "$comment"; then
        if post_approved_comment "$file_path" "$line_num" "$comment"; then
            ((approved_count++))
        else
            ((failed_count++))
        fi
    else
        ((skipped_count++))
    fi
done

# Final summary
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🎉 Interactive Review Complete!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ Comments approved and posted: $approved_count${NC}"
echo -e "${YELLOW}⏭️  Comments skipped: $skipped_count${NC}"
echo -e "${RED}❌ Comments failed to post: $failed_count${NC}"
echo ""
echo -e "${CYAN}🌐 View PR with comments: https://github.com/$REPO_PATH/pull/$PR_NUMBER${NC}"
echo ""
echo -e "${PURPLE}💡 Thank you for the interactive review!${NC}" 
echo -e "${PURPLE}💡 Thank you for the interactive review!${NC}" 