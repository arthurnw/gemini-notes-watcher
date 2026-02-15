#!/bin/bash

WATCH_DIR="$HOME/Downloads"
DEST_DIR="$HOME/vaults/obsidian/02-work/gemini-notes"  # change to your desired folder
TEMP_DIR="/tmp/gemini-notes-processing"

mkdir -p "$DEST_DIR" "$TEMP_DIR"
echo "Watching: $WATCH_DIR"
echo "Destination: $DEST_DIR"
echo "Temp: $TEMP_DIR"

SUMMARY_PROMPT='You are a meeting notes summarizer. You will receive a meeting transcript. Produce a markdown document with exactly three sections:

## Summary
1-3 sentence executive summary of the meeting.

## Details
Summary of the key sections and topics discussed in the meeting. Use subsections (###) to organize by topic. Be thorough but concise.

## Action Items
Bulleted list of action items identified in the transcript. Include the responsible person if mentioned.

Output ONLY the markdown content. No preamble, no commentary.'

fswatch -0 --event Created "$WATCH_DIR" | while read -d "" file; do
  filename=$(basename "$file")

  if [[ "$filename" == *"Notes by Gemini"* ]]; then
    sleep 1

    echo "---"
    echo "$(date): Detected: $filename"

    if [[ ! -f "$file" ]]; then
      echo "File no longer exists, skipping: $file"
      continue
    fi

    # Generate output filename (dash-case, alphanumeric and dashes only)
    newname=$(echo "$filename" | tr '[:upper:]' '[:lower:]' | sed 's/\.[^.]*$//' | sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//;s/-$//').md

    # Move transcript to temp for processing
    temp_file="$TEMP_DIR/$filename"
    mv -v "$file" "$temp_file" 2>&1
    if [[ $? -ne 0 ]]; then
      echo "Failed to move file to temp dir, skipping"
      continue
    fi
    echo "Moved to temp: $temp_file"

    # Summarize with Claude
    echo "Generating summary with Claude..."
    summary_file="$TEMP_DIR/$newname"

    claude -p "$SUMMARY_PROMPT" < "$temp_file" --output-format text > "$summary_file" 2>/tmp/gemini-notes-claude.err
    claude_exit=$?

    if [[ $claude_exit -ne 0 ]]; then
      echo "Claude summarization failed (exit code: $claude_exit)"
      echo "Stderr: $(cat /tmp/gemini-notes-claude.err)"
      echo "Moving original transcript to dest as fallback"
      mv -v "$temp_file" "$DEST_DIR/$newname" 2>&1
      continue
    fi

    # Check that summary is non-empty
    if [[ ! -s "$summary_file" ]]; then
      echo "Claude produced empty output"
      echo "Moving original transcript to dest as fallback"
      mv -v "$temp_file" "$DEST_DIR/$newname" 2>&1
      continue
    fi

    echo "Summary generated: $(wc -l < "$summary_file") lines"

    # Move summary to destination
    mv -v "$summary_file" "$DEST_DIR/$newname" 2>&1
    if [[ $? -ne 0 ]]; then
      echo "Failed to move summary to dest"
      continue
    fi

    # Clean up temp transcript
    rm -f "$temp_file"
    echo "$(date): Done. Output: $DEST_DIR/$newname"
  fi
done
