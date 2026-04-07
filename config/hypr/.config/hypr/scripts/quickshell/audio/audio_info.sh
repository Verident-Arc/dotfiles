#!/usr/bin/env bash

# This script gathers audio information for the Quickshell AudioPopup.

get_info() {
    # Get lists in JSON format
    local sinks=$(pactl --format=json list sinks)
    # Filter out monitor sources for a cleaner input list
    local sources=$(pactl --format=json list sources | jq -c '[.[] | select(.monitor_source == "" or .monitor_source == null)]')
    local sink_inputs=$(pactl --format=json list sink-inputs)
    local source_outputs=$(pactl --format=json list source-outputs)
    local default_sink=$(pactl get-default-sink)
    local default_source=$(pactl get-default-source)

    cat <<EOF
{
  "sinks": $sinks,
  "sources": $sources,
  "sink_inputs": $sink_inputs,
  "source_outputs": $source_outputs,
  "default_sink": "$default_sink",
  "default_source": "$default_source"
}
EOF
}

set_default_sink() {
    pactl set-default-sink "$1"
}

set_default_source() {
    pactl set-default-source "$1"
}

set_volume() {
    local target="$1" # sink, source, sink-input, source-output
    local id="$2"
    local vol="$3" # 0-100
    pactl set-$target-volume "$id" "$vol%"
}

toggle_mute() {
    local target="$1"
    local id="$2"
    pactl set-$target-mute "$id" toggle
}

mute_all_sources() {
    # Get all source indices
    local sources=$(pactl --format=json list sources | jq -r '.[].index')
    for idx in $sources; do
        pactl set-source-mute "$idx" toggle
    done
}

case "$1" in
    --get) get_info ;;
    --set-sink) set_default_sink "$2" ;;
    --set-source) set_default_source "$2" ;;
    --set-volume) set_volume "$2" "$3" "$4" ;;
    --toggle-mute) toggle_mute "$2" "$3" ;;
    --mute-all-sources) mute_all_sources ;;
    *) echo "Usage: $0 {--get | --set-sink | --set-source | --set-volume | --toggle-mute | --mute-all-sources}" ;;
esac
