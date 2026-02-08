#!/usr/bin/env bash

# Screen recording toggle script using wf-recorder
# Saves recordings to ~/Videos/Recordings/

RECORDING_FILE="/tmp/wf-recorder.pid"
SAVE_DIR="$HOME/Videos/Recordings"
STATUS_FILE="$HOME/.cache/screenrecording-status"

if [ -f "$RECORDING_FILE" ]; then
    # Stop recording
    PID=$(cat "$RECORDING_FILE")
    if kill -INT "$PID" 2>/dev/null; then
        wait "$PID" 2>/dev/null
    fi
    rm -f "$RECORDING_FILE"
    rm -f "$STATUS_FILE"
    notify-send -t 3000 "Screen Recording" "Recording stopped and saved"
else
    # Start recording
    mkdir -p "$SAVE_DIR"
    OUTPUT="$SAVE_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"

    # Use slurp to select region
    GEOMETRY=$(slurp 2>/dev/null)

    if [ -z "$GEOMETRY" ]; then
        notify-send -t 3000 "Screen Recording" "Recording cancelled"
        exit 0
    fi

    # Get the default audio sink (wf-recorder will use its monitor)
    DEFAULT_SINK=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | grep "node.name" | cut -d'"' -f2)

    # Start recording in background with desktop audio (no mic)
    # Using PipeWire backend and specifying the sink will record from its monitor
    # Hardware accelerated encoding (GPU) for smooth performance with high quality
    wf-recorder -g "$GEOMETRY" -f "$OUTPUT" \
        --audio-backend=pipewire -a "$DEFAULT_SINK" \
        -c h264_vaapi -d /dev/dri/renderD128 \
        -p qp=18 \
        -r 60 \
        -P b=320k &
    RECORDER_PID=$!
    echo "$RECORDER_PID" > "$RECORDING_FILE"
    echo "recording" > "$STATUS_FILE"

    notify-send -t 3000 "Screen Recording" "Recording started\nPress Super+R to stop"
fi
