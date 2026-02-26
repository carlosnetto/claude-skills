#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="colima-k8s"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/skills/$SKILL_NAME"

echo "Installing $SKILL_NAME skill..."

mkdir -p "$TARGET_DIR/topics"

cp "$SKILL_DIR/SKILL.md" "$TARGET_DIR/SKILL.md"
cp "$SKILL_DIR/topics/"*.md "$TARGET_DIR/topics/"

echo "✓ Installed to $TARGET_DIR"
echo ""
echo "Skill is now available in all Claude Code sessions."
echo "Non-invocable — activates automatically when Colima/K8s topics are detected."
