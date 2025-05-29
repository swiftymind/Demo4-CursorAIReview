# 🚀 Enhanced iOS PR Review Aliases for Bash/Zsh
# Portable & Scalable for Any iOS Project
# Source this file to get convenient shortcuts for PR review

# === CORE ALIASES ===
alias review-pr='./.cursor/rules/tools/review-pr.sh'
alias interactive-review='./.cursor/rules/tools/review-pr-interactive.sh'
alias pr-comment='./.cursor/rules/tools/gh-pr-comment.sh pr review'

# === QUICK ACCESS ===
alias ir='interactive-review'                    # Super quick interactive review
alias rpr='review-pr'                           # Quick automated review
alias list-prs='curl -s "https://api.github.com/repos/$(git remote get-url origin | sed -E "s|^.*github\.com[:/]||" | sed "s|\.git$||")/pulls?state=open" | grep -E "\"number\"|\"title\"" | sed "N;s/\\n/ /" | sed "s/.*\"number\": \\([0-9]*\\),.*\"title\": \"\\([^\"]*\\)\".*/  PR #\\1: \\2/"'

# === NUMBERED SHORTCUTS ===
# Quick review shortcuts for common PRs
alias review-pr1='./.cursor/rules/tools/review-pr.sh 1'
alias review-pr2='./.cursor/rules/tools/review-pr.sh 2'
alias review-pr3='./.cursor/rules/tools/review-pr.sh 3'
alias review-pr4='./.cursor/rules/tools/review-pr.sh 4'
alias review-pr5='./.cursor/rules/tools/review-pr.sh 5'

# Interactive review shortcuts
alias interactive-pr1='./.cursor/rules/tools/review-pr-interactive.sh 1'
alias interactive-pr2='./.cursor/rules/tools/review-pr-interactive.sh 2'
alias interactive-pr3='./.cursor/rules/tools/review-pr-interactive.sh 3'
alias interactive-pr4='./.cursor/rules/tools/review-pr-interactive.sh 4'
alias interactive-pr5='./.cursor/rules/tools/review-pr-interactive.sh 5'

# === WORKFLOW HELPERS ===
alias check-auth='gh auth status'
alias setup-review='echo "🚀 iOS PR Review System Setup"; echo ""; echo "📋 Available Commands:"; echo "  ir <PR_NUMBER>           - Interactive review"; echo "  rpr <PR_NUMBER>          - Automated review"; echo "  list-prs                 - Show open PRs"; echo "  check-auth               - Check GitHub auth"; echo ""; echo "🎯 Quick Start:"; echo "  ir 1                     - Review PR #1 interactively"; echo "  rpr 2                    - Review PR #2 automatically"'

# === iOS PROJECT HELPERS ===
alias ios-review-setup='echo "📱 iOS PR Review System"; echo ""; echo "✅ Core Features:"; echo "  • Swift conventions checking"; echo "  • iOS memory management"; echo "  • Threading safety (@MainActor)"; echo "  • Architecture patterns (MVVM)"; echo "  • SwiftUI best practices"; echo ""; echo "🎯 Usage:"; echo "  ir <PR_NUMBER>  - Interactive review with approval"; echo "  rpr <PR_NUMBER> - Automated review"; echo ""; gh auth status 2>/dev/null && echo "✅ GitHub authenticated" || echo "⚠️  Run: gh auth login"'

# === CONVENIENCE FUNCTIONS ===
quick-review() {
    if [ $# -eq 0 ]; then
        echo "Usage: quick-review <PR_NUMBER> [interactive|auto]"
        echo ""
        echo "Examples:"
        echo "  quick-review 1           # Interactive review (default)"
        echo "  quick-review 2 auto      # Automated review"
        echo "  quick-review 3 interactive # Interactive review"
        return 1
    fi
    
    local pr_number="$1"
    local review_type="interactive"
    
    if [ $# -gt 1 ]; then
        review_type="$2"
    fi
    
    case "$review_type" in
        auto|automated)
            echo "🤖 Running automated review for PR #$pr_number..."
            ./.cursor/rules/tools/review-pr.sh "$pr_number"
            ;;
        interactive|i)
            echo "👥 Running interactive review for PR #$pr_number..."
            ./.cursor/rules/tools/review-pr-interactive.sh "$pr_number"
            ;;
        *)
            echo "❌ Unknown review type: $review_type"
            echo "Use: interactive, auto"
            return 1
            ;;
    esac
}

# Display help when sourcing
echo "🎯 iOS PR Review Aliases Loaded!"
echo ""
echo "📋 Key Commands:"
echo "  ir <PR_NUMBER>      - Interactive review"
echo "  rpr <PR_NUMBER>     - Automated review"
echo "  list-prs            - Show open PRs"
echo "  setup-review        - Show all commands"
echo ""
echo "🎯 Quick Start: ir 1" 