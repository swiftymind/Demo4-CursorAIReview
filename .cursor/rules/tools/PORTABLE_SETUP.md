# 🚀 Portable iOS PR Review System

> **Enhanced Interactive Review System v2.0** - Copy to any iOS project and start reviewing!

## 📦 What's Included

### 🛠️ Core Scripts
- **`review-pr.sh`** - Automated PR review with Swift conventions
- **`review-pr-interactive.sh`** - **NEW!** Interactive review with user approval
- **`gh-pr-comment.sh`** - GitHub comment posting utility

### 📚 Configuration Files
- **`swift-conventions.mdc`** - Comprehensive iOS coding standards
- **`github-pr-review.mdc`** - PR review guidelines
- **`memory-management.mdc`** - iOS memory management best practices

### 🎯 Convenience Files
- **`pr-review-aliases.fish`** - Fish shell shortcuts
- **`pr-review-aliases.sh`** - Bash/Zsh shortcuts
- **`PORTABLE_SETUP.md`** - This documentation

## 🎯 Key Features

### ✨ Interactive Review System
- **Manual Approval**: Review each comment before posting
- **File Navigation**: Opens files in Cursor IDE at specific lines
- **Context Display**: Shows code around problematic lines
- **Edit Comments**: Modify suggestions before posting
- **Selective Posting**: Skip comments you don't want

### 🤖 Automated Analysis
- **Swift Conventions**: Modern iOS development practices
- **Memory Management**: ARC, weak delegates, closure capture
- **Threading Safety**: @MainActor, UI thread violations
- **Architecture**: MVVM, dependency injection, SOLID principles
- **Testing**: Swift Testing framework recommendations
- **Localization**: Hardcoded string detection

### 🔧 Portability Features
- **Auto-Repository Detection**: Works with any GitHub repo
- **Flexible Convention Loading**: Multiple search paths
- **Editor Support**: Cursor IDE + VS Code fallback
- **Zero Configuration**: Copy and run immediately

## 🚀 Quick Start

### 1. Copy to Any iOS Project
```bash
# Copy the entire .cursor/rules/tools/ directory to your iOS project
cp -r .cursor/rules/tools/ /path/to/your/ios-project/.cursor/rules/
```

### 2. Make Scripts Executable
```bash
cd /path/to/your/ios-project
chmod +x .cursor/rules/tools/*.sh
```

### 3. Load Aliases (Optional)
```bash
# For Fish shell
source .cursor/rules/tools/pr-review-aliases.fish

# For Bash/Zsh
source .cursor/rules/tools/pr-review-aliases.sh
```

### 4. Start Reviewing!
```bash
# Interactive review (recommended)
./.cursor/rules/tools/review-pr-interactive.sh 1

# Or automated review
./.cursor/rules/tools/review-pr.sh 1

# Using aliases (if loaded)
interactive-review 1
```

## 📋 Usage Examples

### Interactive Review Workflow
```bash
# 1. List available PRs
./.cursor/rules/tools/review-pr-interactive.sh

# 2. Review specific PR interactively
./.cursor/rules/tools/review-pr-interactive.sh 3

# 3. For each found issue:
#    - See file context
#    - File opens in Cursor IDE
#    - Choose: [a]pprove, [e]dit, [s]kip, [q]uit
#    - Comments posted only after approval
```

### Automated Review
```bash
# Quick automated review
./.cursor/rules/tools/review-pr.sh 2

# All comments posted automatically
```

### Manual Comment Posting
```bash
# Post individual comment
./.cursor/rules/tools/gh-pr-comment.sh pr review 1 \
  --comment -b "Consider using async/await here" \
  --path "Sources/ViewModel.swift" \
  --line 42
```

## 🔧 Configuration

### Swift Conventions Auto-Discovery
The system automatically searches for Swift conventions in:
1. `.cursor/rules/swift-conventions.mdc`
2. `swift-conventions.mdc` (project root)
3. `docs/swift-conventions.mdc`

If none found, uses built-in iOS best practices.

### GitHub Authentication
```bash
# Recommended: Use GitHub CLI
gh auth login

# Alternative: Environment variable
export GITHUB_TOKEN="your_token_here"
```

## 📱 iOS-Specific Checks

### 🏗️ Architecture & Design Patterns
- MVVM compliance (ViewModels with @MainActor)
- Dependency injection patterns
- SOLID principles violations
- Proper delegate patterns (weak references)

### 🧠 Memory Management
- Force unwrapping detection
- Weak reference patterns for delegates
- Closure capture list recommendations ([weak self])
- ARC best practices

### 🎯 Threading & Concurrency
- @MainActor usage for ViewModels/Controllers
- UIKit main thread violations
- Modern async/await patterns
- DispatchQueue.main.async recommendations

### 🧪 Testing & Quality
- Swift Testing framework over XCTest
- Descriptive test naming
- Error handling patterns (do-catch vs try!)
- Public API documentation requirements

### 🌍 iOS App Considerations
- Localization string detection (NSLocalizedString)
- Core Data context thread safety
- Modern app lifecycle (@main vs @UIApplicationMain)
- SwiftUI ObservableObject thread safety

## 🛠️ Advanced Usage

### Custom Review Rules
Edit `review-pr-interactive.sh` to add project-specific checks:

```bash
# Add custom checks in check_swift_conventions function
if echo "$patch" | grep -q "YourCustomPattern"; then
    add_pending_comment "$filename" "$line_num" "🔧 **Custom Rule**: Your advice here"
fi
```

### Multiple Projects
```bash
# Create project-specific aliases
alias review-project1='cd /path/to/project1 && interactive-review'
alias review-project2='cd /path/to/project2 && interactive-review'
```

### CI/CD Integration
```bash
# GitHub Actions example
- name: iOS PR Review
  run: |
    ./.cursor/rules/tools/review-pr.sh ${{ github.event.pull_request.number }}
```

## 📊 What Gets Checked

### ✅ Automatically Detected Issues
- Force unwrapping (`!`) in Swift code
- Missing @MainActor on ViewModels/Controllers
- XCTest usage (suggests Swift Testing)
- Strong delegate references (suggests weak)
- Missing [weak self] in closures
- UIKit operations on background threads
- Hardcoded user-facing strings
- Missing public API documentation

### 🎯 Architecture Patterns
- MVVM compliance
- Dependency injection opportunities
- SOLID principles adherence
- Modern Swift/iOS API usage
- Threading safety patterns

### 📱 iOS-Specific Recommendations
- SwiftUI ObservableObject best practices
- Core Data thread safety
- Modern app lifecycle patterns
- Localization support
- Memory management patterns

## 🔍 Troubleshooting

### Common Issues

1. **"Could not detect GitHub repository"**
   ```bash
   # Ensure you're in a git repository with GitHub remote
   git remote -v
   ```

2. **"GitHub CLI not authenticated"**
   ```bash
   gh auth login
   # or
   export GITHUB_TOKEN="your_token"
   ```

3. **"Cursor CLI not available"**
   ```bash
   # Add Cursor to PATH or install VS Code
   # The system will fallback to VS Code automatically
   ```

4. **"No Swift conventions found"**
   ```
   # This is normal - system uses built-in iOS best practices
   # Optionally copy swift-conventions.mdc to your project
   ```

## 📈 Best Practices

### 1. Interactive vs Automated
- **Use Interactive** for thorough reviews of important PRs
- **Use Automated** for quick checks and CI/CD

### 2. Review Strategy
- Focus on **actionable feedback**
- Prioritize **safety and architecture** issues
- Skip **style-only** comments
- Consider **team conventions**

### 3. Comment Quality
- Be **specific** and **constructive**
- Provide **alternatives** when possible
- Reference **Apple documentation** for iOS patterns
- Keep comments **concise** but **clear**

## 🌟 Advanced Features

### File Opening Integration
- **Cursor IDE**: Primary editor support
- **VS Code**: Automatic fallback
- **Line-specific**: Opens at exact problem location
- **Context Display**: Shows surrounding code

### Smart Convention Loading
- **Auto-discovery**: Finds conventions in multiple locations
- **Fallback System**: Uses built-in iOS practices
- **Project-specific**: Can override with local conventions
- **Team Standards**: Easy to share across projects

### Comprehensive iOS Coverage
- **All iOS Frameworks**: UIKit, SwiftUI, Core Data, etc.
- **Modern Patterns**: async/await, @MainActor, Swift Testing
- **Memory Safety**: ARC patterns, weak references
- **Architecture**: MVVM, SOLID, dependency injection

---

## 🎉 Ready to Use!

The system is **100% portable** and requires **zero configuration**. Simply copy the files and start reviewing PRs in any iOS project!

```bash
# That's it! Start reviewing:
interactive-review 1
```

**Made with ❤️ for better iOS code reviews** 