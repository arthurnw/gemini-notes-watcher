# Gemini Notes Watcher

A macOS file watcher that automatically summarizes Google Meet transcript exports using Claude and saves the results to a specified folder.

## What It Does

When Google Meet generates meeting notes via Gemini, you export the **transcript tab** as markdown. This drops a file like:

```
Meeting Notes - 2026_02_13 11_56 EST - Notes by Gemini.md
```

The watcher:

1. Detects files matching `*Notes by Gemini*` in your Downloads folder
2. Moves the transcript to a temp directory
3. Passes it to the Claude CLI to generate a structured summary with:
   - **Summary** - 1-3 sentence executive summary
   - **Details** - Key topics organized by section
   - **Action Items** - Action items with responsible parties
4. Saves the summary with a sanitized filename in the destination folder
5. Cleans up the temp transcript

Output filename: `meeting-notes-2026-02-13-11-56-est-notes-by-gemini.md`

Filenames are lowercased, non-alphanumeric characters replaced with dashes, and consecutive dashes collapsed.

If Claude summarization fails, the original transcript is moved to the destination as a fallback.

It runs as a macOS Launch Agent, starting automatically on login.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh)
- fswatch: `brew install fswatch`
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code): `npm install -g @anthropic-ai/claude-code`
  - Must be authenticated (`claude` should work from the terminal)

## Installation

1. Clone this repo
2. Edit `watch-gemini-notes.sh` and set `DEST_DIR` to your desired output folder
3. Run the install script:

```bash
./install.sh
```

The install script will:
- Check that `fswatch` and `claude` are installed
- Copy the watcher script to `~/scripts/`
- Install a Launch Agent plist to `~/Library/LaunchAgents/`
- Load the Launch Agent

### Manual Step: Full Disk Access

The watcher needs Full Disk Access to monitor the Downloads folder. After running the install script:

1. Open **System Settings** > **Privacy & Security** > **Full Disk Access**
2. Click the **+** button
3. Press `Cmd+Shift+G`, type `/bin/bash`, click **Open**
4. Optionally add `fswatch` (run `which fswatch` to find its path)
5. Toggle both on
6. Restart the watcher:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.gemini-notes-watcher.plist
launchctl load ~/Library/LaunchAgents/com.user.gemini-notes-watcher.plist
```

## Google Docs Export

To export only the transcript tab of a multi-tab Google Doc, append `&tab=t.0` to the export URL (adjust the tab index as needed):

```
https://docs.google.com/document/d/YOUR_DOC_ID/export?format=md&tab=t.0
```

## Configuration

Edit `~/scripts/watch-gemini-notes.sh` to change:

| Variable | Default | Description |
|----------|---------|-------------|
| `WATCH_DIR` | `$HOME/Downloads` | Folder to monitor for new files |
| `DEST_DIR` | `$HOME/vaults/obsidian/02-work/gemini-notes` | Where summary files are saved |
| `TEMP_DIR` | `/tmp/gemini-notes-processing` | Temp directory for processing |

The filename match pattern (`*Notes by Gemini*`) and the Claude prompt (`SUMMARY_PROMPT`) can also be changed in the script.

## Useful Commands

```bash
# Stop the watcher
launchctl unload ~/Library/LaunchAgents/com.user.gemini-notes-watcher.plist

# Start the watcher
launchctl load ~/Library/LaunchAgents/com.user.gemini-notes-watcher.plist

# Check if running
launchctl list | grep gemini

# View logs
tail -f /tmp/gemini-notes-watcher.log

# View errors
cat /tmp/gemini-notes-watcher.err

# View Claude errors (if summarization fails)
cat /tmp/gemini-notes-claude.err
```

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.user.gemini-notes-watcher.plist
rm ~/Library/LaunchAgents/com.user.gemini-notes-watcher.plist
rm ~/scripts/watch-gemini-notes.sh
```

Optionally remove Full Disk Access entries for `/bin/bash` and `fswatch` in System Settings.
