#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="watch-gemini-notes.sh"
INSTALL_DIR="$HOME/scripts"
PLIST_NAME="com.user.gemini-notes-watcher.plist"
PLIST_DIR="$HOME/Library/LaunchAgents"
MODEL="${1:-sonnet}"

if [[ "$MODEL" != "haiku" && "$MODEL" != "sonnet" && "$MODEL" != "opus" ]]; then
  echo "Invalid model: $MODEL (must be haiku, sonnet, or opus)"
  exit 1
fi

echo "=== Gemini Notes Watcher Installer ==="
echo "Model: $MODEL"
echo

# Check for fswatch
if ! command -v fswatch &>/dev/null; then
  echo "fswatch is not installed. Install it with:"
  echo "  brew install fswatch"
  exit 1
fi
echo "fswatch found: $(which fswatch)"

# Check for claude CLI
if ! command -v claude &>/dev/null; then
  echo "Claude Code CLI is not installed. Install it with:"
  echo "  npm install -g @anthropic-ai/claude-code"
  exit 1
fi
echo "claude found: $(which claude)"

# Unload existing launch agent if present
if launchctl list 2>/dev/null | grep -q "com.user.gemini-notes-watcher"; then
  echo "Stopping existing watcher..."
  launchctl unload "$PLIST_DIR/$PLIST_NAME" 2>/dev/null || true
fi

# Copy script
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
echo "Installed script to $INSTALL_DIR/$SCRIPT_NAME"

# Install launch agent plist
mkdir -p "$PLIST_DIR"
cat > "$PLIST_DIR/$PLIST_NAME" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.gemini-notes-watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>${INSTALL_DIR}/${SCRIPT_NAME} ${MODEL}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/gemini-notes-watcher.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/gemini-notes-watcher.err</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin</string>
    </dict>
</dict>
</plist>
EOF
echo "Installed plist to $PLIST_DIR/$PLIST_NAME"

# Load launch agent
launchctl load "$PLIST_DIR/$PLIST_NAME"
echo "Launch agent loaded."

echo
echo "=== Installation complete ==="
echo
echo "MANUAL STEP REQUIRED: Grant Full Disk Access"
echo "  1. Open System Settings > Privacy & Security > Full Disk Access"
echo "  2. Click + and add /bin/bash (use Cmd+Shift+G to type the path)"
echo "  3. Optionally add $(which fswatch)"
echo "  4. Toggle both on"
echo "  5. Restart the watcher:"
echo "     launchctl unload ~/Library/LaunchAgents/$PLIST_NAME"
echo "     launchctl load ~/Library/LaunchAgents/$PLIST_NAME"
echo
echo "To configure, edit $INSTALL_DIR/$SCRIPT_NAME and update WATCH_DIR and DEST_DIR."
