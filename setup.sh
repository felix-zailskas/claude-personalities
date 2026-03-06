#!/bin/bash
# This script sets up the Claude Personalities project interactively.

REPO_DIR="$(pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"

# 1. Symlinks for skills
read -rp "Do you want to add symlinks for this project's skills? [Y/n] " add_skills
add_skills="${add_skills:-Y}"
if [[ "$add_skills" =~ ^[Yy]$ ]]; then
  mkdir -p "$HOME/.claude/skills"
  for skill_dir in skills/*/; do
    skill_name=$(basename "$skill_dir")
    target="$HOME/.claude/skills/$skill_name"

    read -rp "  Add symlink for '$skill_name'? [Y/n] " add_skill
    add_skill="${add_skill:-Y}"
    if [[ ! "$add_skill" =~ ^[Yy]$ ]]; then
      echo "  Skipped: $skill_name"
      continue
    fi

    if [[ -e "$target" || -L "$target" ]]; then
      read -rp "  '$skill_name' already exists. Overwrite? [y/N] " overwrite
      overwrite="${overwrite:-N}"
      if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "  Skipped: $skill_name"
        continue
      fi
    fi

    rm -rf "$target"
    ln -sf "$REPO_DIR/$skill_dir" "$target"
    echo "  Linked: $skill_name"
  done
  echo "Done linking skills."
fi

# 2. Allow reading from this project
read -rp "Do you want to allow read access to this project in settings.json? [Y/n] " allow_read
allow_read="${allow_read:-Y}"
if [[ "$allow_read" =~ ^[Yy]$ ]]; then
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required to modify settings.json. Install it with: brew install jq"
    exit 1
  fi

  permission="Read($REPO_DIR/**)"

  if jq -e --arg p "$permission" '.permissions.allow // [] | index($p) != null' "$SETTINGS_FILE" &>/dev/null; then
    echo "Permission '$permission' already present, skipping."
  else
    tmp=$(mktemp)
    jq --arg p "$permission" '.permissions.allow = ((.permissions.allow // []) + [$p])' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    echo "Added '$permission' to permissions.allow in $SETTINGS_FILE"
  fi
fi