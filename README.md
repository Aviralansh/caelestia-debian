# Caelestia Debian Installer

An open-source installer script and set of patches to run the [Caelestia Hyprland desktop environment](https://github.com/caelestia-dots) on **Debian Trixie (Testing)**.

## Motivation

Caelestia is a highly customized, visually striking Hyprland configuration primarily targeted at Arch Linux. This project bridges the compatibility gap for Debian Trixie by:
- Enabling backports for modern packages (like latest `hyprland`, `xdg-desktop-portal-hyprland`, `hyprpicker`).
- Compiling core dependencies (`libcava`, `quickshell`) from source to work seamlessly.
- Applying patches to the compilation process of `caelestia-shell` to resolve GCC 14 type-completeness errors and down-target the Qt requirements to `6.8` (instead of `6.9`).

## Features

- **Backports Auto-configuration:** Automatically adds and updates the `trixie-backports` package archives.
- **Audio Visualizer Compilation:** Automatically builds and installs the shared library version of CAVA (`libcava.so`).
- **Quickshell Engine Builder:** Builds and registers the custom `quickshell` modules.
- **Debian Compatibility Patches:** Auto-applies changes to:
  - Down-target the required Qt version requirement to `6.8` in `CMakeLists.txt`.
  - Explicitly include `<QJsonDocument>` in `hyprextras.cpp` and `lyrics.cpp` (resolving GCC 14 compilation issues).
  - Explicitly wrap `std::string` objects in `QString::fromStdString()` in `qalculator.cpp` to prevent compile errors.
- **Fonts & Configurations:** Fetches JetBrains Mono Nerd Font, clones the `caelestia-dots` repository, and automatically deploys the configuration.

## Installation

1. **Clone this repository:**
   ```bash
   git clone https://github.com/Aviralansh/caelestia-debian.git
   cd caelestia-debian
   ```

2. **Run the installer:**
   ```bash
   ./install.sh
   ```

3. **Reboot your system:**
   ```bash
   sudo reboot
   ```
   Select **Hyprland** at your display manager screen (e.g., SDDM, GDM) to enjoy Caelestia.

## License

This installer and patches are released under the [MIT License](LICENSE). The underlying components (Caelestia Shell, Quickshell, CAVA) retain their original licenses.
