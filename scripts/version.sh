#!/bin/bash

set -euo pipefail

# Configuration
MAIN_BRANCH="main"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get current version information
get_current_version() {
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -z "$last_tag" ]]; then
        echo "v1.0.0"
        return
    fi
    
    echo "$last_tag"
}

# Calculate next version using distance-based versioning
calculate_next_version() {
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -z "$last_tag" ]]; then
        echo "v1.0.0"
        return
    fi
    
    # Parse version components (assuming format vX.Y.Z)
    if [[ ! "$last_tag" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        echo "Error: Last tag '$last_tag' does not follow semantic versioning (vX.Y.Z)" >&2
        exit 1
    fi
    
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"
    local patch="${BASH_REMATCH[3]}"
    
    # Count commits since last tag
    local distance
    distance=$(git rev-list "${last_tag}..HEAD" --count)
    
    if [[ "$distance" -eq 0 ]]; then
        echo "$last_tag"
        return
    fi
    
    # Calculate new patch version
    local new_patch=$((patch + distance))
    local new_version="v${major}.${minor}.${new_patch}"
    
    echo "$new_version"
}

# Get commit information
get_commit_info() {
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -z "$last_tag" ]]; then
        local total_commits
        total_commits=$(git rev-list --count HEAD)
        echo "Total commits: $total_commits"
        return
    fi
    
    local distance
    distance=$(git rev-list "${last_tag}..HEAD" --count)
    
    echo "Commits since $last_tag: $distance"
    
    if [[ "$distance" -gt 0 ]]; then
        echo "Recent commits:"
        git log --oneline "${last_tag}..HEAD" | head -5
    fi
}

# Show branch information
get_branch_info() {
    local current_branch
    current_branch=$(git branch --show-current)
    
    echo "Current branch: $current_branch"
    
    if [[ "$current_branch" != "$MAIN_BRANCH" ]]; then
        echo "⚠️  Not on $MAIN_BRANCH branch"
    fi
    
    # Check if there are uncommitted changes
    if [[ $(git status --porcelain) ]]; then
        echo "⚠️  Uncommitted changes detected"
    fi
}

# Main function
main() {
    local command="${1:-info}"
    
    case "$command" in
        "current"|"info")
            echo -e "${BLUE}ChildModeKit Version Information${NC}"
            echo "=================================="
            echo ""
            echo -e "${GREEN}Current Version:${NC} $(get_current_version)"
            echo -e "${GREEN}Next Version:${NC} $(calculate_next_version)"
            echo ""
            get_commit_info
            echo ""
            get_branch_info
            ;;
        "next")
            calculate_next_version
            ;;
        "current-only")
            get_current_version
            ;;
        "commits")
            get_commit_info
            ;;
        "help"|"--help"|"-h")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  info, current    Show complete version information (default)"
            echo "  next             Show only the next version number"
            echo "  current-only     Show only the current version number"
            echo "  commits          Show commit information since last tag"
            echo "  help             Show this help message"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi