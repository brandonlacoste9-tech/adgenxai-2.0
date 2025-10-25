#!/usr/bin/env bash
# Repository Security Audit Script
# Scans for secrets, suspicious CI changes, and dependency advisories
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="${REPO_ROOT}/repo-audit-report.txt"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M UTC")

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize report
echo "========================================" > "$REPORT_FILE"
echo "Repository Security Audit Report" >> "$REPORT_FILE"
echo "Timestamp: $TIMESTAMP" >> "$REPORT_FILE"
echo "Repository: ${GITHUB_REPOSITORY:-$(git config --get remote.origin.url)}" >> "$REPORT_FILE"
echo "========================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Counter for findings
TOTAL_FINDINGS=0
CRITICAL_FINDINGS=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $1" >> "$REPORT_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $1" >> "$REPORT_FILE"
    ((TOTAL_FINDINGS++))
}

log_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
    echo "[CRITICAL] $1" >> "$REPORT_FILE"
    ((TOTAL_FINDINGS++))
    ((CRITICAL_FINDINGS++))
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    echo "[PASS] $1" >> "$REPORT_FILE"
}

section_header() {
    echo "" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "$1" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# 1. SECRET SCANNING
section_header "1. Secret Scanning"

log_info "Scanning for hardcoded secrets and credentials..."

# Common secret patterns
PATTERNS=(
    # API Keys and Tokens
    "password\s*=\s*['\"][^'\"]{8,}"
    "api[_-]?key\s*=\s*['\"][^'\"]{16,}"
    "api[_-]?secret\s*=\s*['\"][^'\"]{16,}"
    "access[_-]?token\s*=\s*['\"][^'\"]{16,}"
    "auth[_-]?token\s*=\s*['\"][^'\"]{16,}"
    "secret[_-]?key\s*=\s*['\"][^'\"]{16,}"
    # GitHub tokens
    "gh[pousr]_[0-9a-zA-Z]{36}"
    # AWS
    "AKIA[0-9A-Z]{16}"
    "aws[_-]?access[_-]?key[_-]?id\s*=\s*['\"][^'\"]{16,}"
    "aws[_-]?secret[_-]?access[_-]?key\s*=\s*['\"][^'\"]{32,}"
    # Private keys
    "BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY"
    # Slack tokens
    "xox[pbar]-[0-9]{12}-[0-9]{12}-[0-9a-zA-Z]{24}"
    # Generic secrets in env vars
    "export\s+[A-Z_]*SECRET[A-Z_]*\s*=\s*['\"][^'\"]{8,}"
    "export\s+[A-Z_]*PASSWORD[A-Z_]*\s*=\s*['\"][^'\"]{8,}"
)

SECRET_FOUND=0

for pattern in "${PATTERNS[@]}"; do
    # Search in git history (last 100 commits)
    if git log --all --oneline -100 | head -1 > /dev/null 2>&1; then
        matches=$(git grep -i -E "$pattern" $(git rev-list --all --max-count=100) -- . ':!*.md' ':!*.txt' 2>/dev/null || true)
        if [ -n "$matches" ]; then
            log_critical "Potential secret found in git history matching pattern: $pattern"
            echo "$matches" | head -5 >> "$REPORT_FILE"
            SECRET_FOUND=1
        fi
    fi
    
    # Search in current files
    matches=$(grep -r -i -E "$pattern" "$REPO_ROOT" \
        --exclude-dir=.git \
        --exclude-dir=node_modules \
        --exclude-dir=dist \
        --exclude-dir=build \
        --exclude="*.md" \
        --exclude="*.txt" \
        --exclude="*.log" \
        2>/dev/null || true)
    
    if [ -n "$matches" ]; then
        log_critical "Potential secret found in current files matching pattern: $pattern"
        echo "$matches" | head -5 >> "$REPORT_FILE"
        SECRET_FOUND=1
    fi
done

# Check for common credential files
CRED_FILES=(".env" ".env.local" ".env.production" "credentials.json" "secrets.yaml" "secrets.yml" ".npmrc" ".pypirc")
for file in "${CRED_FILES[@]}"; do
    if [ -f "$REPO_ROOT/$file" ]; then
        log_warning "Found credential file that might contain secrets: $file"
        SECRET_FOUND=1
    fi
done

if [ $SECRET_FOUND -eq 0 ]; then
    log_success "No obvious secrets detected in repository"
fi

# 2. SUSPICIOUS CI CHANGES
section_header "2. Suspicious CI/CD Changes Analysis"

log_info "Analyzing workflow files for suspicious patterns..."

SUSPICIOUS_FOUND=0

if [ -d "$REPO_ROOT/.github/workflows" ]; then
    workflow_files=$(find "$REPO_ROOT/.github/workflows" -name "*.yml" -o -name "*.yaml")
    
    for workflow in $workflow_files; do
        workflow_name=$(basename "$workflow")
        
        # Check for suspicious patterns in workflows
        
        # 1. Curl/wget to external URLs
        if grep -E "(curl|wget)\s+.*http" "$workflow" > /dev/null 2>&1; then
            suspicious_lines=$(grep -n -E "(curl|wget)\s+.*http" "$workflow")
            log_warning "External network calls found in $workflow_name:"
            echo "$suspicious_lines" >> "$REPORT_FILE"
            SUSPICIOUS_FOUND=1
        fi
        
        # 2. Base64 decode operations
        if grep -E "base64\s+-d|base64\s+--decode" "$workflow" > /dev/null 2>&1; then
            log_warning "Base64 decode operation found in $workflow_name (potential obfuscation)"
            SUSPICIOUS_FOUND=1
        fi
        
        # 3. Direct secret printing
        if grep -E "echo.*\\\$\{\{\s*secrets\." "$workflow" > /dev/null 2>&1; then
            log_critical "Potential secret exposure in $workflow_name (printing secrets)"
            SUSPICIOUS_FOUND=1
        fi
        
        # 4. Unrestricted write permissions
        if grep -E "permissions:\s*write-all" "$workflow" > /dev/null 2>&1; then
            log_warning "Overly permissive permissions in $workflow_name (write-all)"
            SUSPICIOUS_FOUND=1
        fi
        
        # 5. Pull request target with code execution
        if grep -E "pull_request_target:" "$workflow" > /dev/null 2>&1; then
            if grep -E "(npm|yarn|pip|gem)\s+(install|run)" "$workflow" > /dev/null 2>&1; then
                log_critical "Dangerous pattern: pull_request_target with code execution in $workflow_name"
                SUSPICIOUS_FOUND=1
            fi
        fi
        
        # 6. Suspicious third-party actions
        third_party_actions=$(grep -E "uses:\s*[^/]+/[^@/]+@" "$workflow" | grep -v "actions/" || true)
        if [ -n "$third_party_actions" ]; then
            log_info "Third-party actions in $workflow_name:"
            echo "$third_party_actions" >> "$REPORT_FILE"
        fi
    done
    
    # Check for recently modified workflow files
    log_info "Checking for recently modified workflows..."
    recent_changes=$(git log --since="7 days ago" --name-only --pretty=format: -- .github/workflows/ | sort -u | grep -v '^$' || true)
    if [ -n "$recent_changes" ]; then
        log_info "Workflows modified in the last 7 days:"
        echo "$recent_changes" >> "$REPORT_FILE"
    fi
    
    if [ $SUSPICIOUS_FOUND -eq 0 ]; then
        log_success "No suspicious patterns detected in CI/CD workflows"
    fi
else
    log_info "No .github/workflows directory found"
fi

# 3. DEPENDENCY ADVISORIES
section_header "3. Dependency Security Advisories"

log_info "Checking for known vulnerabilities in dependencies..."

VULN_FOUND=0

# Check for package.json (Node.js)
if [ -f "$REPO_ROOT/package.json" ]; then
    log_info "Found package.json - checking npm dependencies..."
    if command -v npm >/dev/null 2>&1; then
        if npm audit --json > /tmp/npm-audit.json 2>&1; then
            vulns=$(jq -r '.metadata.vulnerabilities | to_entries[] | select(.value > 0) | "\(.key): \(.value)"' /tmp/npm-audit.json 2>/dev/null || echo "")
            if [ -n "$vulns" ]; then
                log_warning "npm audit found vulnerabilities:"
                echo "$vulns" >> "$REPORT_FILE"
                VULN_FOUND=1
            else
                log_success "No npm vulnerabilities found"
            fi
        else
            log_info "npm audit check skipped (npm not available or no dependencies installed)"
        fi
    else
        log_info "npm not available - skipping npm audit"
    fi
fi

# Check for requirements.txt (Python)
if [ -f "$REPO_ROOT/requirements.txt" ]; then
    log_info "Found requirements.txt - checking Python dependencies..."
    if command -v pip >/dev/null 2>&1; then
        if pip list --format=json > /tmp/pip-list.json 2>&1; then
            log_info "Python packages installed - consider using 'pip-audit' or 'safety' for vulnerability scanning"
        fi
    else
        log_info "pip not available - skipping Python dependency check"
    fi
fi

# Check for Gemfile (Ruby)
if [ -f "$REPO_ROOT/Gemfile" ]; then
    log_info "Found Gemfile - Ruby project detected"
    log_info "Consider using 'bundler-audit' for vulnerability scanning"
fi

# Check for go.mod (Go)
if [ -f "$REPO_ROOT/go.mod" ]; then
    log_info "Found go.mod - Go project detected"
    log_info "Consider using 'govulncheck' for vulnerability scanning"
fi

# Check for Cargo.toml (Rust)
if [ -f "$REPO_ROOT/Cargo.toml" ]; then
    log_info "Found Cargo.toml - Rust project detected"
    log_info "Consider using 'cargo-audit' for vulnerability scanning"
fi

if [ $VULN_FOUND -eq 0 ]; then
    log_info "No dependency vulnerabilities detected (limited scanning capability)"
fi

# 4. FILE PERMISSIONS CHECK
section_header "4. File Permissions Audit"

log_info "Checking for overly permissive file permissions..."

# Find world-writable files
world_writable=$(find "$REPO_ROOT" -type f -perm -002 ! -path "*/.git/*" 2>/dev/null || true)
if [ -n "$world_writable" ]; then
    log_warning "World-writable files found:"
    echo "$world_writable" >> "$REPORT_FILE"
else
    log_success "No world-writable files found"
fi

# Check script permissions
scripts=$(find "$REPO_ROOT" -type f \( -name "*.sh" -o -name "*.bash" \) ! -path "*/.git/*" 2>/dev/null || true)
if [ -n "$scripts" ]; then
    log_info "Shell scripts found - verifying executable permissions:"
    for script in $scripts; do
        if [ ! -x "$script" ]; then
            log_info "  Non-executable: $script"
        fi
    done
fi

# 5. GIT CONFIGURATION AUDIT
section_header "5. Git Configuration Audit"

log_info "Checking Git configuration for security issues..."

# Check for unsigned commits
if git log -1 --show-signature 2>&1 | grep -q "Good signature"; then
    log_success "Latest commit is signed"
else
    log_info "Latest commit is not GPG signed (consider enabling commit signing)"
fi

# Check for .gitignore
if [ -f "$REPO_ROOT/.gitignore" ]; then
    log_success "Found .gitignore file"
    
    # Check if common secret files are ignored
    if ! grep -q -E "(\.env|secrets|credentials)" "$REPO_ROOT/.gitignore" 2>/dev/null; then
        log_warning ".gitignore should include .env, secrets, and credentials patterns"
    fi
else
    log_warning "No .gitignore file found - secrets could be accidentally committed"
fi

# SUMMARY
section_header "Audit Summary"

echo "" >> "$REPORT_FILE"
echo "Total Findings: $TOTAL_FINDINGS" >> "$REPORT_FILE"
echo "Critical Findings: $CRITICAL_FINDINGS" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ $CRITICAL_FINDINGS -gt 0 ]; then
    echo "⚠️  URGENT: $CRITICAL_FINDINGS critical security issues found!" >> "$REPORT_FILE"
    echo "ACTION REQUIRED: Review findings and rotate any exposed credentials immediately." >> "$REPORT_FILE"
    log_critical "Audit completed with $CRITICAL_FINDINGS critical findings"
elif [ $TOTAL_FINDINGS -gt 0 ]; then
    echo "⚠️  $TOTAL_FINDINGS security warnings found - review recommended." >> "$REPORT_FILE"
    log_warning "Audit completed with $TOTAL_FINDINGS warnings"
else
    echo "✅ No significant security issues detected." >> "$REPORT_FILE"
    log_success "Audit completed successfully - no issues found"
fi

echo "" >> "$REPORT_FILE"
echo "========================================" >> "$REPORT_FILE"
echo "End of Report" >> "$REPORT_FILE"
echo "========================================" >> "$REPORT_FILE"

log_info "Audit report saved to: $REPORT_FILE"

# Exit with appropriate code
if [ $CRITICAL_FINDINGS -gt 0 ]; then
    exit 1
elif [ $TOTAL_FINDINGS -gt 0 ]; then
    exit 0  # Exit 0 for warnings (don't fail CI)
else
    exit 0
fi
