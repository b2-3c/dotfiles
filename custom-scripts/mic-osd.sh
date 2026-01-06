#!/usr/bin/env bash

# Microphone mute toggle with mako OSD notification

wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Get mute status
volume=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
muted=$(echo "$volume" | grep -o "MUTED")

# Send notification
if [ -n "$muted" ]; then
    notify-send -h string:x-canonical-private-synchronous:microphone \
                -t 2000 \
                "Microphone: Muted" \
                "🎤🔇"
else
    notify-send -h string:x-canonical-private-synchronous:microphone \
                -t 2000 \
                "Microphone: Unmuted" \
                "🎤"
fi
