#!/bin/bash
#
# install-brain-sync.sh — daily `claude -p "/sync-all"` via macOS launchd
#
# Edit the three KNOBS at the top, then:
#   bash scripts/install-brain-sync.sh
#
# Verify it's queued:
#   launchctl print gui/$UID/com.user.sync-second-brain | grep -E 'state|next'
#
# Force-fire without waiting:
#   launchctl kickstart -k gui/$UID/com.user.sync-second-brain
#
# Uninstall:
#   launchctl bootout gui/$UID/com.user.sync-second-brain
#   rm ~/Library/LaunchAgents/com.user.sync-second-brain.plist
#

set -euo pipefail

# =============================================================
# KNOBS — edit these to match your setup
# =============================================================
VAULT_DIR="$HOME/Documents/second-brain"   # ← your vault path
HOUR=10                                    # ← 24-hour clock; 10 = 10:00 AM
MINUTE=0
# =============================================================

LABEL="com.user.sync-second-brain"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_DIR="$VAULT_DIR/.logs"

CLAUDE_BIN="$(command -v claude || true)"
if [ -z "$CLAUDE_BIN" ]; then
  echo "❌ 'claude' not found in PATH. Install Claude Code CLI first:"
  echo "   https://docs.claude.com/claude-code"
  exit 1
fi
echo "✓ claude binary: $CLAUDE_BIN"

if [ ! -d "$VAULT_DIR" ]; then
  echo "❌ Vault directory not found: $VAULT_DIR"
  echo "   Edit VAULT_DIR at the top of this script."
  exit 1
fi

mkdir -p "$LOG_DIR" "$(dirname "$PLIST")"

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
      <string>cd "$VAULT_DIR" &amp;&amp; $CLAUDE_BIN -p --dangerously-skip-permissions "/sync-all"</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key><integer>$HOUR</integer>
      <key>Minute</key><integer>$MINUTE</integer>
    </dict>
    <key>RunAtLoad</key><false/>
    <key>StandardOutPath</key><string>$LOG_DIR/sync.out.log</string>
    <key>StandardErrorPath</key><string>$LOG_DIR/sync.err.log</string>
    <key>EnvironmentVariables</key>
    <dict>
      <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
      <key>HOME</key><string>$HOME</string>
    </dict>
</dict>
</plist>
PLIST_EOF

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST"
launchctl enable "gui/$UID/$LABEL"

echo "✓ Loaded. Next run: $(printf '%02d:%02d' $HOUR $MINUTE) daily."
echo ""
echo "Logs: $LOG_DIR/sync.{out,err}.log"
