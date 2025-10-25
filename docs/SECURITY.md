# Security Audit Guide

This document describes the automated security audit tools available in this repository.

## Overview

After a suspected security compromise, we've implemented comprehensive security auditing tools to help identify vulnerabilities, exposed secrets, suspicious code patterns, and other security issues.

## Tools

### 1. Repository Audit Script (`tools/repo-audit.sh`)

A comprehensive bash script that performs deep security analysis of the repository.

**What it checks:**
- ✅ Recent commit history for suspicious patterns
- ✅ Hardcoded secrets and credentials (API keys, tokens, passwords)
- ✅ Git history for removed secrets
- ✅ CI/CD workflow configurations for security issues
- ✅ Suspicious code execution patterns
- ✅ Dependency vulnerabilities (npm, pip, bundler, go)
- ✅ File permissions and executable scripts
- ✅ SSH keys and authentication artifacts

**Usage:**

```bash
# Run the audit locally
bash tools/repo-audit.sh

# Review the generated report
cat repo-audit-report.txt
```

**Output:**
- Console output with color-coded severity levels
- `repo-audit-report.txt` - Detailed findings and recommendations
- Exit code 1 if critical or high severity issues found

### 2. Security Audit Workflow (`.github/workflows/repo-audit.yml`)

Automated GitHub Actions workflow that runs security audits.

**Triggers:**
- Pull requests to `main` or `develop` branches
- Weekly schedule (Mondays at 2 AM UTC)
- Manual dispatch via Actions tab

**What it does:**
1. Checks out repository with full history
2. Installs required dependencies (npm, jq)
3. Runs the audit script
4. Uploads audit report as artifact (retained for 90 days)
5. Comments on PRs with findings summary
6. Fails the workflow if critical/high issues found

**Accessing Reports:**
1. Go to repository Actions tab
2. Click on "Repository Security Audit" workflow
3. Select a run
4. Download the `repo-audit-report` artifact

## Security Findings Severity Levels

- **🔴 CRITICAL**: Immediate action required (exposed private keys, active credentials)
- **🔴 HIGH**: Urgent attention needed (potential secret exposure, dangerous workflow patterns)
- **🟡 MEDIUM**: Should be reviewed (patterns suggesting past secrets, elevated privileges)
- **🟡 LOW**: Informational (third-party actions, general recommendations)

## Immediate Actions After Compromise

If the audit detects critical or high severity issues:

### 1. Rotate All Credentials
Assume all secrets in this repository are compromised:
- ✅ GitHub Personal Access Tokens
- ✅ Cloud provider keys (AWS, Azure, GCP, DigitalOcean)
- ✅ API keys (Slack, Stripe, OpenAI, etc.)
- ✅ Database credentials
- ✅ SSH keys

### 2. Revoke Access
- ✅ Review and remove unknown SSH keys: https://github.com/settings/keys
- ✅ Revoke unfamiliar OAuth applications: https://github.com/settings/applications
- ✅ Review repository collaborators and deploy keys
- ✅ Check for unknown webhooks in repository settings

### 3. Enable Security Features
- ✅ Enable/verify 2FA: https://github.com/settings/security
- ✅ Enable GitHub secret scanning alerts
- ✅ Enable Dependabot security updates
- ✅ Enable GitHub Actions approval for external contributors

### 4. Clean Repository
- ✅ Remove any hardcoded secrets found
- ✅ Use environment variables and GitHub Secrets for sensitive data
- ✅ Consider using `git-filter-repo` to clean secrets from history
- ✅ Force push cleaned branches (coordinate with team)

### 5. Monitor and Review
- ✅ Audit recent commits for unauthorized changes
- ✅ Review workflow run history for suspicious activity
- ✅ Enable security notifications
- ✅ Set up monitoring for unusual repository activity

## Manual Security Checks

The automated audit provides comprehensive coverage, but some checks require manual review:

### GitHub Account Settings
1. **SSH Keys**: https://github.com/settings/keys
   - Review all SSH keys
   - Remove any unknown or unused keys
   
2. **OAuth Applications**: https://github.com/settings/applications
   - Review authorized OAuth apps
   - Revoke any unfamiliar applications
   
3. **Two-Factor Authentication**: https://github.com/settings/security
   - Verify 2FA is enabled
   - Review recovery codes

### Repository Settings
1. **Deploy Keys**: Repository Settings → Deploy keys
   - Review all deploy keys
   - Remove unknown keys
   
2. **Webhooks**: Repository Settings → Webhooks
   - Review webhook endpoints
   - Remove suspicious webhooks
   
3. **Actions Secrets**: Repository Settings → Secrets and variables → Actions
   - Review all secrets
   - Rotate any that may be compromised

## Best Practices

### Preventing Future Issues

1. **Never commit secrets**
   - Use `.env` files (add to `.gitignore`)
   - Use GitHub Secrets for CI/CD
   - Use environment variables for runtime

2. **Scan before commit**
   - Use pre-commit hooks
   - Use tools like `git-secrets` or `detect-secrets`

3. **Regular security audits**
   - Run this audit script regularly
   - Review the weekly automated runs
   - Keep dependencies updated

4. **Least privilege principle**
   - Limit workflow permissions
   - Use read-only tokens when possible
   - Regularly review access levels

5. **Stay informed**
   - Subscribe to security advisories
   - Enable Dependabot alerts
   - Review GitHub security alerts

## Troubleshooting

### Audit script fails to run
- Ensure bash is available
- Check that git is installed and repository is initialized
- Verify you're running from repository root

### Too many false positives
- Review the patterns in the script
- Adjust sensitivity for your use case
- Add exclusions for known safe patterns

### Workflow doesn't run
- Check workflow file syntax
- Verify branch names in triggers
- Ensure Actions are enabled in repository settings

## Additional Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [Dependabot](https://docs.github.com/en/code-security/dependabot)
- [Actions Security](https://docs.github.com/en/actions/security-guides)

## Support

For questions or issues with the security audit tools:
1. Check this documentation
2. Review the audit script source code
3. Open an issue in the repository
4. Contact repository administrators

---

**Remember:** Security is an ongoing process, not a one-time check. Run audits regularly and stay vigilant!
