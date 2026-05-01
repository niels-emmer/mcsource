#!/usr/bin/env bash
# Usage: ./scripts/release.sh <minor|major> "<description>"
# Bumps the version, commits everything, creates an annotated tag, and pushes.
set -euo pipefail

BUMP="${1:-minor}"
DESCRIPTION="${2:-Release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST="$ROOT/Info.plist"

cd "$ROOT"

# ── Read current version ─────────────────────────────────────────────────────
CURRENT=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PLIST")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# ── Bump ─────────────────────────────────────────────────────────────────────
case "$BUMP" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
    *) echo "Usage: $0 <minor|major|patch> <description>"; exit 1 ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
TAG="v${NEW_VERSION}"

echo "→ Bumping ${CURRENT} → ${NEW_VERSION} (${BUMP})"

# ── Update Info.plist ─────────────────────────────────────────────────────────
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${NEW_VERSION}" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_VERSION}"            "$PLIST"

# ── Build release notes for the annotated tag ─────────────────────────────────
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
    COMMITS=$(git log "${LAST_TAG}..HEAD" --oneline 2>/dev/null || echo "(no new commits)")
else
    COMMITS=$(git log --oneline | head -20)
fi

TAG_MESSAGE="${DESCRIPTION}

Changes:
${COMMITS}"

# ── Stage, commit, tag, push ─────────────────────────────────────────────────
git add -A
git commit -m "Release ${TAG}: ${DESCRIPTION}"
git tag -a "$TAG" -m "$TAG_MESSAGE"

echo "→ Pushing to origin..."
git push origin HEAD
git push origin "$TAG"

echo ""
echo "✓ Released ${TAG}"
echo "  GitHub will build and publish the release automatically."
echo "  https://github.com/niels-emmer/McAudio/releases/tag/${TAG}"
