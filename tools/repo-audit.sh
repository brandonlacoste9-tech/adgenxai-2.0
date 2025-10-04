#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Repository Security Audit Script
# ============================================================================
# Purpose: Comprehensive security audit for post-compromise assessment
# Outputs: repo-audit-report.txt with findings and recommendations
# ============================================================================

REPORT_FILE="repo-audit-report.txt"
COMMIT_LIMIT=50
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Color codes for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters for findings
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0

# ============================================================================
# Helper Functions
# ============================================================================

log_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    echo "" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "$1" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

log_critical() {
    CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    echo -e "${RED}[CRITICAL] $1${NC}"
    echo "[CRITICAL] $1" >> "$REPORT_FILE"
}

log_high() {
    HIGH_COUNT=$((HIGH_COUNT + 1))
    echo -e "${RED}[HIGH] $1${NC}"
    echo "[HIGH] $1" >> "$REPORT_FILE"
}

log_medium() {
    MEDIUM_COUNT=$((MEDIUM_COUNT + 1))
    echo -e "${YELLOW}[MEDIUM] $1${NC}"
    echo "[MEDIUM] $1" >> "$REPORT_FILE"
}

log_low() {
    LOW_COUNT=$((LOW_COUNT + 1))
    echo -e "${YELLOW}[LOW] $1${NC}"
    echo "[LOW] $1" >> "$REPORT_FILE"
}

log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
    echo "[INFO] $1" >> "$REPORT_FILE"
}

log_output() {
    echo "$1" | tee -a "$REPORT_FILE"
}

# ============================================================================
# Audit Functions
# ============================================================================

audit_recent_commits() {
    log_section "1. Recent Commit Analysis"
    
    log_info "Analyzing last $COMMIT_LIMIT commits for suspicious activity..."
    
    # Get recent commits
    if git log --oneline -n "$COMMIT_LIMIT" >> "$REPORT_FILE" 2>&1; then
        log_output "Recent commits logged successfully"
    else
        log_medium "Unable to access git history"
    fi
    
    # Check for suspicious commit messages
    echo "" >> "$REPORT_FILE"
    log_info "Checking for suspicious commit patterns..."
    
    suspicious_patterns=(
        "backdoor"
        "malicious"
        "exploit"
        "inject"
        "bypass"
        "override.*security"
        "disable.*auth"
        "temp.*password"
        "test.*credential"
    )
    
    for pattern in "${suspicious_patterns[@]}"; do
        if git log -i --grep="$pattern" -n "$COMMIT_LIMIT" --oneline 2>/dev/null | grep -q .; then
            log_high "Suspicious commit message pattern detected: '$pattern'"
            git log -i --grep="$pattern" -n "$COMMIT_LIMIT" --oneline >> "$REPORT_FILE" 2>&1 || true
        fi
    done
    
    # Check for unusual commit times (outside 6am-11pm local time might indicate compromise)
    log_info "Checking commit timing patterns..."
    echo "Recent commit timestamps:" >> "$REPORT_FILE"
    git log -n "$COMMIT_LIMIT" --pretty=format:"%h %ai %an" >> "$REPORT_FILE" 2>&1 || true
    echo "" >> "$REPORT_FILE"
}

audit_secrets() {
    log_section "2. Secret and Credential Detection"
    
    log_info "Scanning for hardcoded secrets and credentials..."
    
    # Common secret patterns
    secret_patterns=(
        # API Keys and Tokens
        "api[_-]?key['\"]?\s*[:=]\s*['\"][a-zA-Z0-9_-]{20,}['\"]"
        "api[_-]?secret['\"]?\s*[:=]\s*['\"][a-zA-Z0-9_-]{20,}['\"]"
        "access[_-]?token['\"]?\s*[:=]\s*['\"][a-zA-Z0-9_-]{20,}['\"]"
        "auth[_-]?token['\"]?\s*[:=]\s*['\"][a-zA-Z0-9_-]{20,}['\"]"
        "bearer['\"]?\s*[:=]\s*['\"][a-zA-Z0-9_-]{20,}['\"]"
        
        # AWS Credentials
        "AKIA[0-9A-Z]{16}"
        "aws[_-]?access[_-]?key[_-]?id"
        "aws[_-]?secret[_-]?access[_-]?key"
        
        # GitHub Tokens
        "gh[pousr]_[0-9a-zA-Z]{36}"
        "github[_-]?token"
        "github[_-]?pat"
        
        # Private Keys
        "BEGIN.*PRIVATE KEY"
        "BEGIN RSA PRIVATE KEY"
        "BEGIN OPENSSH PRIVATE KEY"
        
        # Cloud Provider Keys
        "GOOGLE[_-]?API[_-]?KEY"
        "AZURE[_-]?SECRET"
        "DIGITALOCEAN[_-]?TOKEN"
        
        # Database Credentials
        "mysql://.*:.*@"
        "postgres://.*:.*@"
        "mongodb://.*:.*@"
        "redis://.*:.*@"
        
        # Generic Passwords
        "password['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
        "passwd['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
        "pwd['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
        
        # JWT Tokens
        "eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*"
        
        # Slack Tokens
        "xox[baprs]-[0-9a-zA-Z-]+"
        
        # Stripe Keys
        "sk_live_[0-9a-zA-Z]{24,}"
        "pk_live_[0-9a-zA-Z]{24,}"
    )
    
    found_secrets=false
    
    # Search in current files
    for pattern in "${secret_patterns[@]}"; do
        results=$(git grep -iE "$pattern" -- ':!*.md' ':!*.txt' ':!*.log' ':!tools/repo-audit.sh' 2>/dev/null || true)
        if [ -n "$results" ]; then
            found_secrets=true
            log_critical "Potential secret pattern detected: ${pattern:0:50}..."
            echo "$results" | head -5 >> "$REPORT_FILE"
            echo "..." >> "$REPORT_FILE"
        fi
    done
    
    # Search in git history for removed secrets
    log_info "Scanning git history for exposed secrets..."
    
    history_patterns=(
        "password"
        "api_key"
        "secret"
        "token"
        "private_key"
        "credential"
    )
    
    for pattern in "${history_patterns[@]}"; do
        if git log -S"$pattern" --all --oneline 2>/dev/null | head -10 | grep -q . 2>/dev/null; then
            log_medium "Pattern '$pattern' found in git history - may indicate removed secrets"
            git log -S"$pattern" --all --oneline 2>/dev/null | head -5 >> "$REPORT_FILE" 2>&1 || true
        fi
    done
    
    if [ "$found_secrets" = false ]; then
        log_info "No obvious hardcoded secrets detected in current files"
    fi
}

audit_workflows() {
    log_section "3. CI/CD Workflow Security Audit"
    
    log_info "Inspecting GitHub Actions workflows..."
    
    if [ ! -d ".github/workflows" ]; then
        log_info "No .github/workflows directory found"
        return
    fi
    
    # List all workflows
    log_output "Found workflows:"
    ls -la .github/workflows/*.yml 2>/dev/null | tee -a "$REPORT_FILE" || true
    echo "" >> "$REPORT_FILE"
    
    # Check for suspicious patterns in workflows
    workflow_files=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null || true)
    
    if [ -z "$workflow_files" ]; then
        log_info "No workflow files found"
        return
    fi
    
    for workflow in $workflow_files; do
        log_info "Auditing: $workflow"
        echo "--- $workflow ---" >> "$REPORT_FILE"
        
        # Check for secrets exposure (but skip audit workflow itself)
        if echo "$workflow" | grep -q "repo-audit.yml"; then
            # Skip checking the audit workflow itself
            :
        elif grep -iE "(echo.*\\\$.*SECRET|print.*\\\$.*SECRET|cat.*\\\$.*SECRET)" "$workflow" 2>/dev/null | grep -q .; then
            log_high "Workflow may be exposing secrets: $workflow"
        fi
        
        # Check for curl/wget with tokens in URLs
        if grep -E "(curl|wget).*http.*token=|http.*key=" "$workflow" 2>/dev/null; then
            log_high "Workflow may have credentials in URLs: $workflow"
        fi
        
        # Check for privilege escalation
        if grep -iE "(sudo|chmod 777|chown.*root)" "$workflow" 2>/dev/null; then
            log_medium "Workflow uses elevated privileges: $workflow"
        fi
        
        # Check for external script execution
        if grep -E "(curl.*\|.*bash|wget.*\|.*sh)" "$workflow" 2>/dev/null; then
            log_critical "Workflow pipes remote content to shell: $workflow"
        fi
        
        # Check for write permissions
        if grep -E "permissions:.*write" "$workflow" 2>/dev/null; then
            log_medium "Workflow has write permissions enabled"
            grep -A5 "permissions:" "$workflow" >> "$REPORT_FILE" 2>&1 || true
        fi
        
        # Check for pull_request_target (dangerous if not careful)
        if grep "pull_request_target" "$workflow" 2>/dev/null; then
            log_medium "Workflow uses pull_request_target - verify it's safe"
        fi
        
        # Check for third-party actions
        third_party_actions=$(grep -E "uses:.*@" "$workflow" 2>/dev/null | grep -v "actions/" || true)
        if [ -n "$third_party_actions" ]; then
            log_low "Third-party actions found:"
            echo "$third_party_actions" >> "$REPORT_FILE"
        fi
        
        echo "" >> "$REPORT_FILE"
    done
}

audit_suspicious_code() {
    log_section "4. Suspicious Code Pattern Detection"
    
    log_info "Scanning for suspicious code execution patterns..."
    
    suspicious_code_patterns=(
        # Command execution
        "eval\s*\("
        "exec\s*\("
        "system\s*\("
        "shell_exec"
        "proc_open"
        "popen"
        
        # Network connections
        "curl.*-X POST.*password"
        "wget.*password"
        "http.*://.*:.*@"
        
        # Obfuscation
        "base64_decode"
        "rot13"
        "str_rot13"
        "gzinflate"
        "eval.*base64"
        
        # Dangerous file operations
        "file_get_contents.*http"
        "fopen.*http"
        "readfile.*http"
        
        # Bitcoin/Crypto wallets
        "bitcoin"
        "ethereum"
        "wallet"
        "private.*key.*crypto"
    )
    
    for pattern in "${suspicious_code_patterns[@]}"; do
        results=$(git grep -iE "$pattern" -- ':!*.md' ':!*.txt' ':!*.log' ':!tools/repo-audit.sh' 2>/dev/null || true)
        if [ -n "$results" ]; then
            log_medium "Suspicious code pattern: ${pattern:0:40}..."
            echo "$results" | head -3 >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    done
}

audit_dependencies() {
    log_section "5. Dependency Vulnerability Scan"
    
    # Check for package.json (Node.js)
    if [ -f "package.json" ]; then
        log_info "Found package.json - running npm audit..."
        
        if command -v npm &> /dev/null; then
            # Run npm audit
            npm audit --json > npm-audit.json 2>&1 || true
            
            if [ -f "npm-audit.json" ]; then
                # Parse audit results
                critical=$(jq -r '.metadata.vulnerabilities.critical // 0' npm-audit.json 2>/dev/null || echo "0")
                high=$(jq -r '.metadata.vulnerabilities.high // 0' npm-audit.json 2>/dev/null || echo "0")
                moderate=$(jq -r '.metadata.vulnerabilities.moderate // 0' npm-audit.json 2>/dev/null || echo "0")
                
                if [ "$critical" -gt 0 ]; then
                    log_critical "npm audit found $critical critical vulnerabilities"
                fi
                if [ "$high" -gt 0 ]; then
                    log_high "npm audit found $high high vulnerabilities"
                fi
                if [ "$moderate" -gt 0 ]; then
                    log_medium "npm audit found $moderate moderate vulnerabilities"
                fi
                
                # Include summary in report
                npm audit 2>&1 | head -50 >> "$REPORT_FILE" || true
                
                rm -f npm-audit.json
            fi
        else
            log_info "npm not installed, skipping npm audit"
        fi
    fi
    
    # Check for requirements.txt (Python)
    if [ -f "requirements.txt" ]; then
        log_info "Found requirements.txt"
        
        if command -v pip &> /dev/null; then
            log_info "Checking for known vulnerable packages..."
            # safety would be better but might not be installed
            cat requirements.txt >> "$REPORT_FILE"
        else
            log_info "pip not installed, skipping Python dependency check"
        fi
    fi
    
    # Check for Gemfile (Ruby)
    if [ -f "Gemfile" ]; then
        log_info "Found Gemfile"
        if command -v bundle &> /dev/null; then
            bundle audit check --update 2>&1 | head -30 >> "$REPORT_FILE" || true
        fi
    fi
    
    # Check for go.mod (Go)
    if [ -f "go.mod" ]; then
        log_info "Found go.mod"
        if command -v go &> /dev/null; then
            go list -m all >> "$REPORT_FILE" 2>&1 || true
        fi
    fi
}

audit_file_permissions() {
    log_section "6. File Permission Audit"
    
    log_info "Checking for overly permissive files..."
    
    # Check for world-writable files
    world_writable=$(find . -type f -perm -002 ! -path "./.git/*" 2>/dev/null || true)
    if [ -n "$world_writable" ]; then
        log_medium "World-writable files found:"
        echo "$world_writable" | head -20 >> "$REPORT_FILE"
    fi
    
    # Check for executable scripts
    log_info "Listing executable scripts:"
    find . -type f -executable ! -path "./.git/*" 2>/dev/null | head -20 >> "$REPORT_FILE" || true
}

audit_ssh_keys() {
    log_section "7. SSH Key and Authentication Audit"
    
    log_info "Checking for SSH keys in repository..."
    
    # Look for SSH keys
    ssh_key_patterns=(
        "id_rsa"
        "id_dsa"
        "id_ecdsa"
        "id_ed25519"
        "*.pem"
        "*.key"
    )
    
    for pattern in "${ssh_key_patterns[@]}"; do
        results=$(find . -name "$pattern" ! -path "./.git/*" 2>/dev/null || true)
        if [ -n "$results" ]; then
            log_critical "SSH key file pattern found: $pattern"
            echo "$results" >> "$REPORT_FILE"
        fi
    done
    
    # Check for authorized_keys
    if find . -name "authorized_keys" ! -path "./.git/*" 2>/dev/null | grep -q .; then
        log_critical "authorized_keys file found in repository!"
    fi
    
    log_output ""
    log_output "IMPORTANT: Manual checks required:"
    log_output "1. Review GitHub SSH keys: https://github.com/settings/keys"
    log_output "2. Review authorized OAuth Apps: https://github.com/settings/applications"
    log_output "3. Check for unknown deploy keys in repo settings"
    log_output "4. Verify 2FA is enabled: https://github.com/settings/security"
}

generate_summary() {
    log_section "8. Audit Summary and Recommendations"
    
    log_output "Audit completed at: $(date -u +"%Y-%m-%d %H:%M UTC")"
    log_output ""
    log_output "FINDINGS SUMMARY:"
    log_output "================="
    log_output "Critical: $CRITICAL_COUNT"
    log_output "High:     $HIGH_COUNT"
    log_output "Medium:   $MEDIUM_COUNT"
    log_output "Low:      $LOW_COUNT"
    log_output ""
    
    if [ $CRITICAL_COUNT -gt 0 ] || [ $HIGH_COUNT -gt 0 ]; then
        echo -e "${RED}"
        log_output "⚠️  URGENT ACTION REQUIRED ⚠️"
        log_output ""
        log_output "IMMEDIATE REMEDIATION STEPS:"
        log_output "1. ROTATE ALL CREDENTIALS - Assume all secrets in this repo are compromised"
        log_output "   - GitHub Personal Access Tokens"
        log_output "   - Cloud provider keys (AWS, Azure, GCP, DO)"
        log_output "   - API keys (Slack, Stripe, OpenAI, etc.)"
        log_output "   - Database credentials"
        log_output "   - SSH keys"
        log_output ""
        log_output "2. REVOKE ACCESS"
        log_output "   - Remove unknown SSH keys from GitHub"
        log_output "   - Revoke unfamiliar OAuth applications"
        log_output "   - Review and remove unknown collaborators"
        log_output ""
        log_output "3. ENABLE SECURITY FEATURES"
        log_output "   - Enable/verify 2FA on all accounts"
        log_output "   - Enable GitHub secret scanning alerts"
        log_output "   - Enable Dependabot security updates"
        log_output ""
        log_output "4. CLEAN REPOSITORY"
        log_output "   - Remove any hardcoded secrets found"
        log_output "   - Use environment variables and GitHub Secrets"
        log_output "   - Consider using tools like git-filter-repo to clean history"
        log_output ""
        log_output "5. REVIEW AND MONITOR"
        log_output "   - Audit all recent commits and changes"
        log_output "   - Review workflow run history for suspicious activity"
        log_output "   - Enable GitHub Actions approval for external contributors"
        log_output "   - Monitor for unusual activity"
        echo -e "${NC}"
    else
        log_info "No critical or high severity issues detected"
        log_output ""
        log_output "RECOMMENDED SECURITY IMPROVEMENTS:"
        log_output "1. Enable GitHub secret scanning"
        log_output "2. Enable Dependabot security updates"
        log_output "3. Regularly rotate credentials"
        log_output "4. Use GitHub Secrets for sensitive data"
        log_output "5. Review workflow permissions regularly"
    fi
    
    log_output ""
    log_output "Full report saved to: $REPORT_FILE"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Initialize report file
    > "$REPORT_FILE"
    
    echo "============================================================================" | tee -a "$REPORT_FILE"
    echo "        REPOSITORY SECURITY AUDIT REPORT" | tee -a "$REPORT_FILE"
    echo "============================================================================" | tee -a "$REPORT_FILE"
    echo "Repository: $(git remote get-url origin 2>/dev/null || echo 'Unknown')" | tee -a "$REPORT_FILE"
    echo "Branch: $(git branch --show-current 2>/dev/null || echo 'Unknown')" | tee -a "$REPORT_FILE"
    echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'Unknown')" | tee -a "$REPORT_FILE"
    echo "Scan time: $(date -u +"%Y-%m-%d %H:%M UTC")" | tee -a "$REPORT_FILE"
    echo "============================================================================" | tee -a "$REPORT_FILE"
    
    # Run all audit functions
    audit_recent_commits
    audit_secrets
    audit_workflows
    audit_suspicious_code
    audit_dependencies
    audit_file_permissions
    audit_ssh_keys
    generate_summary
    
    echo ""
    echo -e "${GREEN}✅ Audit complete!${NC}"
    echo -e "${BLUE}Report saved to: $REPORT_FILE${NC}"
    echo ""
    
    # Exit with error code if critical/high findings
    if [ $CRITICAL_COUNT -gt 0 ] || [ $HIGH_COUNT -gt 0 ]; then
        exit 1
    fi
}

# Run main function
main "$@"
