# Security Audit Tools

This directory contains security auditing tools for the repository.

## repo-audit.sh

Comprehensive security audit script that scans for:
- Suspicious commit patterns
- Hardcoded secrets and credentials
- Workflow security issues
- Suspicious code patterns
- Dependency vulnerabilities
- File permission issues
- SSH keys in repository

### Quick Start

```bash
# Run the audit
bash tools/repo-audit.sh

# Review the report
cat repo-audit-report.txt
```

### What it detects

**Secrets & Credentials:**
- API keys (AWS, GitHub, Google, Azure, etc.)
- Access tokens and bearer tokens
- Private SSH keys
- Database connection strings
- JWT tokens
- Service-specific keys (Slack, Stripe, etc.)

**Workflow Issues:**
- Secrets exposed in logs
- Credentials in URLs
- Elevated privileges (sudo, chmod 777)
- Remote script execution via curl/wget
- Unsafe pull_request_target usage
- Suspicious third-party actions

**Code Patterns:**
- Dangerous eval() usage
- System command execution
- Network connections with credentials
- Code obfuscation patterns
- Unsafe file operations

**Dependencies:**
- npm audit for Node.js projects
- Vulnerability checks for Python, Ruby, Go

### Output

The script generates:
1. **Console output** - Real-time progress with color-coded findings
2. **repo-audit-report.txt** - Detailed report with all findings

### Severity Levels

- **CRITICAL** - Immediate action required (private keys, active credentials)
- **HIGH** - Urgent attention (secret patterns, dangerous workflows)
- **MEDIUM** - Should review (historical patterns, privilege usage)
- **LOW** - Informational (third-party actions, recommendations)

### Exit Codes

- `0` - Success (no critical/high issues)
- `1` - Issues found (critical or high severity)

### Integration

The script is automatically run by the GitHub Actions workflow:
- `.github/workflows/repo-audit.yml`

See `docs/SECURITY.md` for complete documentation.

## Adding New Checks

To add new security patterns:

1. Edit `repo-audit.sh`
2. Add patterns to the appropriate array (e.g., `secret_patterns`, `suspicious_code_patterns`)
3. Test locally before committing
4. Update this README with new detections

## Requirements

- Bash 4.0+
- Git
- jq (for npm audit parsing)
- npm (optional, for dependency scanning)
