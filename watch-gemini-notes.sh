#!/bin/bash

WATCH_DIR="$HOME/Downloads"
DEST_DIR="$HOME/vaults/obsidian/02-work/gemini-notes"  # change to your desired folder

mkdir -p "$DEST_DIR"
echo "Watching: $WATCH_DIR"
echo "Destination: $DEST_DIR"

fswatch -0 "$WATCH_DIR" | while read -d "" file; do
  filename=$(basename "$file")

  if [[ "$filename" == *"Notes by Gemini"* ]]; then
    sleep 1

    echo "Processing: $file"
    echo "File exists: $(test -f "$file" && echo 'yes' || echo 'no')"

    newname=$(echo "$filename" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -s '-')

    mv -v "$file" "$DEST_DIR/$newname" 2>&1
    echo "Exit code: $?"
  fi
done
