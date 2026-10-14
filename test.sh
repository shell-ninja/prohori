#!/usr/bin/env bash
set -e

# Resolve symlinks so the script works from any invocation path
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_SOURCE" ]; do
    _TMP_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
    SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
    [[ "$SCRIPT_SOURCE" != /* ]] && SCRIPT_SOURCE="$_TMP_DIR/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
PRESETS_DIR="${SCRIPT_DIR}/themes"
THEME_CONF="${SCRIPT_DIR}/theme.conf"


# Check for sddm greeter
if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    GREETER="sddm-greeter-qt6"
elif command -v sddm-greeter >/dev/null 2>&1; then
    GREETER="sddm-greeter"
else
    echo "[ERROR] Neither sddm-greeter-qt6 nor sddm-greeter was found in PATH." >&2
    exit 1
fi

# If a theme preset is specified, apply it first
if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
    THEME_ARG="$1"
    shift
    PRESET_FILE=""

    if [[ -f "${PRESETS_DIR}/${THEME_ARG}.conf" ]]; then
        PRESET_FILE="${PRESETS_DIR}/${THEME_ARG}.conf"
    else
        # Fuzzy match
        for f in "${PRESETS_DIR}"/*.conf; do
            base="$(basename "$f" .conf)"
            if [[ "${base,,}" == *"${THEME_ARG,,}"* ]]; then
                PRESET_FILE="$f"
                break
            fi
        done
    fi

    if [[ -n "$PRESET_FILE" && -f "$PRESET_FILE" ]]; then
        cp "$PRESET_FILE" "$THEME_CONF"
        THEME_NAME=$(grep "^themeName=" "$THEME_CONF" | head -n 1 | cut -d'=' -f2- | tr -d '"\r')
        echo -e "\033[0;32m[Applied Preset]\033[0m: ${THEME_NAME:-$THEME_ARG}"
    else
        echo -e "\033[0;33m[Notice]\033[0m: Unknown preset '${THEME_ARG}', running with current theme.conf"
    fi
fi

CURRENT_THEME=$(grep "^themeName=" "$THEME_CONF" 2>/dev/null | head -n 1 | cut -d'=' -f2- | tr -d '"\r' || echo "Prohori")
echo -e "\033[0;32m[Previewing SDDM Theme]\033[0m: ${CURRENT_THEME} (${SCRIPT_DIR})"
echo "Using greeter: ${GREETER}"

# Run greeter in test mode
"$GREETER" --test-mode --theme "$SCRIPT_DIR" "$@"
