#!/bin/bash
# Install the google-oauth-dev skill for Claude Code
#
# Usage:
#   bash install.sh

set -e

SKILL_NAME="google-oauth-dev"
SKILL_DIR="$HOME/.claude/skills/$SKILL_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Claude Code skill: $SKILL_NAME"

mkdir -p "$SKILL_DIR/topics"

cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"

for topic in "$SCRIPT_DIR/topics/"*.md; do
  if [ -f "$topic" ]; then
    cp "$topic" "$SKILL_DIR/topics/$(basename "$topic")"
  fi
done

echo ""
echo "Installed to: $SKILL_DIR"
echo ""
echo "Files:"
find "$SKILL_DIR" -type f | sort | while read -r f; do
  echo "  $f"
done
echo ""
echo "The skill is now available in all Claude Code sessions."
