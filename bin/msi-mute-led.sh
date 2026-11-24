#!/usr/bin/env bash
# Directly toggle speaker / microphone mute LEDs on MSI Modern laptops
# Usage:
#   msi-mute-led.sh speaker on|off|toggle
#   msi-mute-led.sh mic on|off|toggle
set -euo pipefail

WHAT="${1:-speaker}"
ACTION="${2:-toggle}"

MUTE_LED="/sys/class/leds/platform::mute/brightness"
MIC_LED="/sys/class/leds/platform::micmute/brightness"

TARGET_LED="$MUTE_LED"
if [[ "$WHAT" =~ ^(mic|micmute|input)$ ]]; then
    TARGET_LED="$MIC_LED"
fi

if [[ ! -w "$TARGET_LED" ]]; then
    echo "Warning: $TARGET_LED not accessible." >&2
    exit 1
fi

case "$ACTION" in
    1|on|mute)
        echo 1 > "$TARGET_LED"
        ;;
    0|off|unmute)
        echo 0 > "$TARGET_LED"
        ;;
    toggle)
        CUR=$(cat "$TARGET_LED" 2>/dev/null || echo 0)
        if [[ "$CUR" -eq 1 ]]; then
            echo 0 > "$TARGET_LED"
        else
            echo 1 > "$TARGET_LED"
        fi
        ;;
    get)
        cat "$TARGET_LED"
        ;;
    *)
        echo "Usage: $0 {speaker|mic} {on|off|toggle|get}"
        exit 1
        ;;
esac
