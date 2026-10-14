#!/usr/bin/env bash
set -e

THEME_NAME="prohori"
INSTALL_DEST="/usr/share/sddm/themes/${THEME_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ANSI Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

SKIP_DEPS=false
CHECK_ONLY=false

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --no-deps|-n)
            SKIP_DEPS=true
            ;;
        --check|-c)
            CHECK_ONLY=true
            ;;
        --help|-h)
            echo -e "${BOLD}Usage:${RESET} ./install.sh [options]"
            echo ""
            echo "Options:"
            echo "  -n, --no-deps    Skip package manager dependency installation"
            echo "  -c, --check      Check dependencies without installing"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
    esac
done

echo -e "${BOLD}${CYAN}=== Prohori (প্রহরী) SDDM Theme Installer ===${RESET}\n"

# Helper for sudo / root elevation
elevate() {
    if [ "$EUID" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        elif command -v doas >/dev/null 2>&1; then
            doas "$@"
        else
            echo -e "${RED}[ERROR] Root privileges required, but neither sudo nor doas was found.${RESET}" >&2
            exit 1
        fi
    else
        "$@"
    fi
}

# 1. Dependency Manager Detection & Installation
install_dependencies() {
    echo -e "${BLUE}==>${RESET} Checking package manager and dependencies..."

    if command -v pacman >/dev/null 2>&1; then
        echo -e "Detected package manager: ${GREEN}pacman${RESET} (Arch Linux / CachyOS / EndeavourOS)"
        DEPS=("sddm" "qt6-declarative" "qt6-5compat" "qt6-svg")
        if [ "$CHECK_ONLY" = true ]; then
            pacman -Qi "${DEPS[@]}" >/dev/null 2>&1 && echo -e "${GREEN}[OK] All dependencies are installed.${RESET}" || echo -e "${YELLOW}[!] Some dependencies are missing: ${DEPS[*]}${RESET}"
            return 0
        fi
        if [ "$SKIP_DEPS" = false ]; then
            elevate pacman -S --needed --noconfirm "${DEPS[@]}"
        fi

    elif command -v apt-get >/dev/null 2>&1; then
        echo -e "Detected package manager: ${GREEN}apt${RESET} (Debian / Ubuntu / Mint / Pop!_OS)"
        DEPS=(
            "sddm"
            "qml6-module-qtquick"
            "qml6-module-qtquick-controls"
            "qml6-module-qtquick-layouts"
            "qml6-module-qt5compat-graphicaleffects"
            "qt6-declarative-dev"
        )
        if [ "$CHECK_ONLY" = true ]; then
            dpkg -s "${DEPS[@]}" >/dev/null 2>&1 && echo -e "${GREEN}[OK] All dependencies are installed.${RESET}" || echo -e "${YELLOW}[!] Some dependencies may be missing.${RESET}"
            return 0
        fi
        if [ "$SKIP_DEPS" = false ]; then
            elevate apt-get update -y
            elevate apt-get install -y "${DEPS[@]}"
        fi

    elif command -v dnf >/dev/null 2>&1; then
        echo -e "Detected package manager: ${GREEN}dnf${RESET} (Fedora / RHEL / Nobara)"
        DEPS=("sddm" "qt6-qtdeclarative" "qt6-qt5compat" "qt6-qtsvg")
        if [ "$CHECK_ONLY" = true ]; then
            rpm -q "${DEPS[@]}" >/dev/null 2>&1 && echo -e "${GREEN}[OK] All dependencies are installed.${RESET}" || echo -e "${YELLOW}[!] Some dependencies may be missing: ${DEPS[*]}${RESET}"
            return 0
        fi
        if [ "$SKIP_DEPS" = false ]; then
            elevate dnf install -y "${DEPS[@]}"
        fi

    elif command -v zypper >/dev/null 2>&1; then
        echo -e "Detected package manager: ${GREEN}zypper${RESET} (openSUSE Tumbleweed / Leap)"
        DEPS=("sddm" "qt6-declarative" "qt6-declarative-imports" "qt6-qt5compat" "qt6-svg")
        if [ "$CHECK_ONLY" = true ]; then
            rpm -q "${DEPS[@]}" >/dev/null 2>&1 && echo -e "${GREEN}[OK] All dependencies are installed.${RESET}" || echo -e "${YELLOW}[!] Some dependencies may be missing.${RESET}"
            return 0
        fi
        if [ "$SKIP_DEPS" = false ]; then
            elevate zypper --non-interactive in "${DEPS[@]}"
        fi

    elif command -v xbps-install >/dev/null 2>&1; then
        echo -e "Detected package manager: ${GREEN}xbps${RESET} (Void Linux)"
        DEPS=("sddm" "qt6-declarative" "qt6-5compat" "qt6-svg")
        if [ "$CHECK_ONLY" = true ]; then
            xbps-query -s "${DEPS[0]}" >/dev/null 2>&1 && echo -e "${GREEN}[OK] Dependencies checked.${RESET}"
            return 0
        fi
        if [ "$SKIP_DEPS" = false ]; then
            elevate xbps-install -y "${DEPS[@]}"
        fi

    elif command -v apk >/dev/null 2>&1; then
        echo -e "Detected package manager: ${GREEN}apk${RESET} (Alpine Linux)"
        DEPS=("sddm" "qt6-qtdeclarative" "qt6-qt5compat" "qt6-qtsvg")
        if [ "$CHECK_ONLY" = true ]; then
            apk info -e "${DEPS[@]}" >/dev/null 2>&1 && echo -e "${GREEN}[OK] All dependencies are installed.${RESET}"
            return 0
        fi
        if [ "$SKIP_DEPS" = false ]; then
            elevate apk add "${DEPS[@]}"
        fi

    else
        echo -e "${YELLOW}[WARNING] Could not identify a supported package manager.${RESET}"
        echo -e "Please ensure ${BOLD}sddm, qt6-declarative, and qt6-5compat${RESET} are installed manually."
    fi
}

install_dependencies

if [ "$CHECK_ONLY" = true ]; then
    echo -e "\n${GREEN}[CHECK COMPLETE]${RESET} Exiting."
    exit 0
fi

# 2. Theme Copy & Installation
echo -e "\n${BLUE}==>${RESET} Copying theme files to ${BOLD}${INSTALL_DEST}${RESET}..."
elevate mkdir -p "$INSTALL_DEST"
elevate cp -rf "${SCRIPT_DIR}/"* "$INSTALL_DEST/"

# Copy fonts system-wide so desktop apps can also use them
if [ -d "${SCRIPT_DIR}/fonts" ]; then
    echo -e "${BLUE}==>${RESET} Installing bundled Outfit fonts to ${BOLD}/usr/share/fonts/prohori${RESET}..."
    elevate mkdir -p /usr/share/fonts/prohori
    elevate cp -rf "${SCRIPT_DIR}/fonts/"*.ttf /usr/share/fonts/prohori/
    if command -v fc-cache >/dev/null 2>&1; then
        elevate fc-cache -f /usr/share/fonts/prohori >/dev/null 2>&1 || true
    fi
fi

# Ensure correct permissions
elevate chmod -R 755 "$INSTALL_DEST"

# 3. Configure SDDM
echo -e "${BLUE}==>${RESET} Setting Prohori as default theme in SDDM configuration..."

# Modern SDDM Drop-in directory (/etc/sddm.conf.d/)
elevate mkdir -p /etc/sddm.conf.d
cat <<EOF | elevate tee /etc/sddm.conf.d/theme.conf >/dev/null
[Theme]
Current=${THEME_NAME}

[General]
InputMethod=
EOF

cat <<EOF | elevate tee /etc/sddm.conf.d/theme.conf.user >/dev/null
[Theme]
Current=${THEME_NAME}

[General]
InputMethod=
EOF

# Ensure virtual keyboard does not automatically pop up from separate drop-ins
if [ -f /etc/sddm.conf.d/virtualkbd.conf ]; then
    echo -e "${BLUE}==>${RESET} Disabling default virtual keyboard in /etc/sddm.conf.d/virtualkbd.conf..."
    elevate sed -i 's/^InputMethod=.*/InputMethod=/' /etc/sddm.conf.d/virtualkbd.conf 2>/dev/null || true
fi

# Ensure highest drop-in priority prevents virtual keyboard from opening by default
cat <<EOF | elevate tee /etc/sddm.conf.d/zz-prohori-virtualkbd.conf >/dev/null
[General]
InputMethod=
EOF

# Legacy fallback (/etc/sddm.conf) if it exists
if [ -f /etc/sddm.conf ]; then
    elevate cp -f /etc/sddm.conf /etc/sddm.conf.bak."$(date +%s)"
    if grep -q "^\[Theme\]" /etc/sddm.conf; then
        if grep -q "^Current=" /etc/sddm.conf; then
            elevate sed -i "s/^Current=.*/Current=${THEME_NAME}/" /etc/sddm.conf
        else
            elevate sed -i "/^\[Theme\]/a Current=${THEME_NAME}" /etc/sddm.conf
        fi
    else
        echo -e "\n[Theme]\nCurrent=${THEME_NAME}" | elevate tee -a /etc/sddm.conf >/dev/null
    fi

    if grep -q "^\[General\]" /etc/sddm.conf; then
        if grep -q "^InputMethod=" /etc/sddm.conf; then
            elevate sed -i "s/^InputMethod=.*/InputMethod=/" /etc/sddm.conf
        else
            elevate sed -i "/^\[General\]/a InputMethod=" /etc/sddm.conf
        fi
    fi
fi

# Install prohori-theme command to /usr/local/bin for convenient CLI access
if [ -f "${INSTALL_DEST}/switch-theme.sh" ]; then
    echo -e "${BLUE}==>${RESET} Installing theme switcher CLI tool to ${BOLD}/usr/local/bin/prohori-theme${RESET}..."
    elevate ln -sf "${INSTALL_DEST}/switch-theme.sh" /usr/local/bin/prohori-theme 2>/dev/null || true
fi

echo -e "\n${GREEN}${BOLD}✓ [SUCCESS] Prohori SDDM theme installed and activated!${RESET}"
echo -e "Theme Location: ${CYAN}${INSTALL_DEST}${RESET}"
echo -e "To switch themes anytime: ${CYAN}prohori-theme${RESET} (or ${CYAN}${SCRIPT_DIR}/switch-theme.sh${RESET})"
echo -e "To test anytime: ${CYAN}${SCRIPT_DIR}/test.sh${RESET}\n"
