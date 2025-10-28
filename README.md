#!/bin/bash

# --- Configuration ---
# Bash array with the names of the services to check.
services_to_check=("sshd" "cron" "nginx")

# Flag to track if any service was found to be inactive
all_active=true

echo "--- Service Status Checker ---"

# --- Loop and Check Services ---
for service in "${services_to_check[@]}"; do
    echo "Checking service: $service..."

# Check the service status quietly. Exit code 0 means 'active'.
    systemctl is-active --quiet "$service"

# $? holds the exit code of the last executed command
    if [ $? -ne 0 ]; then
        echo "WARNING: The '$service' service is not running!"
        all_active=false

# --- Optional Bonus: Attempt to Restart ---
        echo "   Attempting to restart '$service'..."
# NOTE: This requires 'sudo' privileges. You may need to enter a password.
        sudo systemctl restart "$service" &> /dev/null

# Check status again after attempting restart
        systemctl is-active --quiet "$service"
        if [ $? -eq 0 ]; then
            echo "SUCCESS: '$service' has been restarted and is now active."
        else
            echo "FAILURE: Could not restart '$service'. Manual intervention required."
        fi
        
    else
        echo "   Status: Active "
    fi
    echo "" # Add a blank line for readability
done

# --- Generate Final Report ---
echo "--- Final Report ---"
if $all_active; then
    echo "All critical services are active."
else
    echo "One or more critical services required attention. Review the output above."
# We exit with a non-zero status to indicate an issue (good practice for scripts)
    exit 1 
fi

# Exit successfully if all were checked and running
exit 0

#Part 3
# Create a small log file
echo "This is a small log file." > app_debug.log

# Create a large log file (5MB)
head -c 5M /dev/urandom > system_errors.log

# Create another large log file (10MB) and set its modification time to 8 days ago
head -c 10M /dev/urandom > access.log
touch -d "8 days ago" access.log

# Create a small log file
echo "This is a small log file." > app_debug.log

# Create a large log file (5MB)
head -c 5M /dev/urandom > system_errors.log



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

# Create another large log file (10MB) and set its modification time to 8 days ago
head -c 10M /dev/urandom > access.log
touch -d "8 days ago" access.log
