#!/bin/bash
#
# install-cross-device-pull.sh — hourly `git pull` on a secondary device
#
# Use on any Mac OTHER than your main one to keep the vault mirrored.
# Your main Mac runs install-brain-sync.sh (daily /sync-all → push);
# this device just pulls what's been pushed.
#
# Edit REPO_DIR at the top, then:
#   bash scripts/install-cross-device-pull.sh
#
# Verify:
#   tail ~/Library/Logs/brain-pull.log
#   launchctl list | grep brain-pull
#
# Uninstall:
#   launchctl bootout gui/$UID/com.user.brain-pull
#   rm ~/Library/LaunchAgents/com.user.brain-pull.plist
#

set -euo pipefail

# =============================================================
# KNOBS — edit these to match your setup
# =============================================================
REPO_DIR="$HOME/Documents/second-brain"    # ← your vault clone path on this device
INTERVAL_SECONDS=3600                      # ← how often to pull (3600 = hourly)
# =============================================================

LABEL="com.user.brain-pull"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/brain-pull.log"

GIT_BIN="$(command -v git || true)"
if [ -z "$GIT_BIN" ]; then
  echo "❌ 'git' not found in PATH. Install Xcode Command Line Tools:"
  echo "   xcode-select --install"
  exit 1
fi

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "❌ Not a git repo: $REPO_DIR"
  echo "   Edit REPO_DIR at the top of this script, or clone the repo first."
  exit 1
fi

mkdir -p "$(dirname "$PLIST")"

cat > "$PLIST" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>-lc</string>
    <string>cd "$REPO_DIR" &amp;&amp; $GIT_BIN pull --rebase --autostash &gt;&gt; "$LOG" 2&gt;&amp;1 &amp;&amp; echo "[\$(date +%F\\ %T)] sync OK" &gt;&gt; "$LOG"</string>
  </array>
  <key>StartInterval</key><integer>$INTERVAL_SECONDS</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
PLIST_EOF

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST"
launchctl enable "gui/$UID/$LABEL"

echo "✓ Auto-pull installed."
echo "  Repo:     $REPO_DIR"
echo "  Schedule: every $INTERVAL_SECONDS seconds + once at login"
echo "  Log:      $LOG"
echo ""
echo "First pull just ran. Confirm: tail $LOG"
