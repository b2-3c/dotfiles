#!/bin/bash
# checklist; make the script use systemd-inhibit instead of killing hypridle

STATE_FILE="/tmp/coffeestate"
[ ! -f "$STATE_FILE" ] && echo "1" > "$STATE_FILE"

is_hypridle_running() {
    if pidof hypridle >/dev/null; then
        echo "running"
    else
        echo "not running"
    fi
}

if [ "$1" = "toggle" ]; then
    if [ "$(cat $STATE_FILE)" = "1" ]; then
        echo "2" > "$STATE_FILE"
        pkill hypridle
    else
        echo "1" > "$STATE_FILE"
        hypridle &
    fi
    exit 0
fi

STATE=$(cat $STATE_FILE)
HYPR_STATE=$(is_hypridle_running)

if [ "$STATE" = "1" ]; then
    #active
    echo "{\"text\": \" \", \"class\": \"coffee2\", \"tooltip\": \"Hypridle is $HYPR_STATE\"}"
else
    #killed
    echo "{\"text\": \" \", \"class\": \"coffee1\", \"tooltip\": \"Hypridle is $HYPR_STATE\"}"
fi