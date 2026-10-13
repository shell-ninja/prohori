#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for sddm greeter
if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    GREETER="sddm-greeter-qt6"
elif command -v sddm-greeter >/dev/null 2>&1; then
    GREETER="sddm-greeter"
else
    echo "[ERROR] Neither sddm-greeter-qt6 nor sddm-greeter was found in PATH." >&2
    exit 1
fi

echo -e "\033[0;32m[Previewing SDDM Theme]\033[0m: ${SCRIPT_DIR}"
echo "Using greeter: ${GREETER}"

# Run greeter in test mode
"$GREETER" --test-mode --theme "$SCRIPT_DIR" "$@"
