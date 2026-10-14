#!/usr/bin/env bash
# ==============================================================================
# Prohori (প্রহরী) SDDM Theme Switcher
# Switch between handcrafted aesthetic presets or apply custom configurations.
# ==============================================================================

set -e

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESETS_DIR="${THEME_DIR}/themes"
THEME_CONF="${THEME_DIR}/theme.conf"
SYSTEM_THEME_DIR="/usr/share/sddm/themes/prohori"

# Terminal Color Palette
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_CYAN="\033[0;36m"
C_BCYAN="\033[1;36m"
C_GREEN="\033[0;32m"
C_BGREEN="\033[1;32m"
C_YELLOW="\033[0;33m"
C_BYELLOW="\033[1;33m"
C_BLUE="\033[0;34m"
C_BBLUE="\033[1;34m"
C_PURPLE="\033[0;35m"
C_BPURPLE="\033[1;35m"
C_RED="\033[0;31m"
C_BRED="\033[1;31m"
C_GRAY="\033[0;90m"

print_banner() {
    cat << "EOF"
  ____  ____   ___  _   _  ___  ____  ___
 |  _ \|  _ \ / _ \| | | |/ _ \|  _ \|_ _|
 | |_) | |_) | | | | |_| | | | | |_) || | 
 |  __/|  _ <| |_| |  _  | |_| |  _ < | | 
 |_|   |_| \_\\___/|_| |_|\___/|_| \_\___|
  PRESET THEME SWITCHER // SENTINEL OS
EOF
    echo ""
}

# Theme definitions: key|Display Name|Accent Color|Description
THEMES=(
    "default|Prohori Classic|#38bdf8|Iconic orbital concentric chronometer dials on deep obsidian navy"
    "minimal|Prohori Minimal|#00f5a0|Architectural monolithic digital clock, live kinetic millisecond sweep & floating auth dock"
)

# Helper to extract value from theme.conf
get_conf_value() {
    local file="$1"
    local key="$2"
    if [[ -f "$file" ]]; then
        grep "^${key}=" "$file" | head -n 1 | cut -d'=' -f2- | tr -d '"\r'
    fi
}

get_current_theme_name() {
    local name
    name=$(get_conf_value "$THEME_CONF" "themeName")
    if [[ -z "$name" ]]; then
        name="Prohori Classic"
    fi
    echo "$name"
}

list_themes() {
    echo -e "${C_BOLD}Available Prohori Theme Presets:${C_RESET}"
    echo ""
    local idx=1
    for t in "${THEMES[@]}"; do
        IFS='|' read -r key name accent desc <<< "$t"
        local marker=" "
        if [[ "$(get_current_theme_name)" == "$name" ]]; then
            marker="*"
            echo -e "  ${C_BGREEN}[${idx}] ${marker} ${name}${C_RESET} ${C_GRAY}(${key})${C_RESET} ${C_DIM}— CURRENT ACTIVE${C_RESET}"
        else
            echo -e "  ${C_BCYAN}[${idx}]${C_RESET}   ${C_BOLD}${name}${C_RESET} ${C_GRAY}(${key})${C_RESET}"
        fi
        echo -e "      ${C_GRAY}Accent:${C_RESET} ${accent}  ${C_GRAY}|${C_RESET}  ${C_DIM}${desc}${C_RESET}"
        echo ""
        ((idx++))
    done
}

show_current() {
    local cur_name cur_mode cur_bg cur_accent cur_fmt
    cur_name=$(get_conf_value "$THEME_CONF" "themeName")
    cur_mode=$(get_conf_value "$THEME_CONF" "themeMode")
    cur_bg=$(get_conf_value "$THEME_CONF" "background")
    cur_accent=$(get_conf_value "$THEME_CONF" "accentColor")
    cur_fmt=$(get_conf_value "$THEME_CONF" "hourFormat")

    echo -e "${C_BOLD}Current Prohori Theme Configuration:${C_RESET}"
    echo -e "  ${C_BCYAN}Theme Name:${C_RESET}    ${cur_name:-Prohori Classic}"
    echo -e "  ${C_BCYAN}Mode:${C_RESET}          ${cur_mode:-dark}"
    echo -e "  ${C_BCYAN}Accent Color:${C_RESET}  ${cur_accent:-#38bdf8}"
    echo -e "  ${C_BCYAN}Time Format:${C_RESET}   ${cur_fmt:-12} Hour"
    echo -e "  ${C_BCYAN}Background:${C_RESET}    ${cur_bg:-None (Pure Canvas)}"
    echo -e "  ${C_BCYAN}Config Path:${C_RESET}   ${THEME_CONF}"
}

apply_preset() {
    local target="$1"
    local do_system="$2"
    local preset_file=""

    # 1. Exact match by key
    if [[ -f "${PRESETS_DIR}/${target}.conf" ]]; then
        preset_file="${PRESETS_DIR}/${target}.conf"
    # 2. Number match
    elif [[ "$target" =~ ^[1-9]$ ]] && [ "$target" -le "${#THEMES[@]}" ]; then
        local entry="${THEMES[$((target - 1))]}"
        local key
        key=$(echo "$entry" | cut -d'|' -f1)
        preset_file="${PRESETS_DIR}/${key}.conf"
    # 3. Fuzzy search in preset names or keys
    else
        for t in "${THEMES[@]}"; do
            IFS='|' read -r key name accent desc <<< "$t"
            local lkey="${key,,}"
            local lname="${name,,}"
            local ltarget="${target,,}"
            if [[ "$lkey" == *"$ltarget"* || "$lname" == *"$ltarget"* ]]; then
                preset_file="${PRESETS_DIR}/${key}.conf"
                break
            fi
        done
    fi

    if [[ -z "$preset_file" || ! -f "$preset_file" ]]; then
        echo -e "${C_BRED}[ERROR]${C_RESET} Unknown theme preset: '${target}'" >&2
        echo -e "Run ${C_CYAN}./switch-theme.sh --list${C_RESET} to view available presets." >&2
        return 1
    fi

    # Read applied theme name
    local applied_name
    applied_name=$(get_conf_value "$preset_file" "themeName")

    # Copy preset to local theme.conf
    cp "$preset_file" "$THEME_CONF"
    echo -e "${C_BGREEN}[SUCCESS]${C_RESET} Applied theme: ${C_BOLD}${applied_name}${C_RESET}"
    echo -e "Configuration written to: ${C_GRAY}${THEME_CONF}${C_RESET}"

    # Sync to system if explicitly requested
    if [[ "$do_system" == "true" || "$do_system" == "1" ]]; then
        sync_to_system
    fi

    return 0
}

sync_to_system() {
    if [[ ! -d "$SYSTEM_THEME_DIR" ]]; then
        echo -e "${C_YELLOW}[INFO]${C_RESET} System theme directory ${SYSTEM_THEME_DIR} not found. Theme is only active locally."
        return 0
    fi

    echo -e "${C_BCYAN}[SYNC]${C_RESET} Syncing theme configuration and assets to ${SYSTEM_THEME_DIR}..."
    if [[ $EUID -eq 0 ]]; then
        cp "$THEME_CONF" "${SYSTEM_THEME_DIR}/theme.conf"
        cp -r "${THEME_DIR}/backgrounds" "${SYSTEM_THEME_DIR}/"
        cp -r "${THEME_DIR}/themes" "${SYSTEM_THEME_DIR}/"
        cp "${THEME_DIR}/Main.qml" "${SYSTEM_THEME_DIR}/Main.qml"
        chmod 644 "${SYSTEM_THEME_DIR}/theme.conf"
    else
        sudo cp "$THEME_CONF" "${SYSTEM_THEME_DIR}/theme.conf"
        sudo cp -r "${THEME_DIR}/backgrounds" "${SYSTEM_THEME_DIR}/"
        sudo cp -r "${THEME_DIR}/themes" "${SYSTEM_THEME_DIR}/"
        sudo cp "${THEME_DIR}/Main.qml" "${SYSTEM_THEME_DIR}/Main.qml"
        sudo chmod 644 "${SYSTEM_THEME_DIR}/theme.conf"
    fi
    echo -e "${C_BGREEN}[SUCCESS]${C_RESET} System-wide SDDM theme updated successfully!"
}

set_custom_wallpaper() {
    local wp_path="$1"
    if [[ ! -f "$wp_path" ]]; then
        echo -e "${C_BRED}[ERROR]${C_RESET} Wallpaper file not found: '${wp_path}'" >&2
        return 1
    fi

    # Read absolute path
    local abs_path
    abs_path="$(cd "$(dirname "$wp_path")" && pwd)/$(basename "$wp_path")"

    if grep -q "^background=" "$THEME_CONF"; then
        sed -i "s|^background=.*|background=\"${abs_path}\"|" "$THEME_CONF"
    else
        echo "background=\"${abs_path}\"" >> "$THEME_CONF"
    fi

    echo -e "${C_BGREEN}[SUCCESS]${C_RESET} Set wallpaper to: ${C_BOLD}${abs_path}${C_RESET}"
}

run_test() {
    echo ""
    echo -e "${C_BCYAN}[PREVIEW]${C_RESET} Launching SDDM greeter in test mode..."
    "${THEME_DIR}/test.sh"
}

# Interactive Menu
interactive_menu() {
    print_banner
    list_themes

    local count="${#THEMES[@]}"
    local choice
    echo -e -n "${C_BOLD}Select a theme [1-${count}] (or 'q' to quit): ${C_RESET}"
    read -r choice

    if [[ "$choice" =~ ^[qQ]$ || -z "$choice" ]]; then
        echo "Exiting without changes."
        exit 0
    fi

    if apply_preset "$choice" "false"; then
        echo ""
        echo -e -n "${C_BOLD}Would you like to test preview this theme now? [Y/n]: ${C_RESET}"
        read -r test_choice
        if [[ "$test_choice" =~ ^[yY]$ || -z "$test_choice" ]]; then
            run_test
        fi
    fi
}

# Command Line Parsing
DO_SYSTEM=false
DO_TEST=false
TARGET_THEME=""
CUSTOM_WP=""

if [[ $# -eq 0 ]]; then
    interactive_menu
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo
            print_banner
            echo "Usage: ./switch-theme.sh [OPTIONS] [THEME_NAME]"
            echo ""
            echo "Options:"
            echo "  -l, --list             List all available theme presets"
            echo "  -c, --current          Show current active theme details"
            echo "  -t, --test             Launch live test mode preview"
            echo "  -s, --system, --sync   Sync theme to /usr/share/sddm/themes/prohori"
            echo "  -w, --wallpaper <path> Set a custom wallpaper image"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./switch-theme.sh                   # Interactive selection menu"
            echo "  ./switch-theme.sh minimal           # Switch to Prohori Minimal theme"
            echo "  ./switch-theme.sh default --test    # Switch to Prohori Classic and preview"
            echo "  ./switch-theme.sh minimal -s        # Switch to Minimal and sync system"
            echo "  ./switch-theme.sh --wallpaper ~/wall.png"
            exit 0
            ;;
        -l|--list)
            print_banner
            list_themes
            exit 0
            ;;
        -c|--current)
            show_current
            exit 0
            ;;
        -t|--test)
            DO_TEST=true
            shift
            ;;
        -s|--system|--sync)
            DO_SYSTEM=true
            shift
            ;;
        -w|--wallpaper)
            shift
            CUSTOM_WP="$1"
            shift
            ;;
        *)
            TARGET_THEME="$1"
            shift
            ;;
    esac
done

if [[ -n "$CUSTOM_WP" ]]; then
    set_custom_wallpaper "$CUSTOM_WP"
fi

if [[ -n "$TARGET_THEME" ]]; then
    apply_preset "$TARGET_THEME" "$DO_SYSTEM"
elif [[ "$DO_SYSTEM" == "true" && -z "$TARGET_THEME" && -z "$CUSTOM_WP" ]]; then
    sync_to_system
fi

if [[ "$DO_TEST" == "true" ]]; then
    run_test
fi
