#!/usr/bin/env bash
# Smooth stepped keyboard backlight fade for MSI Modern laptops (0 <-> 1 <-> 2 <-> 3)
set -euo pipefail

KBD="/sys/class/leds/msiacpi::kbd_backlight/brightness"
DELAY=0.07

if [[ ! -w "$KBD" ]]; then
    echo "Error: $KBD is not writable. Ensure msi-ec is loaded and udev rules are active." >&2
    exit 1
fi

get_current() {
    cat "$KBD" 2>/dev/null || echo 0
}

fade_in() {
    local cur target
    cur=$(get_current)
    target="${1:-3}"
    for ((l = cur + 1; l <= target; l++)); do
        echo "$l" > "$KBD"
        sleep "$DELAY"
    done
}

fade_out() {
    local cur target
    cur=$(get_current)
    target="${1:-0}"
    for ((l = cur - 1; l >= target; l--)); do
        echo "$l" > "$KBD"
        sleep "$DELAY"
    done
}

toggle() {
    local cur
    cur=$(get_current)
    if [[ "$cur" -gt 0 ]]; then
        fade_out 0
    else
        fade_in 3
    fi
}

case "${1:-toggle}" in
    in|up)
        fade_in "${2:-3}"
        ;;
    out|down)
        fade_out "${2:-0}"
        ;;
    toggle)
        toggle
        ;;
    get)
        get_current
        ;;
    set)
        echo "${2:-3}" > "$KBD"
        ;;
    *)
        echo "Usage: $0 {in|out|toggle|get|set [0-3]}"
        exit 1
        ;;
esac
