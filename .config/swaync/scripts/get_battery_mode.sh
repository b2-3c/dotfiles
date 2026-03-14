#!/bin/bash
# Returns true if NOT power-saver
if ! command -v powerprofilesctl &>/dev/null; then
    echo "false"; exit
fi
CURRENT=$(powerprofilesctl get 2>/dev/null || echo "balanced")
[[ "$CURRENT" != "power-saver" ]] && echo "true" || echo "false"
