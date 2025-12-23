#!/bin/bash

# wallpaper-cycle.sh
# Wallpaper cycling script for Hyprland with day/night support, subfolder recursion, smart cache, and logging

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

DEBUG=true  # Set to false to disable terminal debug output

# === Logging Function ===
log() {
    echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
    $DEBUG && echo "[$(date '+%F %T')] $*"
}

# === Determine Mode (day/night) ===
get_current_mode() {
    local hour
    hour=$(date +"%H")
    if (( hour >= DAY_START && hour < NIGHT_START )); then
        echo "day"
    else
        echo "night"
    fi
}

# === Update wallpaper list if directory content changed ===
update_wallpaper_list_if_changed() {
    local dir="$1"
    local list_file="$2"
    local hash_file="$3"

    if [[ ! -d "$dir" ]]; then
        log "Directory $dir does not exist. Skipping."
        return 1
    fi

    local current_hash last_hash
    current_hash=$(find "$dir" -type f \( -iname "*.jpg" -o -iname "*.png" \) -printf '%P\n' | sort | sha256sum | awk '{print $1}')
    [[ -f "$hash_file" ]] && last_hash=$(<"$hash_file") || last_hash=""

    if [[ "$current_hash" != "$last_hash" ]]; then
        log "Changes detected in $dir. Updating wallpaper list."
        find "$dir" -type f \( -iname "*.jpg" -o -iname "*.png" \) > "$list_file"
        echo "$current_hash" > "$hash_file"
    else
        log "No change in $dir. Using cached wallpaper list."
    fi
}

# === Apply Next Wallpaper ===
apply_wallpaper() {
    local wallpapers=("$@")
    local index_file="$INDEX_FILE"

    [[ -f "$index_file" ]] && index=$(<"$index_file") || index=0
    local count=${#wallpapers[@]}
    [[ $count -eq 0 ]] && log "No wallpapers found to apply. Exiting." && exit 1

    local next_index=$(( (index + 1) % count ))
    local next_wallpaper="${wallpapers[$next_index]}"

    log "Applying wallpaper [$next_index]: $next_wallpaper"
    swww img "$next_wallpaper" --transition-type any --transition-duration 2

    echo "$next_index" > "$index_file"
}

# === Main Execution ===

mkdir -p "$CACHE_DIR"

MODE=$(get_current_mode)

# Determine target based on mode and folder existence
if [[ -d "$DAY_DIR" && -d "$NIGHT_DIR" ]]; then
    # Use day/night logic
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
    # Fallback to all wallpapers
    WALLPAPER_DIR="$BASE_DIR"
    LIST_FILE="$ALL_LIST"
    INDEX_FILE="$ALL_INDEX_FILE"
    HASH_FILE="$ALL_HASH_FILE"
    log "Day/Night folders not found. Falling back to all wallpapers under: $WALLPAPER_DIR"
fi

# Update list if changed
update_wallpaper_list_if_changed "$WALLPAPER_DIR" "$LIST_FILE" "$HASH_FILE"

# Load wallpapers from list
if [[ -f "$LIST_FILE" ]]; then
    mapfile -t WALLPAPERS < "$LIST_FILE"
else
    log "Wallpaper list file not found: $LIST_FILE"
    exit 1
fi

apply_wallpaper "${WALLPAPERS[@]}"

