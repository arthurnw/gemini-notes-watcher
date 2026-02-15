# Gemini Notes Watcher

A macOS file watcher that automatically renames and moves Google Docs "Notes by Gemini" exports from Downloads to a specified folder.

## What It Does

When Google Meet generates meeting notes via Gemini, exporting them as markdown drops a file like:

```
Meeting Notes - 2026_02_13 11_56 EST - Notes by Gemini.md
```

This watcher detects files matching `*Notes by Gemini*` in your Downloads folder, converts the filename to dash-case, and moves it to a destination folder:

```
meeting-notes-2026_02_13-11_56-est-notes-by-gemini.md
```

It runs as a macOS Launch Agent, starting automatically on login.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh)
- fswatch: `brew install fswatch`

## Installation

1. Clone this repo
2. Edit `watch-gemini-notes.sh` and set `DEST_DIR` to your desired output folder
3. Run the install script:

```bash
./install.sh
```

The install script will:
- Check that `fswatch` is installed
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

## Google Docs Export Tip

To export only the first tab of a multi-tab Google Doc (notes without transcript), append `&tab=t.0` to the export URL:

```
https://docs.google.com/document/d/YOUR_DOC_ID/export?format=md&tab=t.0
```

## Configuration

Edit `~/scripts/watch-gemini-notes.sh` to change:

| Variable | Default | Description |
|----------|---------|-------------|
| `WATCH_DIR` | `$HOME/Downloads` | Folder to monitor for new files |
| `DEST_DIR` | `$HOME/vaults/obsidian/02-work/gemini-notes` | Where processed files are moved |

The filename match pattern (`*Notes by Gemini*`) can also be changed in the script.

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
```

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.user.gemini-notes-watcher.plist
rm ~/Library/LaunchAgents/com.user.gemini-notes-watcher.plist
rm ~/scripts/watch-gemini-notes.sh
```

Optionally remove Full Disk Access entries for `/bin/bash` and `fswatch` in System Settings.
