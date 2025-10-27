#!/bin/bash

# --- Configuration Variables ---
# Use the full, absolute path for the TARGET_DIR and ARCHIVE_DIR.
# The '~' (tilde) shortcut often doesn't work reliably inside scripts.
# We use $HOME to ensure the path is correct regardless of where the script runs.
TARGET_DIR="$HOME/log_project/test_logs"
ARCHIVE_DIR="$HOME/log_project/archives"
SIZE_THRESHOLD="+2M" # Find files larger than 2 Megabytes
AGE_THRESHOLD="+7"  # Find files older than 7 days

# Current date in YYYY-MM-DD format for the archive filename
CURRENT_DATE=$(date +%Y-%m-%d)

echo "--- Log Archiver and Rotator Script ---"
echo "Targeting logs in: $TARGET_DIR"
echo "Archiving to: $ARCHIVE_DIR"
echo "Criteria: > $SIZE_THRESHOLD and modified > $AGE_THRESHOLD days ago"
echo "---------------------------------------"

# 1. Create Archive Directory
if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "Archive directory not found. Creating $ARCHIVE_DIR..."
    mkdir -p "$ARCHIVE_DIR"
fi

# 2. Find Large and Old Files
# find: locate files
# -type f: only regular files
# -size +2M: files larger than 2 Megabytes
# -mtime +7: files modified more than 7 days ago
# -print0: print results separated by null character (safer for files with spaces)
find_results=$(find "$TARGET_DIR" -type f -size "$SIZE_THRESHOLD" -mtime "$AGE_THRESHOLD" -print0)

# Check if any files were found
if [ -z "$find_results" ]; then
    echo "No log files found matching the criteria. Exiting."
    exit 0
fi

# 3. Loop and Archive
# read -d $'\0': reads items separated by null character
while IFS= read -r -d $'\0' log_file; do
    
    # Get just the filename (basename)
    filename=$(basename "$log_file")
    
    # Define the full path for the archive
    archive_name="${filename}_${CURRENT_DATE}.tar.gz"
    archive_path="$ARCHIVE_DIR/$archive_name"
    
    echo "Processing file: $filename"

    # Compress the file into the archive directory
    # -z: gzip compression, -c: create archive, -f: specify filename
    if tar -czf "$archive_path" -C "$(dirname "$log_file")" "$filename"; then
        
        # 4. Clear the Original Log File
        # The '>' operator truncates the file to zero length without deleting it.
        > "$log_file"
        
        # 5. Log Your Actions
        echo "Archived and cleared: $filename -> $archive_name"
    else
        echo "ERROR: Failed to create archive for $filename."
    fi

done <<< "$find_results"

echo "---------------------------------------"
echo "Script finished."

# Optional check to see archived file sizes
ls -lh "$ARCHIVE_DIR"

exit 0