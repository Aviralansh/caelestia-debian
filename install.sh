#!/bin/bash
set -e

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$HOME/caelestia-build"
mkdir -p "$WORK_DIR"

echo "=== Caelestia Installer for Debian Trixie (Open Source Port) ==="
echo "Working directory: $WORK_DIR"
echo ""

if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Please do not run this script as root. Run it as your normal user."
    echo "It will ask for sudo password when necessary."
    exit 1
fi

if ! command -v sudo &> /dev/null; then
    echo "ERROR: sudo is not installed. Please install sudo and configure your user before running this script."
    exit 1
fi

# 1. Enable trixie-backports if not already enabled
if ! apt-cache policy | grep -q "trixie-backports"; then
    echo "Enabling Debian Trixie Backports..."
    echo "deb http://deb.debian.org/debian trixie-backports main" | sudo tee /etc/apt/sources.list.d/trixie-backports.list
    echo "Updating package list..."
    sudo apt update
else
    echo "trixie-backports is already enabled."
fi

# 2. Install all required system packages
echo "Installing Debian dependencies..."
sudo apt install -y -t trixie-backports \
  build-essential cmake ninja-build pkgconf \
  qt6-base-dev qt6-declarative-dev qt6-shadertools-dev qt6-wayland-dev qt6-base-private-dev qt6-declarative-private-dev qt6-wayland-private-dev \
  libdrm-dev spirv-tools libcli11-dev libunwind-dev libdw-dev libjemalloc-dev \
  libwayland-dev wayland-protocols libgbm-dev libxcb1-dev libxcb-composite0-dev \
  libxcb-xfixes0-dev libxcb-damage0-dev libxcb-randr0-dev libxcb-shape0-dev \
  libxcb-util-dev libxcb-keysyms1-dev libxcb-icccm4-dev libxcb-image0-dev \
  libxcb-render-util0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
  libpipewire-0.3-dev libpam0g-dev libpolkit-gobject-1-dev libpolkit-agent-1-dev libglib2.0-dev \
  libqalculate-dev libaubio-dev libsensors-dev \
  libfftw3-dev libasound2-dev libpulse-dev libtool automake libiniparser-dev libsdl2-dev \
  fish eza zoxide direnv foot fastfetch btop micro thunar dolphin \
  papirus-icon-theme gnome-keyring polkit-kde-agent-1 \
  network-manager bluez bluez-obexd \
  pipewire pipewire-pulse wireplumber pavucontrol \
  wl-clipboard cliphist curl git trash-cli jq lazygit bat ripgrep ydotool \
  xdg-user-dirs brightnessctl power-profiles-daemon ddcutil swappy \
  fonts-noto fonts-noto-cjk fonts-noto-color-emoji unzip meson sassc starship fuzzel hyprpicker \
  hyprland xdg-desktop-portal-hyprland python3-pip python3-venv \
  extra-cmake-modules libkf6colorscheme-dev libkf6config-dev libkf6iconthemes-dev \
  qml6-module-qt5compat-graphicaleffects qml6-module-qtquick-effects easyeffects

# 3. Install JetBrains Mono and Material Symbols Rounded fonts
echo "=== Installing Fonts ==="
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
FONT_UPDATED=0

if [ ! -f "JetBrainsMonoNerdFont-Regular.ttf" ]; then
  curl -fLo JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
  unzip -o JetBrainsMono.zip
  rm JetBrainsMono.zip
  FONT_UPDATED=1
fi

if [ ! -f "MaterialSymbolsRounded.ttf" ]; then
  curl -fLo "MaterialSymbolsRounded.ttf" "https://github.com/google/material-design-icons/raw/refs/heads/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
  FONT_UPDATED=1
fi

if [ "$FONT_UPDATED" -eq 1 ]; then
  fc-cache -fv
fi

# 3.5 Install papirus-folders manually
echo "=== Installing papirus-folders ==="
if ! command -v papirus-folders &> /dev/null; then
  sudo curl -sL https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders -o /usr/local/bin/papirus-folders
  sudo chmod +x /usr/local/bin/papirus-folders
fi

# 4. Build and Install libcava from source
echo "=== Building libcava from source ==="
if [ ! -d "$WORK_DIR/libcava-src" ]; then
  git clone https://github.com/LukashonakV/cava.git "$WORK_DIR/libcava-src"
fi
cd "$WORK_DIR/libcava-src"
rm -rf build
meson setup build --prefix=/usr/local --buildtype=release
meson compile -C build
sudo meson install -C build

# 5. Build and Install Quickshell from source
echo "=== Building Quickshell from source ==="
if [ ! -d "$WORK_DIR/quickshell" ]; then
  git clone --recursive https://github.com/outfoxxed/quickshell.git "$WORK_DIR/quickshell"
fi
cd "$WORK_DIR/quickshell"
rm -rf build
cmake -GNinja -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DVENDOR_CPPTRACE=ON -DINSTALL_QMLDIR=/usr/lib/x86_64-linux-gnu/qt6/qml
cmake --build build -j$(nproc)
sudo cmake --install build

# 6. Build and Install Caelestia Shell from source (with Debian Patches)
echo "=== Building Caelestia Shell (with patches) ==="
if [ ! -d "$WORK_DIR/caelestia-shell-git" ]; then
  git clone --recursive https://github.com/caelestia-dots/shell.git "$WORK_DIR/caelestia-shell-git"
fi
cd "$WORK_DIR/caelestia-shell-git"
git reset --hard
git apply "$SCRIPT_DIR/patches/caelestia-shell.patch"

rm -rf build
cmake -GNinja -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DINSTALL_QMLDIR=/usr/lib/x86_64-linux-gnu/qt6/qml -DINSTALL_LIBDIR=/usr/local/lib/caelestia -DINSTALL_QSCONFDIR=/etc/xdg/quickshell/caelestia
cmake --build build -j$(nproc)
sudo cmake --install build

# 7. Install Caelestia CLI (with Debian Patches)
echo "=== Installing Caelestia CLI (with patches) ==="
if [ ! -d "$WORK_DIR/caelestia-cli-git" ]; then
  git clone https://github.com/caelestia-dots/cli.git "$WORK_DIR/caelestia-cli-git"
fi
cd "$WORK_DIR/caelestia-cli-git"
git reset --hard
git apply "$SCRIPT_DIR/patches/caelestia-cli.patch"
pip install --break-system-packages --user .

# 8. Build and Install qtengine from source (with Debian Patches)
echo "=== Building qtengine (with patches) ==="
if [ ! -d "$WORK_DIR/qtengine-src" ]; then
  git clone https://github.com/kossLAN/qtengine.git "$WORK_DIR/qtengine-src"
fi
cd "$WORK_DIR/qtengine-src"
git reset --hard
git apply "$SCRIPT_DIR/patches/qtengine.patch"

rm -rf build
cmake -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_QT5=OFF -B build
cmake --build build -j$(nproc)
sudo cmake --install build

# Symlink plugins to Debian's standard Qt6 path
sudo ln -sf /usr/local/lib/qt6/plugins/platformthemes/libqt6engine-plugin.so /usr/lib/x86_64-linux-gnu/qt6/plugins/platformthemes/libqt6engine-plugin.so
sudo ln -sf /usr/local/lib/qt6/plugins/styles/libqt6engine-style.so /usr/lib/x86_64-linux-gnu/qt6/plugins/styles/libqt6engine-style.so
sudo ldconfig

# 9. Clone Caelestia Dots and Install
echo "=== Installing Caelestia Dots ==="
if [ ! -d "$HOME/caelestia-dots" ]; then
  git clone https://github.com/caelestia-dots/caelestia-dots.git "$HOME/caelestia-dots"
fi
cd "$HOME/caelestia-dots"
# Run Caelestia dots installer
~/.local/bin/caelestia install --noconfirm

# Explicitly copy configuration files to ensure they are properly placed on Debian
echo "=== Configuring Caelestia Dots ==="
mkdir -p "$HOME/.config"
if [ -d "$HOME/caelestia-dots/config" ]; then
    cp -r "$HOME/caelestia-dots/config/"* "$HOME/.config/"
fi

# Set theme to dynamic by default
~/.local/bin/caelestia scheme set --name dynamic

# 10. Install EasyEffects Dolby Atmos & HIFI Presets
echo "=== Installing EasyEffects Presets ==="
mkdir -p "$HOME/.config/easyeffects/output"
mkdir -p "$HOME/.config/easyeffects/irs"
if [ ! -d "$WORK_DIR/easyeffects-presets-git" ]; then
  git clone https://github.com/JackHack96/EasyEffects-Presets.git "$WORK_DIR/easyeffects-presets-git"
fi
cp "$WORK_DIR/easyeffects-presets-git"/*.json "$HOME/.config/easyeffects/output/"
cp "$WORK_DIR/easyeffects-presets-git"/irs/*.irs "$HOME/.config/easyeffects/irs/"

echo ""
echo "=== Caelestia Debian installation complete! ==="
echo "A reboot is recommended to initialize all settings and environments."
