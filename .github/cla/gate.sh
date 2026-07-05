#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# CLA gate — translate the unprivileged check result into a check run.
#
# Runs in the privileged workflow (workflow_run trigger, write-capable
# GITHUB_TOKEN on the default branch). Reads the artifact produced by
# check.sh, creates a pass/fail check run, and posts the "please sign"
# comment if the author has not signed (deduplicated by a hidden marker).
#
# Expected env vars:
#   GH_TOKEN         — GITHUB_TOKEN (write-capable)
#   GITHUB_REPOSITORY — owner/repo (auto-set by Actions)
#   RUNNER_TEMP      — runner temp dir (auto-set by Actions)
#
# The artifact at $RUNNER_TEMP/cla-result/result.json must contain:
#   { pr_number, head_sha, author, result }
#
# The comment template lives in comment.md next to this script.
# ──────────────────────────────────────────────────────────────────────────
set -euo pipefail

RESULT_FILE="${RUNNER_TEMP}/cla-result/result.json"
PR_NUMBER=$(jq -r '.pr_number' "$RESULT_FILE")
HEAD_SHA=$(jq -r '.head_sha' "$RESULT_FILE")
AUTHOR=$(jq -r '.author' "$RESULT_FILE")
STATUS=$(jq -r '.result' "$RESULT_FILE")

echo "PR #${PR_NUMBER} — author ${AUTHOR} — ${STATUS}"

create_check() {
  local conclusion="$1" title="$2" summary="$3"
  jq -n \
    --arg head_sha "$HEAD_SHA" \
    --arg conclusion "$conclusion" \
    --arg title "$title" \
    --arg summary "$summary" \
    '{name: "CLA", head_sha: $head_sha, status: "completed",
      conclusion: $conclusion,
      output: {title: $title, summary: $summary}}' \
    | gh api "repos/${GITHUB_REPOSITORY}/check-runs" --input -
}

case "$STATUS" in
  signed-icla|signed-ccla|allowlisted)
    create_check "success" "CLA signed" \
      "${AUTHOR} has signed the CLA."
    ;;

  unsigned)
    # Dedup: check whether *we* already posted a CLA comment on this PR.
    # We match on author (github-actions[bot]) AND the hidden marker —
    # an attacker can't forge the author, so they can't suppress the
    # instructions by posting the marker themselves.
    EXISTING=$(gh api \
      "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments?per_page=100" \
      --jq '[.[] | select(.user.login == "github-actions[bot]" and (.body | contains("<!-- cla-bot -->")))] | length' \
      2>/dev/null || echo 0)

    if [ "${EXISTING:-0}" -eq 0 ]; then
      COMMENT_FILE="$(dirname "$0")/comment.md"
      jq -n \
        --rawfile body "$COMMENT_FILE" \
        '{body: $body}' \
        | gh api \
            "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
            --input -
    fi

    create_check "failure" "CLA not signed" \
      "${AUTHOR} has not signed the CLA. See the comment above for instructions."
    ;;

  *)
    echo "Unexpected status: ${STATUS}"
    create_check "neutral" "CLA check error" \
      "Could not determine CLA status. Comment recheck to retry."
    ;;
esac
