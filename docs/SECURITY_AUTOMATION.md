# Project Security & Automation Summary
Repo: `brandonlacoste9-tech/adgenxai-2.0`
Default branch: `main`
Primary language: Shell

---

## What This Does
- Automated SAST Remediation: Codex (OpenAI CLI) reads `gl-sast-report.json` and proposes minimal patches for High/Critical issues.
- CI/CD Integration: Runs via GitHub Actions on PRs that touch security-relevant paths or on manual dispatch.
- Patch → PR: Validated patches are applied on a temporary branch; a remediation PR is opened for review (fork-safe).
- Shell-First QA: After patching, CI runs `make test` (if present), `bats`, `shunit2`, and `shellcheck`.
- Test Gate: By default, failures do not block merging; PR gets a label and comment. Set `STRICT_TESTS="true"` to block.
- Reviewers & Notifications: Optional auto-request CODEOWNERS and Slack notifications.
- Permissions: CI has `contents: write`, `pull-requests: write`, `issues: write` for PRs, labels, and comments.

## When It Triggers
- PR events: `opened`, `synchronize`, `reopened` on `main` (and `master` if present).
- Path filters: `gl-sast-report.json`, `.github/workflows/**`, `**/*.sh`, `scripts/**`, `src/**`.
- Manual: `workflow_dispatch`.

## How It Works (Flow)
1. Trigger: PR or manual run.
2. SAST Read: Load `gl-sast-report.json`; short-circuit if missing/empty.
3. Filter: Keep only High/Critical findings.
4. Generate Patches: Prompt Codex to output unified diffs (surgical fixes only).
5. Validate: Ensure diffs apply (`git apply -p0/-p1`).
6. Stage: Create branch `codex/fixes-${GITHUB_RUN_ID}`, commit patches.
7. PR: Open remediation PR (skips on forked PRs for safety).
8. Shell-First QA: `make test`, `bats`, `shunit2`, `shellcheck`.
9. Gate: Non-strict (default) → continue & label/comment on failure; Strict → fail job to block merge.
10. Notify: Optional Slack message with PR link.
11. Artifacts: Upload patches and raw Codex logs.

## Key Toggles (Env)
- `STRICT_TESTS`: `"true"` to block merge on failures; `"false"` default labels/comment only.
- `ENABLE_CODEOWNERS_REVIEWERS`: `"true"` to auto-request CODEOWNERS; default `"false"`.
- `TEST_LABEL_ON_FAILURE`: label when tests fail (default `tests-failed`).
- `SAST_REPORT_PATH`: default `gl-sast-report.json`.

## Reviewer & Notifications
- CODEOWNERS: When enabled, CI requests reviewers per CODEOWNERS; you can also specify users/teams in the PR step.
- Slack: Configure secret `SLACK_WEBHOOK_URL` for notifications.

## Fork Safety
- On PRs from forks, CI does not open remediation PRs, request reviewers, or write labels/comments.

## Troubleshooting & Tips
- No patches produced: Likely no High/Critical findings or diffs didn’t validate; see `artifacts/codex-diff-raw.log`.
- Patches fail to apply: Conflicts or wrong paths. Rebase the PR or adjust patch level.
- Test failures: See `test_gate` logs; PR gets `tests-failed` label and a comment with the run link.
- Missing Slack pings: Ensure `SLACK_WEBHOOK_URL` exists and is permitted.
- CODEOWNERS not applied: Set `ENABLE_CODEOWNERS_REVIEWERS="true"` and verify `CODEOWNERS` on default branch.

## Quick Start (New Teammate)
1. Open a PR changing a `.sh` file or the SAST report.
2. Check the GitHub Actions run; review `codex-remediation` job.
3. If a remediation PR appears, review diffs and CI results.
4. Toggle strict mode by setting `STRICT_TESTS` to `"true"`.
5. (Optional) Add/update `CODEOWNERS` and enable reviewer auto-request.

## Files & Locations
- Workflow: `.github/workflows/codex-remediation.yml`
- SAST report: `gl-sast-report.json`
- Artifacts: `artifacts/codex-diff-raw.log`, `codex_patches/`

## Notes
- Patches are minimal and focused; broader refactors are out of scope for the agent.
- CI permissions are least-privilege for required actions (contents/PRs/issues write).