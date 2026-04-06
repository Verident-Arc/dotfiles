#!/usr/bin/env bash

## WIFI
get_wifi_status() {
    nmcli -t -f WIFI g 2>/dev/null || echo "disabled"
}

get_wifi_ssid() {
    local ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
    echo "${ssid:-}"
}

get_wifi_strength() {
    local signal=$(nmcli -f IN-USE,SIGNAL dev wifi 2>/dev/null | grep '^\*' | awk '{print $2}')
    echo "${signal:-0}"
}

get_wifi_icon() {
    local status=$(get_wifi_status)
    local ssid=$(get_wifi_ssid)
    
    if [ "$status" = "enabled" ]; then
        if [ -n "$ssid" ]; then
            local signal=$(get_wifi_strength)
            if [ "$signal" -ge 75 ]; then echo "󰤨"
            elif [ "$signal" -ge 50 ]; then echo "󰤥"
            elif [ "$signal" -ge 25 ]; then echo "󰤢"
            else echo "󰤟"; fi
        else
            echo "󰤯"
        fi
    else
        echo "󰤮"
    fi
}

## BLUETOOTH
get_bt_status() {
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        echo "on"
    else
        echo "off"
    fi
}

get_bt_icon() {
    if [ "$(get_bt_status)" = "on" ]; then
        if bluetoothctl devices Connected 2>/dev/null | grep -q "Device"; then
            echo "󰂱"
        else
            echo "󰂯"
        fi
    else
        echo "󰂲"
    fi
}

get_bt_connected_device() {
    if [ "$(get_bt_status)" = "on" ]; then
        local device=$(bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)
        echo "${device:-Disconnected}"
    else
        echo "Off"
    fi
}

## KB
get_kb_layout() {
    local layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1)
    echo "$layout" | cut -c1-2 | tr '[:lower:]' '[:upper:]'
}

## AUDIO
get_volume() {
    if command -v pamixer &> /dev/null; then
        pamixer --get-volume 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

is_muted() {
    if command -v pamixer &> /dev/null; then
        pamixer --get-mute 2>/dev/null || echo "false"
    else
        echo "false"
    fi
}

get_volume_icon() {
    local vol=$(get_volume | tr -cd '0-9')
    local muted=$(is_muted)
    [ -z "$vol" ] && vol=0
    if [ "$muted" = "true" ]; then echo "󰝟"
    elif [ "$vol" -ge 70 ]; then echo "󰕾"
    elif [ "$vol" -ge 30 ]; then echo "󰖀"
    elif [ "$vol" -gt 0 ]; then echo "󰕿"
    else echo "󰝟"; fi
}

toggle_mute() {
    pamixer -t
}

## BATTERY
get_battery_percent() {
    cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo "100"
}

get_battery_status() {
    cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo "Full"
}

get_battery_icon() {
    local percent=$(get_battery_percent)
    local status=$(get_battery_status)
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        if [ "$percent" -ge 90 ]; then echo "󰂅"
        elif [ "$percent" -ge 80 ]; then echo "󰂋"
        elif [ "$percent" -ge 60 ]; then echo "󰂊"
        elif [ "$percent" -ge 40 ]; then echo "󰢞"
        elif [ "$percent" -ge 20 ]; then echo "󰂆"
        else echo "󰢜"; fi
    else
        if [ "$percent" -ge 90 ]; then echo "󰁹"
        elif [ "$percent" -ge 80 ]; then echo "󰂂"
        elif [ "$percent" -ge 70 ]; then echo "󰂁"
        elif [ "$percent" -ge 60 ]; then echo "󰂀"
        elif [ "$percent" -ge 50 ]; then echo "󰁿"
        elif [ "$percent" -ge 40 ]; then echo "󰁾"
        elif [ "$percent" -ge 30 ]; then echo "󰁽"
        elif [ "$percent" -ge 20 ]; then echo "󰁼"
        elif [ "$percent" -ge 10 ]; then echo "󰁻"
        else echo "󰁺"; fi
    fi
}

get_all_json() {
    cat <<EOF
{
  "wifi": {
    "status": "$(get_wifi_status)",
    "icon": "$(get_wifi_icon)",
    "ssid": "$(get_wifi_ssid)"
  },
  "bluetooth": {
    "status": "$(get_bt_status)",
    "icon": "$(get_bt_icon)",
    "device": "$(get_bt_connected_device)"
  },
  "audio": {
    "volume": "$(get_volume)",
    "icon": "$(get_volume_icon)",
    "muted": $(is_muted)
  },
  "battery": {
    "percent": "$(get_battery_percent)",
    "icon": "$(get_battery_icon)",
    "status": "$(get_battery_status)"
  },
  "kb_layout": "$(get_kb_layout)"
}
EOF
}

case "$1" in
    --all) get_all_json ;;
    --toggle-mute) toggle_mute ;;
    *) echo "Unknown command: $1" ;;
esac
