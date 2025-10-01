# Codex Remediation Workflow Guide

This guide provides teammates with a comprehensive overview of the Codex remediation workflow, including QA gates, feature toggles, and troubleshooting procedures.

## Table of Contents

1. [Overview](#overview)
2. [Workflow Steps](#workflow-steps)
3. [QA Gates](#qa-gates)
4. [Feature Toggles](#feature-toggles)
5. [Troubleshooting](#troubleshooting)
6. [Best Practices](#best-practices)

---

## Overview

The Codex remediation workflow is designed to ensure code quality, security, and reliability through automated checks and manual review processes. This workflow integrates with GitHub Actions and provides multiple quality gates before code reaches production.

### Key Components

- **Codex AI Assistant**: Automated code analysis and suggestion generation
- **PR Hygiene Checks**: Automated validation of pull request quality
- **QA Gates**: Multiple checkpoints for code review and validation
- **Feature Toggles**: Runtime configuration for gradual rollouts
- **Continuous Integration**: Automated testing and validation

---

## Workflow Steps

### 1. Initial Code Submission

1. **Create a Pull Request**
   - Branch from `main` with a descriptive name (e.g., `feature/user-auth`)
   - Ensure PR title follows convention: `[TYPE] Brief description`
   - Add appropriate labels (e.g., `feature`, `bug`, `hotfix`)

2. **Automated Checks Trigger**
   - CI/CD pipeline starts automatically
   - Codex analysis begins on code changes
   - Hygiene checks run (see `scripts/update_hygiene.sh`)

### 2. Codex Analysis

Codex automatically analyzes your code for:
- Code quality issues
- Security vulnerabilities
- Performance concerns
- Best practice violations
- Documentation gaps

**Timeline**: Usually completes within 2-5 minutes

### 3. Remediation Process

If Codex identifies issues:

1. **Review Suggestions**
   - Check the Codex comments on your PR
   - Evaluate each suggestion's validity
   - Prioritize security and critical issues

2. **Apply Fixes**
   - Address issues in order of severity
   - Commit changes with clear messages
   - Reference issue numbers in commit messages

3. **Re-trigger Analysis**
   - Push commits to trigger re-analysis
   - Wait for updated Codex feedback
   - Iterate until checks pass

### 4. Manual Review

After automated checks pass:
- Request review from code owners
- Address review comments
- Obtain required approvals (see QA Gates)

### 5. Merge and Deploy

- Ensure all checks are green
- Merge using appropriate strategy (squash/rebase)
- Monitor deployment pipeline
- Verify feature toggles (if applicable)

---

## QA Gates

The workflow enforces multiple quality gates to ensure code quality:

### Gate 1: Automated Checks ✅

**Requirements:**
- All CI tests pass
- Hygiene checks pass (no `hygiene-failed` label)
- Code coverage meets minimum threshold
- No security vulnerabilities detected

**Check Status:**
```bash
# View PR hygiene status
gh pr list --label hygiene-failed --state open
```

**Bypass:** Not recommended; requires admin approval

### Gate 2: Codex Analysis ✅

**Requirements:**
- No critical issues reported
- High/medium severity issues addressed or documented
- Code quality score meets threshold

**Review Process:**
1. Check Codex comments on PR
2. Address or acknowledge each issue
3. Document rationale for any unaddressed items

**Bypass:** Requires justification and tech lead approval

### Gate 3: Peer Review ✅

**Requirements:**
- Minimum 1 approving review (configurable in `.github/protection.json`)
- No unresolved review comments
- Code owner approval (if required)

**Review Checklist:**
- [ ] Code follows project conventions
- [ ] Changes are well-tested
- [ ] Documentation is updated
- [ ] No breaking changes (or properly documented)
- [ ] Security considerations addressed

**Bypass:** Not available; enforced by branch protection

### Gate 4: Integration Tests ✅

**Requirements:**
- All integration tests pass
- Performance benchmarks met
- No regression in existing functionality

**Monitoring:**
```bash
# Check workflow status
gh run list --workflow=CI --limit=5
```

**Bypass:** Only for hotfixes with post-deployment validation plan

---

## Feature Toggles

Feature toggles allow gradual rollout and easy rollback of new features.

### Toggle Configuration

**Location:** Feature flags are managed through configuration files or environment variables.

**Types of Toggles:**

1. **Release Toggles** (Temporary)
   - Used for gradual feature rollout
   - Should be removed after full deployment
   - Example: `ENABLE_NEW_AUTH_FLOW=true`

2. **Ops Toggles** (Long-lived)
   - Control operational aspects
   - Example: `ENABLE_DEBUG_LOGGING=false`

3. **Experiment Toggles** (Temporary)
   - For A/B testing
   - Example: `EXPERIMENT_NEW_UI_VARIANT=A`

4. **Permission Toggles** (Long-lived)
   - Control feature access
   - Example: `ENABLE_ADMIN_PANEL=true`

### Using Toggles in Code

**JavaScript/TypeScript Example:**
```javascript
// Check if feature is enabled
if (featureFlags.isEnabled('NEW_FEATURE')) {
  // New feature code
} else {
  // Legacy code path
}
```

**Python Example:**
```python
# Check if feature is enabled
if feature_flags.is_enabled('NEW_FEATURE'):
    # New feature code
else:
    # Legacy code path
```

### Toggle Management

**Adding a New Toggle:**
1. Define in configuration file
2. Document purpose and expiration date
3. Update relevant documentation
4. Set default value (usually `false`)

**Enabling/Disabling:**
```bash
# Via environment variable (deployment-specific)
export ENABLE_NEW_FEATURE=true

# Via configuration file (committed)
# config/features.json
{
  "ENABLE_NEW_FEATURE": true
}
```

**Removing Obsolete Toggles:**
1. Ensure toggle is fully rolled out/rolled back
2. Remove toggle checks from code
3. Update configuration files
4. Document removal in changelog

### Toggle Best Practices

- ✅ Keep toggle names descriptive and prefixed (e.g., `ENABLE_`, `EXPERIMENT_`)
- ✅ Document expected lifespan for each toggle
- ✅ Review and clean up toggles regularly (monthly)
- ✅ Use toggle management tools for complex scenarios
- ❌ Don't nest toggles deeply (max 2 levels)
- ❌ Don't use toggles for permanent configuration
- ❌ Don't forget to remove temporary toggles

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Hygiene Check Failing

**Symptoms:**
- PR labeled with `hygiene-failed`
- CI pipeline shows hygiene check failure
- Badge shows ❌

**Diagnosis:**
```bash
# Check failing PRs
gh pr list --label hygiene-failed --state open

# View specific PR details
gh pr view <PR_NUMBER>
```

**Solutions:**
1. **Review PR comments** for specific hygiene violations
2. **Address code style issues**: Run linter and formatter
   ```bash
   npm run lint -- --fix  # or equivalent for your project
   ```
3. **Update documentation** if required
4. **Rebase on main** if behind
   ```bash
   git fetch origin main
   git rebase origin/main
   ```
5. **Push changes** to re-trigger checks

**Prevention:**
- Run hygiene checks locally before pushing
- Use pre-commit hooks
- Keep PRs small and focused

---

#### Issue 2: Codex Analysis Not Running

**Symptoms:**
- No Codex comments on PR
- Analysis status shows "pending" indefinitely
- Timeout errors in CI logs

**Diagnosis:**
```bash
# Check workflow runs
gh run list --workflow=CI

# View specific run logs
gh run view <RUN_ID> --log
```

**Solutions:**
1. **Verify Codex integration**:
   - Check GitHub Actions secrets are configured
   - Ensure Codex API quota is available
   
2. **Re-trigger analysis**:
   ```bash
   # Close and reopen PR (triggers fresh analysis)
   gh pr close <PR_NUMBER>
   gh pr reopen <PR_NUMBER>
   
   # Or push empty commit
   git commit --allow-empty -m "Re-trigger CI"
   git push
   ```

3. **Check service status**:
   - Visit GitHub Status page
   - Check Codex API status dashboard

**Prevention:**
- Monitor quota usage regularly
- Set up alerts for API failures
- Have fallback review process

---

#### Issue 3: Feature Toggle Not Working

**Symptoms:**
- Feature not enabling despite toggle set to `true`
- Unexpected behavior in production
- Toggle changes not taking effect

**Diagnosis:**
```bash
# Check environment variables
env | grep ENABLE_

# View current configuration
cat config/features.json

# Check application logs
tail -f logs/application.log | grep -i feature
```

**Solutions:**
1. **Verify toggle configuration**:
   - Check spelling and case sensitivity
   - Ensure toggle is defined in configuration
   - Verify environment variable propagation

2. **Clear caches**:
   ```bash
   # Clear application cache
   redis-cli FLUSHALL  # or equivalent
   
   # Restart application
   systemctl restart application
   ```

3. **Check toggle evaluation**:
   - Add debug logging around toggle checks
   - Verify toggle value in runtime
   - Check for middleware or proxy caching

4. **Rollback if necessary**:
   ```bash
   # Disable toggle immediately
   export ENABLE_NEW_FEATURE=false
   # or update configuration file and redeploy
   ```

**Prevention:**
- Test toggles in staging before production
- Use toggle management dashboard
- Document toggle dependencies
- Set up monitoring for toggle changes

---

#### Issue 4: Merge Conflicts

**Symptoms:**
- PR shows merge conflicts
- Unable to merge automatically
- Git reports conflicting files

**Diagnosis:**
```bash
# View conflicting files
gh pr view <PR_NUMBER> --json files
```

**Solutions:**
1. **Resolve conflicts locally**:
   ```bash
   git fetch origin main
   git merge origin/main
   # or
   git rebase origin/main
   
   # Resolve conflicts in editor
   # Mark as resolved
   git add <resolved-files>
   git commit  # or git rebase --continue
   git push --force-with-lease
   ```

2. **Use GitHub conflict editor** (for simple conflicts):
   - Navigate to PR page
   - Click "Resolve conflicts"
   - Edit files in web editor
   - Mark as resolved and commit

**Prevention:**
- Rebase frequently on main
- Keep PRs small and short-lived
- Communicate with team about major changes

---

#### Issue 5: CI Tests Failing

**Symptoms:**
- Red X on PR checks
- Test failures in CI logs
- Build errors

**Diagnosis:**
```bash
# View failed jobs
gh run view <RUN_ID> --log-failed

# List recent runs
gh run list --workflow=CI --limit=10
```

**Solutions:**
1. **Run tests locally**:
   ```bash
   npm test  # or equivalent
   # or
   python -m pytest
   ```

2. **Check for environment issues**:
   - Verify dependencies are installed
   - Check environment variables
   - Ensure database/services are running

3. **Review test logs**:
   - Identify failing test
   - Check error messages
   - Verify test assumptions

4. **Fix and re-run**:
   ```bash
   # Fix code
   git add .
   git commit -m "Fix failing tests"
   git push
   ```

**Prevention:**
- Run tests before pushing
- Use CI locally (e.g., `act` for GitHub Actions)
- Write reliable, deterministic tests

---

#### Issue 6: Approval Delays

**Symptoms:**
- PR ready but no reviews
- Reviewers not responding
- Blocking other work

**Solutions:**
1. **Ping reviewers**:
   - @ mention in PR comments
   - Reach out in team chat
   - Escalate to team lead if urgent

2. **Request different reviewer**:
   ```bash
   # Request review from specific person
   gh pr review --request @username
   ```

3. **Provide context**:
   - Add PR description with background
   - Link to related issues
   - Highlight areas needing attention
   - Add demo/screenshots if relevant

4. **Check reviewer availability**:
   - Verify reviewer is not OOO
   - Consider time zones
   - Check their current workload

**Prevention:**
- Set expectations for review SLAs
- Rotate reviewers fairly
- Keep PRs small for faster review
- Provide good PR descriptions

---

### Getting Help

#### Internal Resources

- **Documentation**: Check `/docs` directory for guides
- **Team Wiki**: Project-specific procedures
- **Code Owners**: Reach out to designated owners for specific areas

#### Escalation Path

1. **Level 1**: Team members (Slack channel)
2. **Level 2**: Team lead or senior engineer
3. **Level 3**: Engineering manager
4. **Level 4**: On-call engineer (for production issues)

#### Useful Commands

```bash
# View PR status
gh pr status

# List open PRs
gh pr list --state open

# View workflow runs
gh run list

# View specific workflow run
gh run view <RUN_ID>

# Download workflow logs
gh run view <RUN_ID> --log > workflow.log

# Check hygiene status
./scripts/update_hygiene.sh
```

---

## Best Practices

### Code Quality

1. **Write Clean Code**
   - Follow project style guide
   - Use meaningful variable/function names
   - Keep functions small and focused
   - Add comments for complex logic

2. **Test Thoroughly**
   - Write unit tests for new code
   - Update tests for modified code
   - Aim for high coverage (>80%)
   - Include edge cases

3. **Document Changes**
   - Update README if needed
   - Add inline documentation
   - Update API docs
   - Document breaking changes

### PR Management

1. **Keep PRs Small**
   - Aim for <400 lines changed
   - Single responsibility principle
   - Easier to review and merge
   - Faster iteration

2. **Write Good PR Descriptions**
   - Explain the "why" not just "what"
   - Include context and background
   - Add screenshots/demos
   - Link related issues

3. **Respond to Feedback Quickly**
   - Check PRs daily
   - Respond to comments promptly
   - Ask questions if unclear
   - Resolve conversations when done

### Workflow Efficiency

1. **Automate What You Can**
   - Use pre-commit hooks
   - Run tests locally
   - Automate formatting
   - Use CI/CD templates

2. **Communicate Proactively**
   - Notify team of breaking changes
   - Update status regularly
   - Flag blockers early
   - Share knowledge

3. **Learn from Issues**
   - Document recurring problems
   - Update runbooks
   - Share solutions with team
   - Improve processes

### Security

1. **Never Commit Secrets**
   - Use environment variables
   - Use secret management tools
   - Check with `git-secrets` or similar
   - Rotate if accidentally committed

2. **Review Security Suggestions**
   - Take Codex security warnings seriously
   - Update dependencies regularly
   - Follow least privilege principle
   - Validate input, sanitize output

3. **Test Security Changes**
   - Verify authentication works
   - Test authorization boundaries
   - Check for injection vulnerabilities
   - Validate cryptographic operations

---

## Additional Resources

### Tools

- **GitHub CLI**: `gh` command for PR/issue management
- **Git Hooks**: Pre-commit, pre-push hooks for quality checks
- **Linters**: Project-specific code linters
- **Formatters**: Automated code formatting tools

### Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Git Best Practices](https://git-scm.com/book/en/v2)
- Project-specific README and wiki

### Support

- Team Slack channel: #engineering
- Engineering wiki: [Link to wiki]
- On-call rotation: [Link to schedule]

---

## Changelog

### v1.0.0 (Initial Release)
- Initial guide creation
- Covered workflow steps, QA gates, toggles, and troubleshooting
- Added best practices section

---

**Last Updated**: 2024
**Maintained By**: Engineering Team
**Questions?** Reach out in #engineering Slack channel
