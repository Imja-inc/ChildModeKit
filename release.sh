#!/bin/bash

set -euo pipefail

# Configuration
MAIN_BRANCH="main"
CHANGELOG_FILE="CHANGELOG.md"
PUSH_TAGS=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH_TAGS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--push] [--help]"
            echo ""
            echo "Options:"
            echo "  --push    Push the created tag to remote repository"
            echo "  --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validation functions
check_git_status() {
    log_info "Checking git status..."
    
    if [[ $(git status --porcelain) ]]; then
        log_error "Working directory is not clean. Please commit or stash changes."
        exit 1
    fi
    
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "$MAIN_BRANCH" ]]; then
        log_error "Not on $MAIN_BRANCH branch. Current branch: $current_branch"
        exit 1
    fi
    
    log_success "Git status check passed"
}

check_changelog() {
    log_info "Checking CHANGELOG.md..."
    
    if [[ ! -f "$CHANGELOG_FILE" ]]; then
        log_error "CHANGELOG.md not found"
        exit 1
    fi
    
    if ! grep -q "## \[Unreleased\]" "$CHANGELOG_FILE"; then
        log_error "No [Unreleased] section found in CHANGELOG.md"
        exit 1
    fi
    
    # Check if there are actual changes in the unreleased section
    local unreleased_content
    unreleased_content=$(awk '/## \[Unreleased\]/{flag=1;next} /^## /{flag=0} flag' "$CHANGELOG_FILE" | grep -v '^$' || true)
    
    if [[ -z "$unreleased_content" ]]; then
        log_error "No unreleased changes found in CHANGELOG.md"
        exit 1
    fi
    
    log_success "CHANGELOG.md check passed"
}

run_security_checks() {
    log_info "Running security checks..."
    
    # Check if we have security tools available
    if command -v swiftlint >/dev/null 2>&1; then
        log_info "Running SwiftLint security checks..."
        swiftlint lint --strict --reporter github-actions-logging || {
            log_error "SwiftLint security checks failed"
            exit 1
        }
    else
        log_warning "SwiftLint not available, skipping lint checks"
    fi
    
    # Check for common security issues
    log_info "Checking for hardcoded secrets..."
    if grep -r -i "password\|secret\|key\|token" Sources/ --include="*.swift" | grep -v "// " | grep -v "//" >/dev/null; then
        log_warning "Potential hardcoded secrets found. Please review manually."
        grep -r -i "password\|secret\|key\|token" Sources/ --include="*.swift" | grep -v "// " | grep -v "//" || true
    fi
    
    log_success "Security checks completed"
}

calculate_version() {
    log_info "Calculating next version..."
    
    # Get the latest tag, if any
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -z "$last_tag" ]]; then
        log_info "No previous tags found, starting with v1.0.0"
        echo "v1.0.0"
        return
    fi
    
    log_info "Last tag: $last_tag"
    
    # Parse version components (assuming format vX.Y.Z)
    if [[ ! "$last_tag" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        log_error "Last tag '$last_tag' does not follow semantic versioning (vX.Y.Z)"
        exit 1
    fi
    
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"
    local patch="${BASH_REMATCH[3]}"
    
    # Count commits since last tag
    local distance
    distance=$(git rev-list "${last_tag}..HEAD" --count)
    
    if [[ "$distance" -eq 0 ]]; then
        log_error "No new commits since last tag. Nothing to release."
        exit 1
    fi
    
    log_info "Distance since last tag: $distance commits"
    
    # Calculate new patch version
    local new_patch=$((patch + distance))
    local new_version="v${major}.${minor}.${new_patch}"
    
    log_info "Calculated new version: $new_version"
    echo "$new_version"
}

update_changelog() {
    local version="$1"
    local date=$(date +"%Y-%m-%d")
    
    log_info "Updating CHANGELOG.md for version $version..."
    
    # Create backup
    cp "$CHANGELOG_FILE" "${CHANGELOG_FILE}.backup"
    
    # Update changelog
    sed -i.tmp "s/## \[Unreleased\]/## [Unreleased]\n\n## [$version] - $date/" "$CHANGELOG_FILE"
    rm "${CHANGELOG_FILE}.tmp" 2>/dev/null || true
    
    log_success "CHANGELOG.md updated"
}

create_tag() {
    local version="$1"
    
    log_info "Creating annotated tag $version..."
    
    # Generate tag message from unreleased changelog content
    local tag_message
    tag_message="ChildModeKit $version

$(awk '/## \[Unreleased\]/{flag=1;next} /^## /{flag=0} flag' "$CHANGELOG_FILE" | grep -v '^$' | head -20)"
    
    git add "$CHANGELOG_FILE"
    git commit -m "Release $version

Update CHANGELOG.md for $version release"
    
    git tag -a "$version" -m "$tag_message"
    
    log_success "Tag $version created"
}

push_changes() {
    local version="$1"
    
    if [[ "$PUSH_TAGS" == true ]]; then
        log_info "Pushing changes and tag to remote..."
        git push origin "$MAIN_BRANCH"
        git push origin "$version"
        log_success "Changes and tag pushed to remote"
    else
        log_info "Tag created locally. Use 'git push origin $MAIN_BRANCH && git push origin $version' to publish"
    fi
}

# Main execution
main() {
    log_info "Starting ChildModeKit release process..."
    
    check_git_status
    check_changelog
    run_security_checks
    
    local new_version
    new_version=$(calculate_version)
    
    log_info "Preparing release $new_version..."
    
    update_changelog "$new_version"
    create_tag "$new_version"
    push_changes "$new_version"
    
    log_success "Release $new_version completed successfully!"
    
    if [[ "$PUSH_TAGS" == false ]]; then
        log_info "To publish this release, run:"
        log_info "  git push origin $MAIN_BRANCH"
        log_info "  git push origin $new_version"
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi