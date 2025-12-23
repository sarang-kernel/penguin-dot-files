#!/bin/bash

# wallpaper-cycle-reverse.sh
# Reverse-cycle wallpapers with day/night/fallback support, caching, subfolders, and logging

# === Configuration ===
BASE_DIR="$HOME/Pictures/wallpapers"
DAY_DIR="$BASE_DIR/day"
NIGHT_DIR="$BASE_DIR/night"
CACHE_DIR="$HOME/.cache"
LOG_FILE="$CACHE_DIR/wallpaper_cycle.log"

DAY_LIST="$CACHE_DIR/wallpapers_day.list"
NIGHT_LIST="$CACHE_DIR/wallpapers_night.list"
ALL_LIST="$CACHE_DIR/wallpapers_all.list"

DAY_INDEX_FILE="$CACHE_DIR/wallpaper_index_day"
NIGHT_INDEX_FILE="$CACHE_DIR/wallpaper_index_night"
ALL_INDEX_FILE="$CACHE_DIR/wallpaper_index_all"

DAY_HASH_FILE="$CACHE_DIR/wallpapers_day.hash"
NIGHT_HASH_FILE="$CACHE_DIR/wallpapers_night.hash"
ALL_HASH_FILE="$CACHE_DIR/wallpapers_all.hash"

DAY_START=7
NIGHT_START=19

DEBUG=true  # Set to false to suppress terminal debug output

# === Logging ===
log() {
    echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
    $DEBUG && echo "[$(date '+%F %T')] $*"
}

# === Mode Detection ===
get_current_mode() {
    local hour
    hour=$(date +"%H")
    if (( hour >= DAY_START && hour < NIGHT_START )); then
        echo "day"
    else
        echo "night"
    fi
}

# === Update list if contents changed ===
update_wallpaper_list_if_changed() {
    local dir="$1"
    local list_file="$2"
    local hash_file="$3"

    if [[ ! -d "$dir" ]]; then
        log "Directory $dir does not exist. Skipping update."
        return 1
    fi

    local current_hash last_hash
    current_hash=$(find "$dir" -type f \( -iname "*.jpg" -o -iname "*.png" \) -printf '%P\n' | sort | sha256sum | awk '{print $1}')
    [[ -f "$hash_file" ]] && last_hash=$(<"$hash_file") || last_hash=""

    if [[ "$current_hash" != "$last_hash" ]]; then
        log "Changes detected in $dir. Refreshing wallpaper list."
        find "$dir" -type f \( -iname "*.jpg" -o -iname "*.png" \) > "$list_file"
        echo "$current_hash" > "$hash_file"
    else
        log "No change in $dir. Using cached wallpaper list."
    fi
}

# === Apply Previous Wallpaper ===
apply_previous_wallpaper() {
    local wallpapers=("$@")
    local index_file="$INDEX_FILE"

    [[ -f "$index_file" ]] && index=$(<"$index_file") || index=0
    local count=${#wallpapers[@]}
    [[ $count -eq 0 ]] && log "No wallpapers to apply. Exiting." && exit 1

    local prev_index=$(( (index - 1 + count) % count ))
    local prev_wallpaper="${wallpapers[$prev_index]}"

    log "Applying wallpaper [$prev_index]: $prev_wallpaper"
    swww img "$prev_wallpaper" --transition-type any --transition-duration 2

    echo "$prev_index" > "$index_file"
}

# === Main Execution ===

mkdir -p "$CACHE_DIR"

MODE=$(get_current_mode)

# Determine which set to use
if [[ -d "$DAY_DIR" && -d "$NIGHT_DIR" ]]; then
    if [[ "$MODE" == "day" ]]; then
        WALLPAPER_DIR="$DAY_DIR"
        LIST_FILE="$DAY_LIST"
        INDEX_FILE="$DAY_INDEX_FILE"
        HASH_FILE="$DAY_HASH_FILE"
    else
        WALLPAPER_DIR="$NIGHT_DIR"
        LIST_FILE="$NIGHT_LIST"
        INDEX_FILE="$NIGHT_INDEX_FILE"
        HASH_FILE="$NIGHT_HASH_FILE"
    fi
    log "Running in $MODE mode using: $WALLPAPER_DIR"
else
    WALLPAPER_DIR="$BASE_DIR"
    LIST_FILE="$ALL_LIST"
    INDEX_FILE="$ALL_INDEX_FILE"
    HASH_FILE="$ALL_HASH_FILE"
    log "Day/Night folders not found. Falling back to all wallpapers under: $WALLPAPER_DIR"
fi

update_wallpaper_list_if_changed "$WALLPAPER_DIR" "$LIST_FILE" "$HASH_FILE"

# Load wallpaper list
if [[ -f "$LIST_FILE" ]]; then
    mapfile -t WALLPAPERS < "$LIST_FILE"
else
    log "Wallpaper list file not found: $LIST_FILE"
    exit 1
fi

apply_previous_wallpaper "${WALLPAPERS[@]}"

