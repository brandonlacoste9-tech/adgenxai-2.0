## Purpose
How to triage flaky MCP health during CI keep-alive.

## Quick triage
1) Open the failing run → “Artifacts” → download `mcp-keep-alive-logs-*` and `mcp-keep-alive-metrics-*`.
2) Check `max_consecutive_failures` and timestamps in `metrics.json`.
3) Verify endpoint locally: `curl -v http://localhost:3057/health` (or service URL in logs).
4) Common fixes:
   - Increase `grace_period_sec` during cold starts.
   - Raise `warn_threshold` for transient networks.
   - Adjust `interval_sec`/`jitter_percent` under CI load.

## Escalation
- Owner: <team/Slack>
- Related workflows: `.github/workflows/mcp-keepalive-*`
- Action: `./.github/actions/mcp-keepalive`