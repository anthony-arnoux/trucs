#!/bin/bash

sleep 5

if which curl &> /dev/null; then
    script_content=$(curl -4 -fsSL 'https://raw.githubusercontent.com/anthony-arnoux/trucs/main/motd.sh')
elif which wget &> /dev/null; then
    script_content=$(wget --inet4-only -qO- 'https://raw.githubusercontent.com/anthony-arnoux/trucs/main/motd.sh')
fi

echo "$script_content" | bash
exit
