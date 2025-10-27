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


