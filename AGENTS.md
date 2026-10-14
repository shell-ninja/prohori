# Prohori (প্রহরী) SDDM Theme — Workspace Memory & Agent Guidelines

## Project Summary
**Prohori** (প্রহরী - The Sentinel) is a handcrafted modern SDDM (Simple Desktop Display Manager) greeter theme developed by **shell-ninja** using QtQuick 6 / QML.

## Active Themes & Presets (Strictly 3 Handcrafted Themes)
Do **NOT** re-add legacy themes 4 to 9 or cyberpunk. The project is focused exclusively on three polished presets:

1. **Prohori Classic** (`themes/default.conf`):
   - Layout: Concentric orbital chronometer dials with windup rotation on submit.
   - Background: Dark atmospheric radial vignette (`backgrounds/default.jpg`).
   - Accent: `#38bdf8` (Cyan Blue).

2. **Prohori Minimal** (`themes/minimal.conf`):
   - Layout: Monolithic digital clock (`displayHour : curM`), kinetic seconds rail with sticky tens badge and floating units + `s` pill on the indicator dot.
   - Background: Clean dark obsidian slate (`backgrounds/minimal.jpg`) with micro-dot matrix and zero light blur.
   - Ambient Particles: Falling green micro-dust motes layer (32 particles, 1.2px–2.8px, staggered drift).
   - Dock: Center-right floating authentication card (`minAuthCard`).
   - Accent: `#00f5a0` (Hyper-Mint Green).

3. **Prohori Astral** (`themes/astral.conf`):
   - Layout: Stacked architectural typography (giant white hours over electric violet minutes), vertical timeline rail with seconds bead, telemetry counter (`SEC // [26s // 60]`).
   - Background: Deep cosmic abyss wallpaper (`backgrounds/astral.jpg`) with fine micro-starfield matrix.
   - Ambient Animation: Dynamic cyber-celestial Constellation Mesh (28 floating nodes with distance-based dynamic connection lines and nexus halos).
   - Dock: Center-right floating authentication card (`minAuthCard`) with violet laser scan and rotating radar indicator.
   - Accent: `#b026ff` (Neon Amethyst / Violet).


## Authentication Mechanics (Minimal Theme)
- **Login Animation (`startLoginSequence`)**:
  - `minLoginAnim` (750ms duration) runs before calling `doLogin()`.
  - Displays scanning laser beam across bottom of `minInputBox`.
  - Arrow transforms into spinning `◌` radar indicator.
  - Status pulses `"AUTHENTICATING CREDENTIALS..."`.
  - On `onLoginSucceeded`: `minUnlockAnim` executes parallel opacity fade out and scale expansion (1.0 to 1.04).
- **Failure Red Alert & Shake (`onLoginFailed`)**:
  - `root.isErrorState = true`.
  - Entire theme shifts to Crimson Red (`#ff3366`) via reactive `accentColor` property.
  - Dark red perimeter alert overlay (`errorAlertOverlay`) appears.
  - 8-stage decaying harmonic camera shake (`root.shakeOffset`: `±18px → ±14px → ±9px → ±4px → 0px`) shakes all elements on screen simultaneously.
  - 3-second auto-recovery (`errorResetTimer`, 3000ms): smoothly restores theme to Hyper-Mint green, resets error state, and refocuses input.

## Key CLI Commands
- `./test-theme.sh`: Dedicated interactive tester menu loop.
- `./test.sh minimal`: Direct SDDM greeter test for minimal theme.
- `./test.sh default`: Direct SDDM greeter test for classic theme.
- `./switch-theme.sh [minimal|default]`: Switch active preset (supports `-s` to sync `/usr/share/sddm/themes/prohori`).
- `./install.sh`: One-step multi-distro installer.

## Development Rules
- Always validate QML with `/usr/bin/qmllint Main.qml` (must produce 0 warnings/errors).
- In SDDM / QML, items cannot anchor to non-parent, non-sibling items across nested hierarchies.
- Maintain Outfit typography across all UI components.
