#!/usr/bin/env bash
# UserPromptSubmit hook: injects release context when the user says "session complete".
# Claude Code passes JSON via stdin; any stdout is shown to Claude as additional context.
set -euo pipefail

INPUT=$(cat)

# Extract the prompt text from the JSON payload
PROMPT=$(python3 -c "
import sys, json
try:
    print(json.loads(sys.argv[1]).get('prompt', ''))
except Exception:
    print('')
" "$INPUT" 2>/dev/null || echo "")

# Only act when "session complete" appears in the prompt
if ! echo "$PROMPT" | grep -qi "session complete"; then
    exit 0
fi

# Change to the project root (cwd from the hook payload)
CWD=$(python3 -c "
import sys, json
try:
    print(json.loads(sys.argv[1]).get('cwd', '.'))
except Exception:
    print('.')
" "$INPUT" 2>/dev/null || echo ".")
cd "$CWD" 2>/dev/null || true

# Collect context for Claude to make the version-bump decision
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist 2>/dev/null || echo "unknown")
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$LAST_TAG" ]; then
    LOG=$(git log "${LAST_TAG}..HEAD" --oneline 2>/dev/null || echo "(no commits since last tag)")
else
    LOG=$(git log --oneline 2>/dev/null | head -30 || echo "(no commits)")
fi

DIRTY=""
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    DIRTY="
Uncommitted changes:
$(git status --short 2>/dev/null | head -20)"
fi

cat <<CONTEXT
--- SESSION COMPLETE ---
Current version : ${VERSION}
Last release tag: ${LAST_TAG:-none}

Commits since last tag:
${LOG}${DIRTY}

Your task:
1. Review the commits above. Decide: is this a MINOR bump (new feature/behaviour) or a PATCH bump (bugfix/docs/refactor)?
2. Write a one-sentence description of the release.
3. Run: ./scripts/release.sh <minor|patch> "<description>"
   (use "major" only for breaking changes)
4. Confirm the tag and push succeeded, then report the new version and the GitHub release URL.
--- END CONTEXT ---
CONTEXT
