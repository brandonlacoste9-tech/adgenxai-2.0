# Repository Security Audit

## Overview
The repository security audit tool (`tools/repo-audit.sh`) performs automated security scanning to detect:
- Hardcoded secrets and credentials
- Suspicious CI/CD workflow patterns
- Dependency vulnerabilities
- Insecure file permissions
- Git configuration issues

## Usage

### Running Locally
```bash
./tools/repo-audit.sh
```

The script will generate a detailed report at `repo-audit-report.txt` in the repository root.

### Automated Scans
The security audit runs automatically via GitHub Actions:
- **Daily** at 2 AM UTC
- **On pull requests** that modify workflows, tools, or scripts
- **On push to main** when workflows, tools, or scripts change
- **Manual trigger** via GitHub Actions UI

## What It Scans

### 1. Secret Scanning
Searches for common secret patterns in code and git history:
- API keys and tokens
- Passwords
- AWS credentials
- GitHub tokens
- Private keys
- Slack tokens
- Environment variable secrets

### 2. Suspicious CI/CD Patterns
Analyzes GitHub Actions workflows for:
- External network calls (curl/wget)
- Base64 decode operations (potential obfuscation)
- Direct secret printing
- Overly permissive permissions
- Dangerous `pull_request_target` usage
- Third-party actions inventory

### 3. Dependency Advisories
Checks for known vulnerabilities in:
- npm packages (Node.js)
- Python packages (pip)
- Ruby gems
- Go modules
- Rust crates

### 4. File Permissions
Identifies:
- World-writable files
- Non-executable scripts

### 5. Git Configuration
Reviews:
- Commit signing status
- .gitignore completeness

## Understanding Results

### Finding Levels
- **[CRITICAL]**: Urgent security issues requiring immediate action
- **[WARNING]**: Security concerns that should be reviewed
- **[INFO]**: Informational messages
- **[PASS]**: Security checks that passed

### Exit Codes
- `0`: No critical issues (warnings may exist)
- `1`: Critical security issues detected

## Critical Findings Response

When critical findings are detected:

1. **Immediate Actions:**
   - Review the audit report artifact in GitHub Actions
   - Identify exposed credentials
   - Rotate ALL potentially compromised credentials immediately
   - Remove secrets from git history if necessary

2. **GitHub Issue:**
   - An issue will be automatically created with label `security-audit`
   - The issue contains a summary of critical findings
   - Check the linked workflow run for the full report

3. **Remediation:**
   - Use `git filter-branch` or `BFG Repo-Cleaner` to remove secrets from history
   - Update CI/CD workflows to remove suspicious patterns
   - Add secrets to `.gitignore` and use GitHub Secrets instead
   - Consider enabling commit signing and branch protection

## Workflow Artifacts

The audit report is uploaded as a workflow artifact:
- **Name**: `repo-audit-report`
- **Retention**: 90 days
- **Location**: GitHub Actions → Workflow run → Artifacts

## Limitations

- Secret scanning uses pattern matching (not exhaustive)
- Dependency scanning requires package managers installed
- Some third-party security tools may provide deeper analysis
- Historical git commits are limited to last 100 commits

## Best Practices

1. **Never commit secrets** - use GitHub Secrets or environment variables
2. **Review third-party actions** - verify actions before use
3. **Use branch protection** - require reviews for workflow changes
4. **Enable commit signing** - verify commit authenticity
5. **Keep dependencies updated** - regularly audit and update packages
6. **Monitor audit results** - review reports and address findings promptly

## Related Documentation
- [Deployment Guide](./DEPLOYMENT.md)
- [GitHub Actions Workflows](../.github/workflows/)
- [Security Best Practices](https://docs.github.com/en/actions/security-guides)
