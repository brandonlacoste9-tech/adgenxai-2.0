#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-brandonlacoste9-tech/adgenxai-2.0}"
GH_TOKEN="${GH_TOKEN:-$(gh auth token)}"
CATEGORY="Announcements" # change if needed

echo "🔎 Checking hygiene locally..."
count=$(gh pr list --repo "$REPO" --state open --label hygiene-failed --json number | jq 'length')
timestamp=$(date -u +"%Y-%m-%d %H:%M UTC")

if [ "$count" -gt 0 ]; then
  echo '{"schemaVersion":1,"label":"hygiene","message":"❌ fail","color":"red","footer":"Last checked: '"$timestamp"'"}' > hygiene_status.json
  echo "❌ Hygiene failed: $count PR(s)."
else
  echo '{"schemaVersion":1,"label":"hygiene","message":"✅ pass","color":"brightgreen","footer":"Last checked: '"$timestamp"'"}' > hygiene_status.json
  echo "✅ Hygiene clean: no failing PRs."
fi

echo "📦 hygiene_status.json written"
cat hygiene_status.json
echo

# --- GitHub Issue management ---
if [ "$count" -gt 0 ]; then
  issue_number=$(gh issue list --repo "$REPO" --label hygiene-alert --state open --json number -q '.[0].number' || true)
  if [ -z "$issue_number" ]; then
    echo "🆕 Opening hygiene-alert issue..."
    gh issue create --repo "$REPO" \
      --title "🚨 Hygiene failed badge" \
      --body "One or more PRs are marked with \`hygiene-failed\`.

👉 [Check failing PRs](https://github.com/$REPO/pulls?q=is%3Apr+is%3Aopen+label%3Ahygiene-failed)" \
      --label hygiene-alert
  else
    echo "🔄 Commenting on existing hygiene-alert issue #$issue_number..."
    gh issue comment "$issue_number" --repo "$REPO" --body "Hygiene still failing at $timestamp."
  fi
else
  echo "✅ Closing any open hygiene-alert issues..."
  issues=$(gh issue list --repo "$REPO" --label hygiene-alert --state open --json number -q '.[].number' || true)
  for i in $issues; do
    gh issue close "$i" --repo "$REPO" --comment "✅ Hygiene passed again at $timestamp. Closing alert."
  done
fi

# --- GitHub Discussion update ---
echo "💬 Updating Hygiene Alerts discussion..."
body="One or more PRs are marked with \`hygiene-failed\`.

👉 [Check PRs](https://github.com/$REPO/pulls?q=is%3Apr+is%3Aopen+label%3Ahygiene-failed)

_Last checked: $timestamp_"

discussion_id=$(gh api graphql -f query='\n  query($owner:String!, $repo:String!) {\n    repository(owner:$owner, name:$repo) {\n      discussions(first:50, orderBy:{field:CREATED_AT, direction:DESC}) {\n        nodes { id number title }\n      }\n    }\n  }' -f owner="$(echo $REPO | cut -d/ -f1)" -f repo="$(echo $REPO | cut -d/ -f2)" --jq '.data.repository.discussions.nodes[] | select(.title=="🚨 Hygiene Alerts") | .id' || true)

if [ -n "$discussion_id" ]; then
  gh api graphql -f query='\n    mutation($id:ID!, $body:String!) {\n      updateDiscussion(input:{discussionId:$id, body:$body}) { discussion { number } }\n    }' -f id="$discussion_id" -f body="$body" >/dev/null
  echo "🔄 Updated existing Hygiene Alerts discussion."
else
  gh api graphql -f query='\n    mutation($repoId:ID!, $title:String!, $body:String!, $categoryId:ID!) {\n      createDiscussion(input:{repositoryId:$repoId, title:$title, body:$body, categoryId:$categoryId}) {\n        discussion { number }\n      }\n    }' \
    -f repoId="$(gh api graphql -f query='query($o:String!, $r:String!){repository(owner:$o, name:$r){id}}' -f o="$(echo $REPO | cut -d/ -f1)" -f r="$(echo $REPO | cut -d/ -f2)" --jq '.data.repository.id')" \
    -f title="🚨 Hygiene Alerts" \
    -f body="$body" \
    -f categoryId="$(gh api graphql -f query='query($o:String!, $r:String!, $c:String!){repository(owner:$o, name:$r){discussionCategories(first:10){nodes{ id name }}}}' -f o="$(echo $REPO | cut -d/ -f1)" -f r="$(echo $REPO | cut -d/ -f2)" -f c="$CATEGORY" --jq ".data.repository.discussionCategories.nodes[] | select(.name==\"$CATEGORY\") | .id")"
  echo "🆕 Created new Hygiene Alerts discussion."
fi

# --- Optional Slack notification ---
if [ "$count" -gt 0 ] && [ -n "
${SLACK_WEBHOOK_URL:-}" ]; then
  echo "📢 Sending Slack alert..."
  curl -X POST -H 'Content-type: application/json' --data "{\"text\": \"🚨 Hygiene Failed: $count PR(s).
👉 https://github.com/$REPO/pulls?q=is%3Apr+is%3Aopen+label%3Ahygiene-failed\"}" "$SLACK_WEBHOOK_URL"
fi

# --- Push badge JSON to hygiene-badge branch ---
echo "🚩 Pushing hygiene_status.json to hygiene-badge branch..."
git fetch origin hygiene-badge || true
if git show-ref --verify --quiet refs/heads/hygiene-badge; then
  git checkout hygiene-badge
else
  git checkout --orphan hygiene-badge
fi
git reset --hard
mv hygiene_status.json hygiene_status.json
git add hygiene_status.json
git commit -m "update hygiene status badge [local]"
git push origin hygiene-badge --force
echo "✅ hygiene_status.json pushed to origin/hygiene-badge"