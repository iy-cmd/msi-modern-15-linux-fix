#!/usr/bin/env bash
# Installer for MSI Modern 15 B7M Linux Hardware Fixes
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script requires superuser privileges to install system configuration."
        echo "Please re-run with sudo: sudo $0"
        exit 1
    fi
}

install() {
    check_root
    info "Installing MSI Modern hardware fixes..."

    # 1. Modprobe configuration (bypass firmware check for 15HKEMS1.600)
    info "Installing modprobe configuration for msi-ec..."
    install -m 644 "$SCRIPT_DIR/etc/modprobe.d/msi-ec.conf" /etc/modprobe.d/msi-ec.conf
    install -m 644 "$SCRIPT_DIR/etc/modules-load.d/msi-ec.conf" /etc/modules-load.d/msi-ec.conf
    success "msi-ec module configuration installed."

    # 2. Udev rules for LED access
    info "Installing udev rules for non-root LED access..."
    install -m 644 "$SCRIPT_DIR/etc/udev/rules.d/99-msi-leds.rules" /etc/udev/rules.d/99-msi-leds.rules
    udevadm control --reload || true
    success "udev rules installed."

    # 3. Hardware database mapping for Fn+Esc
    info "Installing hwdb rule for Fn+Esc (scancode f0 -> KEY_FN_ESC)..."
    install -m 644 "$SCRIPT_DIR/etc/udev/hwdb.d/90-msi-modern-keyboard.hwdb" /etc/udev/hwdb.d/90-msi-modern-keyboard.hwdb
    if command -v systemd-hwdb >/dev/null 2>&1; then
        systemd-hwdb update || true
    else
        udevadm hwdb --update || true
    fi
    udevadm trigger --subsystem-match=input || true
    success "hwdb keymap installed."

    # 4. Helper binaries
    info "Installing user helper binaries to /usr/local/bin..."
    install -m 755 "$SCRIPT_DIR/bin/msi-mute-led.sh" /usr/local/bin/msi-mute-led
    install -m 755 "$SCRIPT_DIR/bin/msi-mute-sync-daemon.sh" /usr/local/bin/msi-mute-sync-daemon
    success "Helper binaries installed in /usr/local/bin."

    # 5. Load module immediately
    info "Attempting to load msi-ec module..."
    modprobe -r msi-ec 2>/dev/null || true
    if modprobe msi-ec firmware=15HKEMS1.501; then
        udevadm trigger --subsystem-match=leds || true
        success "msi-ec successfully loaded and LEDs initialized!"
    else
        warn "Could not load msi-ec automatically. Ensure msi-ec-dkms is installed for your kernel."
    fi

    echo ""
    success "All fixes have been installed successfully!"
    echo "Tip: You can use 'msi-mute-led speaker/mic toggle' to manually control indicator LEDs."
}

uninstall() {
    check_root
    info "Removing MSI Modern hardware fixes..."

    rm -f /etc/modprobe.d/msi-ec.conf
    rm -f /etc/modules-load.d/msi-ec.conf
    rm -f /etc/udev/rules.d/99-msi-leds.rules
    rm -f /etc/udev/hwdb.d/90-msi-modern-keyboard.hwdb
    rm -f /usr/local/bin/msi-mute-led
    rm -f /usr/local/bin/msi-mute-sync-daemon

    if command -v systemd-hwdb >/dev/null 2>&1; then
        systemd-hwdb update || true
    fi
    udevadm control --reload || true

    success "Uninstalled cleanly."
}

case "${1:-install}" in
    install|--install)
        install
        ;;
    uninstall|--uninstall)
        uninstall
        ;;
    *)
        echo "Usage: sudo $0 {install|uninstall}"
        exit 1
        ;;
esac
