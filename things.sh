#!/bin/bash

# List of servers
servers=(
    "srv1"
)

# List of available commands
commands=(
    "apt-get update"
    "apt-get update && apt-get upgrade -y"
    "apt-get autoclean && apt-get autoremove"
    "df -h"
    "uptime --pretty"
    "ping -c 1 -W 1 1.1.1.1"
    "cat /proc/loadavg"
    "free -m"
    "reboot"
    "poweroff"
    "cat /etc/sysctl.conf | grep swappiness"
)

# Display available commands
echo "Available commands:"
for i in "${!commands[@]}"; do
    echo "$((i+1))) ${commands[$i]}"
done

# Prompt user for command selection
read -p "Select a command to run on all servers (enter number 1-99): " choice

# Validate input (allow numbers 1-99)
if ! [[ "$choice" =~ ^[1-9]$|^[1-9][0-9]$ ]]; then
    echo "Invalid choice. Exiting."
    exit 1
fi

# Ensure that the choice is within the valid range
if (( choice < 1 || choice > ${#commands[@]} )); then
    echo "Invalid choice. Exiting."
    exit 1
fi

# Execute selected command on each server
selected_command="${commands[$((choice-1))]}"
for server in "${servers[@]}"; do
    echo ""
    echo "Executing on $server..."
    echo "/- - - - -"
    echo "|"
    ssh "$server" "$selected_command"
    echo "Finished executing on $server"
    echo "|"
    echo "\- - - - -"
    echo ""
done
