#!/usr/bin/env bash
#
# Script to post security audit report comment to PR #36
# This script requires authentication via GITHUB_TOKEN or gh CLI auth
#

set -euo pipefail

REPO="brandonlacoste9-tech/adgenxai-2.0"
PR_NUMBER=36

# Security audit report comment
COMMENT_BODY="========================================
Repository Security Audit Report
Timestamp: 2025-10-04 11:32 UTC
Repository: brandonlacoste9-tech/adgenxai-2.0
========================================

=== 1. Secret Scanning ===
[PASS] No obvious secrets detected in repository

=== 2. Suspicious CI/CD Changes Analysis ===
[INFO] Third-party actions in docker-multiarch.yml:
 uses: docker/setup-qemu-action@v3
 uses: docker/setup-buildx-action@v3
[PASS] No suspicious patterns detected in CI/CD workflows

...

Total Findings: 0
Critical Findings: 0
✅ No significant security issues detected."

echo "📝 Posting security audit comment to PR #${PR_NUMBER}..."

# Try to post comment using gh CLI
if command -v gh &> /dev/null; then
    gh pr comment "$PR_NUMBER" --repo "$REPO" --body "$COMMENT_BODY"
    echo "✅ Comment posted successfully!"
else
    echo "❌ Error: gh CLI not found. Please install gh CLI or post the comment manually."
    echo ""
    echo "Comment body:"
    echo "=============================================="
    echo "$COMMENT_BODY"
    echo "=============================================="
    exit 1
fi
