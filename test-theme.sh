#!/usr/bin/env bash
# ==============================================================================
# Prohori (প্রহরী) Local Theme Test Runner
# Test and preview any or all Prohori themes locally before installing.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESETS_DIR="${SCRIPT_DIR}/themes"
THEME_CONF="${SCRIPT_DIR}/theme.conf"

# ANSI Colors
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

# Locate SDDM greeter
if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    GREETER="sddm-greeter-qt6"
elif command -v sddm-greeter >/dev/null 2>&1; then
    GREETER="sddm-greeter"
else
    echo -e "${C_BRED}[ERROR]${C_RESET} Neither sddm-greeter-qt6 nor sddm-greeter was found in PATH." >&2
    echo "Please ensure SDDM (with Qt6) is installed." >&2
    exit 1
fi

THEMES=(
    "default|Prohori Classic|#38bdf8|Iconic orbital concentric chronometer dials on deep obsidian navy"
    "minimal|Prohori Minimal|#00f5a0|Architectural monolithic digital clock, kinetic seconds rail & floating auth dock"
)

get_current_theme_name() {
    if [[ -f "$THEME_CONF" ]]; then
        local name
        name=$(grep "^themeName=" "$THEME_CONF" | head -n 1 | cut -d'=' -f2- | tr -d '"\r')
        echo "${name:-Prohori Classic}"
    else
        echo "Prohori Classic"
    fi
}

print_header() {
    echo -e "${C_BCYAN}╔═══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BCYAN}║${C_RESET}   ${C_BOLD}PROHORI (প্রহরী) — LOCAL THEME TESTER${C_RESET}                                ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}║${C_RESET}   ${C_DIM}Preview all themes locally without touching system files${C_RESET}            ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

show_menu() {
    local cur_name
    cur_name=$(get_current_theme_name)
    echo -e "${C_BOLD}Select a theme to test in a live preview window:${C_RESET}"
    echo ""

    local idx=1
    for t in "${THEMES[@]}"; do
        IFS='|' read -r key name accent desc <<< "$t"
        if [[ "$cur_name" == "$name" ]]; then
            echo -e "  ${C_BGREEN}[${idx}] * ${name}${C_RESET} ${C_GRAY}(${key})${C_RESET} ${C_DIM}← CURRENT ACTIVE${C_RESET}"
        else
            echo -e "  ${C_BCYAN}[${idx}]${C_RESET}   ${C_BOLD}${name}${C_RESET} ${C_GRAY}(${key})${C_RESET}"
        fi
        echo -e "      ${C_GRAY}Accent:${C_RESET} ${accent}  ${C_GRAY}|${C_RESET}  ${C_DIM}${desc}${C_RESET}"
        ((idx++))
    done
    echo ""
    echo -e "  ${C_BYELLOW}[a]${C_RESET}   ${C_BOLD}Test All Themes in Sequence${C_RESET} ${C_DIM}(cycle through 1 by 1)${C_RESET}"
    echo -e "  ${C_BRED}[q]${C_RESET}   ${C_BOLD}Quit${C_RESET}"
    echo ""
}

resolve_preset_file() {
    local target="$1"
    # 1. Number match
    if [[ "$target" =~ ^[1-9]$ ]] && [ "$target" -le "${#THEMES[@]}" ]; then
        local entry="${THEMES[$((target - 1))]}"
        local key
        key=$(echo "$entry" | cut -d'|' -f1)
        echo "${PRESETS_DIR}/${key}.conf"
        return 0
    fi

    # 2. Key match
    if [[ -f "${PRESETS_DIR}/${target}.conf" ]]; then
        echo "${PRESETS_DIR}/${target}.conf"
        return 0
    fi

    # 3. Fuzzy match
    for t in "${THEMES[@]}"; do
        IFS='|' read -r key name accent desc <<< "$t"
        local lkey="${key,,}"
        local lname="${name,,}"
        local ltarget="${target,,}"
        if [[ "$lkey" == *"$ltarget"* || "$lname" == *"$ltarget"* ]]; then
            echo "${PRESETS_DIR}/${key}.conf"
            return 0
        fi
    done

    return 1
}

test_single_theme() {
    local input="$1"
    local preset_file
    preset_file=$(resolve_preset_file "$input") || {
        echo -e "${C_BRED}[ERROR]${C_RESET} Unknown theme: '${input}'" >&2
        return 1
    }

    local theme_name
    theme_name=$(grep "^themeName=" "$preset_file" | head -n 1 | cut -d'=' -f2- | tr -d '"\r')

    # Apply locally to theme.conf
    cp "$preset_file" "$THEME_CONF"

    echo ""
    echo -e "${C_BGREEN}▶ [TESTING]${C_RESET} Applied ${C_BOLD}${theme_name}${C_RESET} locally to ${C_GRAY}theme.conf${C_RESET}"
    echo -e "${C_BCYAN}→${C_RESET} Opening SDDM preview window... ${C_DIM}(close the window when finished)${C_RESET}"
    echo ""

    # Launch greeter in test mode
    "$GREETER" --test-mode --theme "$SCRIPT_DIR" || true

    echo ""
    echo -e "${C_GREEN}✓ Closed preview for ${C_BOLD}${theme_name}${C_RESET}."
}

cycle_all_themes() {
    echo ""
    echo -e "${C_BYELLOW}[CYCLE MODE]${C_RESET} You will preview all ${#THEMES[@]} themes in sequence."
    echo -e "Close each preview window (or press Alt+F4 / Ctrl+C) to advance to the next theme."
    echo ""

    local count=1
    for t in "${THEMES[@]}"; do
        IFS='|' read -r key name accent desc <<< "$t"
        echo -e "${C_BCYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_BOLD}[Theme ${count}/${#THEMES[@]}] ${name}${C_RESET} ${C_GRAY}(Accent: ${accent})${C_RESET}"
        echo -e "${C_DIM}${desc}${C_RESET}"
        echo -e "${C_BCYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

        test_single_theme "$key"

        if [ "$count" -lt "${#THEMES[@]}" ]; then
            echo -e -n "${C_BOLD}Press Enter for next theme (or 'q' to stop cycling): ${C_RESET}"
            read -r proceed
            if [[ "$proceed" =~ ^[qQ]$ ]]; then
                echo "Stopped theme cycle."
                break
            fi
        fi
        ((count++))
    done

    echo -e "\n${C_BGREEN}✓ Finished theme tour!${C_RESET}"
}

# If arguments passed directly, run test immediately
if [[ $# -gt 0 ]]; then
    arg="$1"
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        print_header
        echo "Usage: ./test-theme.sh [THEME_NAME_OR_NUMBER]"
        echo ""
        echo "Examples:"
        echo "  ./test-theme.sh                # Interactive menu loop"
        echo "  ./test-theme.sh minimal        # Test Prohori Minimal"
        echo "  ./test-theme.sh default        # Test Prohori Classic"
        echo "  ./test-theme.sh all            # Cycle through all themes"
        exit 0
    elif [[ "$arg" == "all" || "$arg" == "-a" || "$arg" == "--all" ]]; then
        cycle_all_themes
        exit 0
    else
        test_single_theme "$arg"
        exit 0
    fi
fi

# Interactive Loop
while true; do
    clear 2>/dev/null || echo ""
    print_header
    show_menu

    echo -e -n "${C_BOLD}Enter choice [1-${#THEMES[@]}, a, or q]: ${C_RESET}"
    read -r choice

    case "$choice" in
        [qQ]|"exit")
            echo -e "\n${C_GREEN}Exited theme tester.${C_RESET} Active local theme is: ${C_BOLD}$(get_current_theme_name)${C_RESET}\n"
            exit 0
            ;;
        [aA]|"all")
            cycle_all_themes
            echo -e -n "\n${C_DIM}Press Enter to return to menu...${C_RESET}"
            read -r
            ;;
        [1-9])
            if [ "$choice" -le "${#THEMES[@]}" ]; then
                test_single_theme "$choice"
                echo -e -n "\n${C_DIM}Press Enter to return to menu...${C_RESET}"
                read -r
            else
                echo -e "\n${C_BRED}[ERROR]${C_RESET} Invalid choice '${choice}'. Please select between 1 and ${#THEMES[@]}."
                sleep 1.2
            fi
            ;;
        *)
            if [[ -n "$choice" ]]; then
                if test_single_theme "$choice"; then
                    echo -e -n "\n${C_DIM}Press Enter to return to menu...${C_RESET}"
                    read -r
                else
                    sleep 1.5
                fi
            fi
            ;;
    esac
done
