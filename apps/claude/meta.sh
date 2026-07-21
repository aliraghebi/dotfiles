#!/usr/bin/env bash
APP_OS="macos"
APP_BINARY="claude"
APP_DESCRIPTION="Claude desktop app + Claude Code CLI"
APP_DEPS=("rtk" "codegraph")
APP_CONFIGS=(
  "config/.claude/CLAUDE.md : ~/.claude/CLAUDE.md"
  "config/.claude/settings.json : ~/.claude/settings.json"
)
