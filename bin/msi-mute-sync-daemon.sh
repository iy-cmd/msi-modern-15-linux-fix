#!/usr/bin/env bash
# Standalone PipeWire / PulseAudio daemon that keeps MSI mute & micmute LEDs in sync
set -euo pipefail

MUTE_LED="/sys/class/leds/platform::mute/brightness"
MIC_LED="/sys/class/leds/platform::micmute/brightness"

sync_state() {
    # Check default sink mute state
    if command -v wpctl >/dev/null 2>&1; then
        local spk_muted mic_muted
        if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "\[MUTED\]"; then
            spk_muted=1
        else
            spk_muted=0
        fi

        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q "\[MUTED\]"; then
            mic_muted=1
        else
            mic_muted=0
        fi

        [[ -w "$MUTE_LED" ]] && echo "$spk_muted" > "$MUTE_LED" 2>/dev/null || true
        [[ -w "$MIC_LED" ]] && echo "$mic_muted" > "$MIC_LED" 2>/dev/null || true
    fi
}

# Initial sync
sync_state

# Monitor PipeWire / PulseAudio events
if command -v pactl >/dev/null 2>&1; then
    pactl subscribe 2>/dev/null | while read -r line; do
        if [[ "$line" =~ (sink|source) ]]; then
            sync_state
        fi
    done
else
    # Fallback polling loop if pactl is not installed
    while true; do
        sync_state
        sleep 1
    done
fi
