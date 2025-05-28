#!/bin/bash

# Servers grouped by category
cat1_servers=(
    "wazuh"
    "zabbix"
    "opnsense"
    "bastion"
    "teleport"
    "vault"
)

cat2_servers=(
    "sgbd-preprod"
    "sgbd-prod"
)

cat3_servers=(
    "web-dev"
    "web-beta"
    "web-prod"
)

cat4_servers=(
    "s3-preprod"
    "s3-prod"
)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m' # Yellow
NC='\033[0m' # No Color

# Function to ping a server and extract latency
ping_server() {
    local server=$1
    local output
    output=$(ping -c 1 -W 1 "$server" 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        # Extract latency from ping output
        local latency
        latency=$(echo "$output" | grep 'time=' | sed -E 's/.*time=([0-9.]+) ms/\1/')
        echo -e "${NC}${server} ${GREEN}OK${NC} - ${latency} ms"
    else
        echo -e "${NC}${server} ${RED}KO${NC}"
    fi
}

# Function to print servers from a category
ping_category() {
    local category_name=$1
    local category_servers=("${!2}")

    echo -e "${YELLOW}${category_name}:${NC}" # Category title in yellow
    for server in "${category_servers[@]}"; do
        ping_server "$server" &
    done
    wait
    echo
}

# Main
echo ""
ping_category "infra" cat1_servers[@]
ping_category "db" cat2_servers[@]
ping_category "web" cat3_servers[@]
ping_category "s3" cat4_servers[@]
