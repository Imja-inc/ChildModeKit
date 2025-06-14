# ChildModeKit Makefile
# Development and release automation

.PHONY: help build test lint security clean release docs install-tools format

# Default target
help: ## Show this help message
	@echo "ChildModeKit Development Commands"
	@echo "================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development commands
build: ## Build the package in debug mode
	@echo "🔨 Building ChildModeKit..."
	swift build

build-release: ## Build the package in release mode
	@echo "🔨 Building ChildModeKit (Release)..."
	swift build -c release

test: ## Run all tests
	@echo "🧪 Running tests..."
	swift test --enable-code-coverage

test-verbose: ## Run tests with verbose output
	@echo "🧪 Running tests (verbose)..."
	swift test --enable-code-coverage --verbose

lint: ## Run SwiftLint
	@echo "🔍 Running SwiftLint..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint; \
	else \
		echo "⚠️  SwiftLint not installed. Run 'make install-tools' first."; \
	fi

lint-fix: ## Run SwiftLint with auto-fix
	@echo "🔧 Running SwiftLint with auto-fix..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --fix; \
	else \
		echo "⚠️  SwiftLint not installed. Run 'make install-tools' first."; \
	fi

format: ## Format code with SwiftFormat
	@echo "🎨 Formatting code..."
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat Sources/ Tests/ Examples/; \
	else \
		echo "⚠️  SwiftFormat not installed. Run 'make install-tools' first."; \
	fi

security: ## Run security checks
	@echo "🔒 Running security checks..."
	@echo "Checking for potential secrets..."
	@if grep -r -i "password\|secret\|key\|token" Sources/ --include="*.swift" | grep -v "// " | grep -v "//" | head -5; then \
		echo "⚠️  Potential secrets found. Please review."; \
	else \
		echo "✅ No obvious secrets detected."; \
	fi
	@if command -v gitleaks >/dev/null 2>&1; then \
		echo "Running GitLeaks..."; \
		gitleaks detect --config .gitleaks.toml; \
	else \
		echo "⚠️  GitLeaks not installed. Install with: brew install gitleaks"; \
	fi

# Documentation
docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	swift package generate-documentation

docs-preview: ## Preview documentation (requires Xcode)
	@echo "📚 Generating documentation preview..."
	xcodebuild docbuild \
		-scheme ChildModeKit \
		-destination generic/platform=iOS

# Package management
clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	swift package clean
	rm -rf .build
	rm -rf DerivedData

reset: ## Reset package dependencies
	@echo "🔄 Resetting package dependencies..."
	swift package reset
	swift package resolve

# Release commands
validate-release: ## Validate everything is ready for release
	@echo "✅ Validating release readiness..."
	@$(MAKE) security
	@$(MAKE) lint
	@$(MAKE) test
	@$(MAKE) build-release
	@echo "📋 Checking CHANGELOG.md..."
	@if grep -q "## \[Unreleased\]" CHANGELOG.md; then \
		echo "✅ CHANGELOG.md has unreleased section"; \
	else \
		echo "❌ CHANGELOG.md missing [Unreleased] section"; \
		exit 1; \
	fi
	@echo "🎯 All validation checks passed!"

release: ## Create a new release (with distance-based versioning)
	@echo "🚀 Creating release..."
	@if [ ! -f "./release.sh" ]; then \
		echo "❌ release.sh not found"; \
		exit 1; \
	fi
	@./release.sh

release-push: ## Create and push a new release
	@echo "🚀 Creating and pushing release..."
	@if [ ! -f "./release.sh" ]; then \
		echo "❌ release.sh not found"; \
		exit 1; \
	fi
	@./release.sh --push

# Tool installation
install-tools: ## Install development tools
	@echo "🔧 Installing development tools..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "❌ Homebrew not found. Please install Homebrew first."; \
		exit 1; \
	fi
	@echo "Installing SwiftLint..."
	@brew list swiftlint >/dev/null 2>&1 || brew install swiftlint
	@echo "Installing SwiftFormat..."
	@brew list swiftformat >/dev/null 2>&1 || brew install swiftformat
	@echo "Installing GitLeaks..."
	@brew list gitleaks >/dev/null 2>&1 || brew install gitleaks
	@echo "✅ All tools installed!"

# Quality checks
check: ## Run all quality checks
	@echo "🔍 Running all quality checks..."
	@$(MAKE) security
	@$(MAKE) lint
	@$(MAKE) test
	@$(MAKE) build-release
	@echo "✅ All checks passed!"

# CI simulation
ci: ## Simulate CI pipeline locally
	@echo "🤖 Simulating CI pipeline..."
	@echo "============================"
	@$(MAKE) security
	@echo ""
	@$(MAKE) lint
	@echo ""
	@$(MAKE) test
	@echo ""
	@$(MAKE) build-release
	@echo ""
	@$(MAKE) docs
	@echo ""
	@echo "✅ CI simulation completed successfully!"

# Coverage
coverage: ## Generate and open code coverage report
	@echo "📊 Generating code coverage..."
	swift test --enable-code-coverage
	@echo "Coverage data generated. Use Xcode to view detailed reports."

# Integration tests
integration-test: ## Run integration tests
	@echo "🔗 Running integration tests..."
	@mkdir -p .tmp/integration-test
	@cd .tmp/integration-test && \
	cat > Package.swift << 'EOF' && \
	// swift-tools-version:5.9\
	import PackageDescription\
	\
	let package = Package(\
	    name: "IntegrationTest",\
	    platforms: [.iOS(.v15), .macOS(.v12)],\
	    dependencies: [\
	        .package(path: "../../")\
	    ],\
	    targets: [\
	        .executableTarget(\
	            name: "IntegrationTest",\
	            dependencies: ["ChildModeKit"]\
	        )\
	    ]\
	)\
	EOF\
	mkdir -p Sources/IntegrationTest && \
	cat > Sources/IntegrationTest/main.swift << 'EOF' && \
	import ChildModeKit\
	\
	let config = ChildModeConfiguration(appIdentifier: "IntegrationTest")\
	let timerManager = TimerManager(configuration: config)\
	\
	print("✅ ChildModeKit integration test passed")\
	EOF\
	swift run IntegrationTest
	@rm -rf .tmp/integration-test
	@echo "✅ Integration test completed!"

# Development workflow
dev-setup: ## Set up development environment
	@echo "🛠️  Setting up development environment..."
	@$(MAKE) install-tools
	@$(MAKE) reset
	@$(MAKE) build
	@echo "✅ Development environment ready!"

# Quick development commands
quick-test: ## Quick test (no coverage)
	@swift test

quick-check: ## Quick quality check
	@$(MAKE) lint
	@$(MAKE) quick-test