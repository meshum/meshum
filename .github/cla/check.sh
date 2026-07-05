#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# CLA check — read-only evaluation of whether a PR author has signed.
#
# Runs in the unprivileged pull_request workflow (read-only GITHUB_TOKEN,
# no secrets). Reads signatures.json from the checked-out base branch and
# writes the result as a workflow artifact for the privileged CLA workflow
# to consume via workflow_run.
#
# Expected env vars:
#   PR_AUTHOR  — github.event.pull_request.user.login
#   PR_NUMBER  — github.event.pull_request.number
#   HEAD_SHA   — github.event.pull_request.head.sha
# ──────────────────────────────────────────────────────────────────────────
set -euo pipefail

# Read signatures from the checked-out base branch (trusted, never from
# the PR's merge ref).
SIGNATURES=$(cat .github/cla/signatures.json)

# Pass if the author is in any of: allowlist, ICLA keys, or referenced
# in any CCLA contributors list.
if echo "$SIGNATURES" | jq --exit-status --arg u "$PR_AUTHOR" \
    '.allowlist | index($u)' >/dev/null; then
  RESULT="allowlisted"
elif echo "$SIGNATURES" | jq --exit-status --arg u "$PR_AUTHOR" \
    '.icla | has($u)' >/dev/null; then
  RESULT="signed-icla"
elif echo "$SIGNATURES" | jq --exit-status --arg u "$PR_AUTHOR" \
    '[.ccla[]? | .contributors[]?] | any(. == $u)' >/dev/null; then
  RESULT="signed-ccla"
else
  RESULT="unsigned"
fi

echo "CLA status for ${PR_AUTHOR}: ${RESULT}"

# Persist the result for the privileged CLA workflow.
mkdir -p cla-result
jq -n \
  --argjson pr_number "$PR_NUMBER" \
  --arg head_sha "$HEAD_SHA" \
  --arg author "$PR_AUTHOR" \
  --arg result "$RESULT" \
  '{pr_number: $pr_number, head_sha: $head_sha, author: $author, result: $result}' \
  > cla-result/result.json
