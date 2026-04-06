#!/usr/bin/env bash

# Paths
cache_dir="$HOME/.cache/quickshell/weather"
json_file="${cache_dir}/weather.json"

# Dubai Coordinates
LAT="25.2048"
LON="55.2708"

mkdir -p "${cache_dir}"

get_icon() {
    # Open-Meteo WMO Weather interpretation codes (WW)
    # https://open-meteo.com/en/docs
    case $1 in
        0) icon=""; quote="Clear sky"; hex="#f9e2af" ;;
        1|2|3) icon=""; quote="Mainly clear"; hex="#bac2de" ;;
        45|48) icon=""; quote="Fog"; hex="#84afdb" ;;
        51|53|55) icon=""; quote="Drizzle"; hex="#74c7ec" ;;
        61|63|65) icon=""; quote="Rain"; hex="#74c7ec" ;;
        71|73|75) icon=""; quote="Snow"; hex="#cdd6f4" ;;
        77) icon=""; quote="Snow grains"; hex="#cdd6f4" ;;
        80|81|82) icon=""; quote="Rain showers"; hex="#74c7ec" ;;
        85|86) icon=""; quote="Snow showers"; hex="#cdd6f4" ;;
        95|96|99) icon=""; quote="Thunderstorm"; hex="#f9e2af" ;;
        *) icon=""; quote="Cloudy"; hex="#bac2de" ;;
    esac
    echo "$icon|$quote|$hex"
}

get_data() {
    # Fetch data from Open-Meteo (No API key required)
    url="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,precipitation_probability_max&timezone=auto"
    
    raw_api=$(curl -sf "$url")
    if [ -z "$raw_api" ]; then return; fi

    final_json="["
    for i in {0..4}; do
        d_date=$(echo "$raw_api" | jq -r ".daily.time[$i]")
        f_day=$(date -d "$d_date" "+%a")
        f_full_day=$(date -d "$d_date" "+%A")
        f_date_num=$(date -d "$d_date" "+%d %b")
        
        w_code=$(echo "$raw_api" | jq -r ".daily.weather_code[$i]")
        icon_data=$(get_icon "$w_code")
        f_icon=$(echo "$icon_data" | cut -d'|' -f1)
        f_desc=$(echo "$icon_data" | cut -d'|' -f2)
        f_hex=$(echo "$icon_data" | cut -d'|' -f3)
        
        f_max=$(echo "$raw_api" | jq -r ".daily.temperature_2m_max[$i]")
        f_min=$(echo "$raw_api" | jq -r ".daily.temperature_2m_min[$i]")
        f_feels=$(echo "$raw_api" | jq -r ".daily.apparent_temperature_max[$i]")
        f_pop=$(echo "$raw_api" | jq -r ".daily.precipitation_probability_max[$i]")
        
        # We only have current wind/hum in this API's simple call, or we could map hourly.
        # For simplicity and to match your UI, we'll use current for today and 0 for others or just use current if it's index 0
        if [ $i -eq 0 ]; then
            f_wind=$(echo "$raw_api" | jq -r ".current.wind_speed_10m")
            f_hum=$(echo "$raw_api" | jq -r ".current.relative_humidity_2m")
        else
            f_wind="0"
            f_hum="0"
        fi

        # Hourly data (Next 8 slots starting from current hour if today, or start of day)
        hourly_json="["
        start_idx=$((i * 24))
        for j in {0..7}; do
            idx=$((start_idx + j * 3)) # Every 3 hours to fill the UI
            h_time_raw=$(echo "$raw_api" | jq -r ".hourly.time[$idx]")
            h_time=$(date -d "$h_time_raw" "+%H:%M")
            h_temp=$(echo "$raw_api" | jq -r ".hourly.temperature_2m[$idx]")
            h_code=$(echo "$raw_api" | jq -r ".hourly.weather_code[$idx]")
            h_icon_data=$(get_icon "$h_code")
            h_icon=$(echo "$h_icon_data" | cut -d'|' -f1)
            h_hex=$(echo "$h_icon_data" | cut -d'|' -f3)
            
            hourly_json="${hourly_json} {\"time\": \"${h_time}\", \"temp\": \"${h_temp}\", \"icon\": \"${h_icon}\", \"hex\": \"${h_hex}\"},"
        done
        hourly_json="${hourly_json%,}]"

        final_json="${final_json} {
            \"id\": \"${i}\",
            \"day\": \"${f_day}\",
            \"day_full\": \"${f_full_day}\",
            \"date\": \"${f_date_num}\",
            \"max\": \"${f_max}\",
            \"min\": \"${f_min}\",
            \"feels_like\": \"${f_feels}\",
            \"wind\": \"${f_wind}\",
            \"humidity\": \"${f_hum}\",
            \"pop\": \"${f_pop}\",
            \"icon\": \"${f_icon}\",
            \"hex\": \"${f_hex}\",
            \"desc\": \"${f_desc}\",
            \"hourly\": ${hourly_json}
        },"
    done
    final_json="${final_json%,}]"

    echo "{ \"forecast\": ${final_json} }" > "${json_file}"
}

# --- MODE HANDLING ---
if [[ "$1" == "--getdata" ]]; then
    get_data

elif [[ "$1" == "--json" ]]; then
    # Refresh every 15 minutes
    CACHE_LIMIT=900
    if [ -f "$json_file" ]; then
        file_time=$(stat -c %Y "$json_file")
        current_time=$(date +%s)
        diff=$((current_time - file_time))
        if [ $diff -gt $CACHE_LIMIT ]; then get_data & fi
        cat "$json_file"
    else
        get_data
        cat "$json_file"
    fi

elif [[ "$1" == "--icon" ]]; then
    cat "$json_file" | jq -r '.forecast[0].icon'

elif [[ "$1" == "--temp" ]]; then 
    t=$(cat "$json_file" | jq -r '.forecast[0].max')
    echo "${t}°C"

elif [[ "$1" == "--hex" ]]; then 
    cat "$json_file" | jq -r '.forecast[0].hex'

elif [[ "$1" == "--current-icon" ]]; then
    cat "$json_file" | jq -r '.forecast[0].icon'

elif [[ "$1" == "--current-temp" ]]; then 
    # Use actual current temp if available in cache or just max
    t=$(cat "$json_file" | jq -r '.forecast[0].max')
    echo "${t}°C"

elif [[ "$1" == "--current-hex" ]]; then
    cat "$json_file" | jq -r '.forecast[0].hex'
fi
