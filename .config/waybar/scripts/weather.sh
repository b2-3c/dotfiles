LAT="X.YY"
LON="Y.XX"

TIMEOUT=5

FALLBACK_TEMP="N/A"
FALLBACK_TIP="Weather Data Unavailable. Click to refresh."

deg_to_compass() {
    local deg=$1
    if ! [[ "$deg" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo ""
        return
    fi

    local points=(N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW)

    local index
    index=$(awk "BEGIN { printf \"%d\", ((($deg / 22.5) + 0.5)) % 16 }")

    echo "${points[$index]}"
}


WEATHER_URL="https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m&forecast_days=1&temperature_unit=celsius&wind_speed_unit=kmh&timezone=auto"
WEATHER_JSON=$(curl -s --connect-timeout $TIMEOUT "$WEATHER_URL")

if [ -z "$WEATHER_JSON" ] || ! echo "$WEATHER_JSON" | jq -e '.current' >/dev/null 2>&1; then
    echo "{\"text\":\"•$FALLBACK_TEMP°C\",\"tooltip\":\"$FALLBACK_TIP\"}"
    exit 1
fi

TEMP=$(echo "$WEATHER_JSON" | jq -r '.current.temperature_2m')
FEELS=$(echo "$WEATHER_JSON" | jq -r '.current.apparent_temperature')
WIND=$(echo "$WEATHER_JSON" | jq -r '.current.wind_speed_10m')
WIND_DIR_DEG=$(echo "$WEATHER_JSON" | jq -r '.current.wind_direction_10m')
HUMID=$(echo "$WEATHER_JSON" | jq -r '.current.relative_humidity_2m')

WINDDIR=$(deg_to_compass "$WIND_DIR_DEG")


SUN_URL="https://api.sunrise-sunset.org/json?lat=$LAT&lng=$LON&formatted=0"
SUN_JSON=$(curl -s --connect-timeout $TIMEOUT "$SUN_URL")


if [ -z "$SUN_JSON" ] || ! echo "$SUN_JSON" | jq -e '.results' >/dev/null 2>&1; then
    SUNRISE="N/A"
    SUNSET="N/A"
else
    SUNRISE_UTC=$(echo "$SUN_JSON" | jq -r '.results.sunrise')
    SUNSET_UTC=$(echo "$SUN_JSON" | jq -r '.results.sunset')

    SUNRISE=$(date -d "$SUNRISE_UTC" +%H:%M 2>/dev/null || echo "N/A")
    SUNSET=$(date -d "$SUNSET_UTC" +%H:%M 2>/dev/null || echo "N/A")
fi


TEMP=${TEMP:-$FALLBACK_TEMP}
FEELS=${FEELS:-$FALLBACK_TEMP}
WIND=${WIND:-"N/A"}
WINDDIR=${WINDDIR:-""} 
HUMID=${HUMID:-"N/A"}

echo "{\"text\":\"✦$TEMP°C\",\"tooltip\":\"Feels like: $FEELS°C\nWind: $WINDDIR $WIND km/h\nHumidity: $HUMID%\nSunrise: $SUNRISE\nSunset: $SUNSET\"}"