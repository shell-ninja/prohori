# Prohori (প্রহরী) — SDDM Theme

A minimalist, high-performance, and futuristic SDDM Qt6 theme designed with rotating concentric dials, clean typography, and zero visual clutter.

---

## Previews

### Main Lockscreen View
![Prohori Main View](screenshots/main.png)

### System Dashboard Flyout
![Prohori Dashboard View](screenshots/dashboard.png)

---

## About the Name

**Prohori** (প্রহরী, pronounced *pro-ho-ri*) is a Bangla word with dual significance:

- **Prohor (প্রহর)**: An ancient unit of time in Bengal denoting the watches of the day and night.
- **Prohori (প্রহরী)**: The **Sentinel, Sentry, or Gatekeeper** who guards access to a stronghold and authorizes entry.

Together, it represents a timepiece that acts as the vigilant gatekeeper to your desktop.

---

## Inspiration & Credits

This theme was inspired by the **Ryoku** lockscreen and login environment design. Special thanks to the Ryoku ecosystem and the Linux ricing community for the original dial clockwork layout concept.

---

## Features

- **Orbital Dial Clock**:
  - Live rotating concentric tracks for minutes and seconds with dynamic spotlight illumination.
  - Symmetrical indicator capsule pill featuring accent-illuminated alignment ticks and a center divider.
  - Concentric circular chronometer guide tracks framing the orbital dial.
  - Large bold hour counter with integrated `AM` / `PM` / `24H` micro-badge.
  - Clean uppercase date and day-of-week display.
- **Dynamic Atmospheric Lighting**:
  - Ambient radial backlight behind the clock dynamically tinted to match each theme's accent color.
  - Contrast dimmer layer ensuring maximum legibility across custom wallpapers.
- **Preset System & Theme Switcher**:
  - 9 handcrafted presets for popular desktop rice aesthetics (Cyberpunk, Nord, Catppuccin, Tokyo Night, Matrix Emerald, Blood Moon, OLED Stealth, Amber Horizon, Prohori Classic).
  - CLI and interactive switcher script (`./switch-theme.sh` / `prohori-theme`).
- **Display & Hardware Optimization**:
  - **All Resolutions**: Proportional dynamic scaling that fits cleanly across 720p, 1080p, 2K (1440p), 4K (2160p), 16:10 laptop screens, and 21:9 ultrawide monitors without clipping.
  - **High Refresh Rate Sync**: Powered by Qt's native `FrameAnimation` synchronized directly with your display's VSync loop (60Hz, 75Hz, 120Hz, 144Hz, 165Hz, 240Hz+).
- **Minimalist Top Navigation**:
  - Session selector with dropdown menu and native support for `HYPRLAND (UWSM)`, standard Hyprland, KDE Plasma, GNOME, Sway, and Niri.
  - Direct Reboot and Shutdown controls wired into SDDM.
- **Bottom-Right Login Form**:
  - Username display with multi-user dropdown support (auto-detects and prioritizes the primary user).
  - Clean bullet-masked (`•`) password input with vertical pulsing needle cursor.
  - Customizable security subtitle and prompt labels.
  - Smooth login transition with shake animation and `ACCESS DENIED` feedback on invalid attempts.
  - Suppressed virtual keyboard popup by default (preserves dial clock visuals without overlay obstructions).
- **System Dashboard (`>_`)**:
  - Corner badge toggling a quick flyout drawer displaying system hostname, session type, active theme name, and a live 12h / 24h toggle.
- **Zero External Font Dependencies**:
  - Bundled typography (`Outfit` static weights: Regular, Medium, SemiBold, Bold, and Black) in `fonts/`.
  - Curated minimalist wallpapers included in `backgrounds/`.

---

## Dependencies & Prerequisites

Prohori is built for **SDDM with Qt 6** (`sddm-greeter-qt6`). The installation script handles dependency installation automatically, or you can install them manually using your distribution's package manager:

### Arch Linux / CachyOS / EndeavourOS
```bash
sudo pacman -S --needed sddm qt6-declarative qt6-5compat qt6-svg
```

### Debian / Ubuntu / Linux Mint / Pop!_OS
```bash
sudo apt update
sudo apt install -y sddm qml6-module-qtquick qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts qml6-module-qt5compat-graphicaleffects qt6-declarative-dev
```

### Fedora / RHEL / Nobara
```bash
sudo dnf install -y sddm qt6-qtdeclarative qt6-qt5compat qt6-qtsvg
```

### openSUSE (Tumbleweed / Leap)
```bash
sudo zypper in sddm qt6-declarative qt6-declarative-imports qt6-qt5compat qt6-svg
```

### Void Linux
```bash
sudo xbps-install -S sddm qt6-declarative qt6-5compat qt6-svg
```

### Alpine Linux
```bash
sudo apk add sddm qt6-qtdeclarative qt6-qt5compat qt6-qtsvg
```

---

## Installation

### Automated Install (Recommended)
The included `install.sh` script automatically detects your Linux distribution, installs any missing packages, installs the theme to `/usr/share/sddm/themes/prohori`, installs the bundled fonts system-wide, and activates the theme in `/etc/sddm.conf.d/theme.conf`.

```bash
chmod +x install.sh
./install.sh
```

#### Installer Flags
- **`./install.sh`**: Automatic detection, dependency install, theme install, and SDDM activation.
- **`./install.sh --check`**: Check if all dependencies are satisfied without making changes.
- **`./install.sh --no-deps`**: Skip package manager checks and only copy/activate the theme.

---

## Testing / Live Preview

To test and interact with the theme in a preview window without logging out or rebooting:

```bash
./test.sh
```

---

## Handcrafted Theme Presets

Prohori comes bundled with 2 curated theme presets in `themes/`:

| Preset Key | Theme Name | Accent | Mood & Aesthetic |
| :--- | :--- | :--- | :--- |
| `minimal` | **Prohori Minimal** | `#00f5a0` | Architectural monolithic digital clock, kinetic seconds sweep, floating auth dock & deep emerald mint ambient aura (`backgrounds/minimal.jpg`) |
| `default` | **Prohori Classic** | `#38bdf8` | Iconic orbital concentric chronometer dials on deep obsidian navy (`backgrounds/default.jpg`) |

---

## Switching Themes (`switch-theme.sh`)

You can switch themes interactively or via CLI commands using `./switch-theme.sh` (or `prohori-theme` once installed):

### 1. Interactive Menu
Simply run the script with no arguments to launch the interactive terminal menu:
```bash
./switch-theme.sh
```
Shows all themes with active indicators, lets you pick by number or name, and offers to launch a live test preview immediately.

### 2. Direct Switching via CLI
```bash
# Switch to Prohori Minimal (Modern architectural layout)
./switch-theme.sh minimal

# Switch to Prohori Minimal and immediately preview live
./switch-theme.sh minimal --test

# Switch to Prohori Classic (Orbital dialer layout)
./switch-theme.sh default

# List all available presets
./switch-theme.sh --list

# Show currently applied theme
./switch-theme.sh --current

# Set a custom wallpaper image
./switch-theme.sh --wallpaper ~/Pictures/wallpapers/neon.png

# Sync local changes to system SDDM directory (/usr/share/sddm/themes/prohori)
./switch-theme.sh --sync
```

---

## Testing Themes Locally (`test-theme.sh` & `test.sh`)

Before running the installation script, you can preview and test the theme presets directly from this directory without touching any system files:

### 1. Interactive Test Menu
```bash
./test-theme.sh
```
Launches an interactive loop. Choose any theme number (1–2) or key to immediately open its live SDDM preview window. Closing the preview window automatically returns you to the menu to test another theme.

### 2. Tour All Themes in Sequence
```bash
./test-theme.sh all
```
Cycles through the theme presets one after another. Close each window to automatically load the next theme.

### 3. Direct One-Line Test
```bash
# Test a theme directly using test.sh:
./test.sh minimal
./test.sh default

# Or with test-theme.sh:
./test-theme.sh minimal
./test-theme.sh default
```

---

## Customization (`theme.conf`)

Edit `theme.conf` in the theme directory to customize options manually:

```ini
[General]
themeName="Prohori Classic"
themeMode="dark"
hourFormat="12"
background="backgrounds/default.jpg"
backgroundDim="0.0"
enableWindup=true
enableVirtualKeyboard=false
authSubtitle="TYPE PASSWORD OR FIDO PIN"
authPrompt="TRY TOUCH ONLY"

# Color Palette
mainTextColor="#faf5ee"
dimTextColor="#64748b"
subTextColor="#94a3b8"
accentColor="#38bdf8"
errorColor="#ef4444"

# Dial pill styling
pillColor="#0f1621"
pillBorder="#243242"
pillInnerLine="#3b4d61"

# Ambient radial glow & chronometer tracks
ambientGlowColor="#1e324a"
showOrbitTracks=true
```

---

## Virtual Keyboard Behavior & Troubleshooting

By default, Prohori keeps the virtual on-screen keyboard closed and suppressed so that the clock dial artwork is never obstructed when the password input gains focus.

### Native Theme Control
In `theme.conf`, `enableVirtualKeyboard=false` ensures that the virtual keyboard remains hidden on focus and click events. If you are on a touchscreen-only device and want the on-screen keyboard to pop up on focus, set:
```ini
enableVirtualKeyboard=true
```

### Global SDDM Input Method Configuration
If your system previously had a global SDDM drop-in enabling Qt Virtual Keyboard (for example `/etc/sddm.conf.d/virtualkbd.conf` with `InputMethod=qtvirtualkeyboard`), the `install.sh` script automatically neutralizes it by configuring `InputMethod=` in SDDM drop-in rules.

To verify or manually disable the virtual keyboard globally in SDDM:
Check `/etc/sddm.conf.d/theme.conf` or `/etc/sddm.conf.d/virtualkbd.conf`:
```ini
[General]
InputMethod=
```
*(Leaving `InputMethod=` empty instructs SDDM not to instantiate the virtual keyboard daemon).*

---

## Directory Structure

```
prohori/
├── Main.qml             # Core QML interface, orbital dial engine & dashboard
├── metadata.desktop     # SDDM theme metadata
├── theme.conf           # Active theme configuration
├── test-theme.sh        # Dedicated local theme test runner & tour
├── switch-theme.sh      # Interactive & CLI theme preset switcher
├── test.sh              # Live preview script with preset argument support
├── install.sh           # One-step multi-distro installer script
├── themes/              # Handcrafted theme preset definitions
│   ├── astral.conf      # Prohori Astral (Cybernetic stacked typography & constellation mesh)
│   ├── minimal.conf     # Prohori Minimal (Modern architectural layout with falling dust motes)
│   └── default.conf     # Prohori Classic (Dialer layout with obsidian navy background)
├── backgrounds/         # Background assets
│   ├── astral.jpg       # Cosmic abyss with micro-starfield matrix
│   ├── minimal.jpg      # Minimal clean obsidian slate background
│   └── default.jpg      # Classic obsidian navy background
├── screenshots/         # Documentation screenshots
│   ├── main.png
│   └── dashboard.png
└── fonts/               # Bundled Outfit font files
    ├── Outfit-Black.ttf
    ├── Outfit-Bold.ttf
    ├── Outfit-Medium.ttf
    ├── Outfit-Regular.ttf
    └── Outfit-SemiBold.ttf
```
