#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# CLA sign — process the contributor's sign or recheck comment.
#
# Runs in the privileged workflow (issue_comment trigger, write-capable
# GITHUB_TOKEN on the default branch). When a contributor comments the
# exact magic phrase, appends their signature to signatures.json and flips
# the check to green. "recheck" re-evaluates without signing.
#
# Expected env vars:
#   GH_TOKEN         — GITHUB_TOKEN (write-capable)
#   GITHUB_REPOSITORY — owner/repo (auto-set by Actions)
#   COMMENT_BODY     — github.event.comment.body
#   COMMENTER        — github.event.comment.user.login
#   COMMENT_ID       — github.event.comment.id
#   PR_AUTHOR        — github.event.issue.user.login
#   PR_NUMBER        — github.event.issue.number
#
# Security: the comment body is the only untrusted input. It is trimmed
# and compared with == only — never interpolated into scripts. All context
# values arrive via env vars per GitHub's script-injection guidance.
# ──────────────────────────────────────────────────────────────────────────
set -euo pipefail

# Trim leading/trailing whitespace so exact matching is robust against
# copy-paste artifacts.
BODY="${COMMENT_BODY#"${COMMENT_BODY%%[![:space:]]*}"}"
BODY="${BODY%"${BODY##*[![:space:]]}"}"

MAGIC_PHRASE="I have read the CLA Document and I hereby sign the CLA"

# Resolve the PR's head SHA (needed for check runs).
HEAD_SHA=$(gh api \
  "repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}" \
  --jq '.head.sha')

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

# ── ICLA sign ─────────────────────────────────────────────────────────────
if [ "$BODY" = "$MAGIC_PHRASE" ]; then
  # Only the PR author may sign for themselves.
  if [ "$COMMENTER" != "$PR_AUTHOR" ]; then
    echo "Commenter '${COMMENTER}' is not the PR author '${PR_AUTHOR}'. Ignoring."
    exit 0
  fi

  echo "Processing ICLA signature for ${COMMENTER}..."

  USER_INFO=$(gh api "users/${COMMENTER}")
  NAME=$(jq -r '.name // .login' <<< "$USER_INFO")
  EMAIL=$(jq -r '.email // ""' <<< "$USER_INFO")
  SIGNED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Append signature with retry on commit conflict (concurrent signers
  # editing signatures.json simultaneously).
  for attempt in 1 2 3; do
    FILE=$(gh api \
      "repos/${GITHUB_REPOSITORY}/contents/.github/cla/signatures.json")
    BLOB_SHA=$(jq -r '.sha' <<< "$FILE")
    CONTENT=$(jq -r '.content' <<< "$FILE" | base64 -d)

    # Skip if already signed (idempotent).
    if echo "$CONTENT" | jq --exit-status --arg u "$COMMENTER" \
        '.icla | has($u)' >/dev/null; then
      echo "${COMMENTER} has already signed the ICLA."
      break
    fi

    UPDATED=$(jq \
      --arg user "$COMMENTER" \
      --arg name "$NAME" \
      --arg email "$EMAIL" \
      --arg date "$SIGNED_AT" \
      '.icla[$user] = {
        name: $name,
        email: $email,
        signedAt: $date,
        claVersion: "1.0"
      }' <<< "$CONTENT")

    ENCODED=$(base64 -w0 <<< "$UPDATED")

    if jq -n \
        --arg message "cla: sign ICLA (${COMMENTER})" \
        --arg content "$ENCODED" \
        --arg sha "$BLOB_SHA" \
        '{message: $message, content: $content, sha: $sha}' \
        | gh api \
            "repos/${GITHUB_REPOSITORY}/contents/.github/cla/signatures.json" \
            -X PUT --input - 2>&1; then
      echo "Signature committed on attempt ${attempt}."
      break
    fi

    echo "Attempt ${attempt} conflicted, retrying..."
    [ "$attempt" -eq 3 ] && { echo "Failed after 3 attempts."; exit 1; }
    sleep 1
  done

  create_check "success" "CLA signed" \
    "${COMMENTER} has signed the CLA."

  # Acknowledge the sign comment with a +1 reaction.
  gh api \
    "repos/${GITHUB_REPOSITORY}/issues/comments/${COMMENT_ID}/reactions" \
    -f content="+1" 2>/dev/null || true

# ── Recheck ───────────────────────────────────────────────────────────────
elif [ "$BODY" = "recheck" ]; then
  echo "Rechecking CLA status for PR #${PR_NUMBER} (author ${PR_AUTHOR})..."

  SIGNATURES=$(gh api \
    "repos/${GITHUB_REPOSITORY}/contents/.github/cla/signatures.json" \
    --jq '.content' | base64 -d)

  if echo "$SIGNATURES" | jq --exit-status --arg u "$PR_AUTHOR" \
      '.allowlist | index($u)' >/dev/null 2>&1 \
    || echo "$SIGNATURES" | jq --exit-status --arg u "$PR_AUTHOR" \
      '.icla | has($u)' >/dev/null 2>&1 \
    || echo "$SIGNATURES" | jq --exit-status --arg u "$PR_AUTHOR" \
      '[.ccla[]? | .contributors[]?] | any(. == $u)' >/dev/null 2>&1; then
    create_check "success" "CLA signed" \
      "${PR_AUTHOR} has signed the CLA."
  else
    create_check "failure" "CLA not signed" \
      "${PR_AUTHOR} has not signed the CLA. See the comment above for instructions."
  fi

else
  echo "Comment does not match any known command. Ignoring."
fi
