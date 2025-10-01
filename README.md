[![CI Artifact Sentinel](https://example.com/ci-artifact-sentinel-badge.svg)](https://example.com/ci-artifact-sentinel) [![Launch Logkeeper](https://github.com/brandonlacoste9-tech/adgenxai-2.0/actions/workflows/launch-logkeeper.yml/badge.svg)](https://github.com/brandonlacoste9-tech/adgenxai-2.0/actions/workflows/launch-logkeeper.yml)

## Maintenance (Unified)

This repository uses a unified maintenance workflow to automate routine tasks and ensure repository health.

### Automated Maintenance Tasks

The `.github/workflows/maintenance.yml` workflow runs automatically and performs the following tasks:

- **Hygiene Checks**: Monitors open pull requests for hygiene failures and maintains status badges
- **Badge Updates**: Ensures all README badges reflect current status
- **Artifact Cleanup**: Removes old workflow artifacts to manage storage
- **Issue Management**: Automatically creates or updates hygiene alert issues when problems are detected

### Workflow Schedule

- **Daily**: Automated maintenance runs at 00:00 UTC
- **On-Demand**: Can be triggered manually via the Actions tab
- **On Changes**: Runs automatically when maintenance scripts or workflow are updated

### Manual Execution

To run maintenance tasks manually:

```bash
# Run hygiene check locally
./scripts/update_hygiene.sh
```

Or trigger the workflow from the GitHub Actions tab.

### Monitoring

Check the status of maintenance tasks:
- View workflow runs in the [Actions tab](https://github.com/brandonlacoste9-tech/adgenxai-2.0/actions/workflows/maintenance.yml)
- Review hygiene status via the badge at the top of this README
- Check for open [hygiene-alert issues](https://github.com/brandonlacoste9-tech/adgenxai-2.0/issues?q=is%3Aissue+is%3Aopen+label%3Ahygiene-alert)