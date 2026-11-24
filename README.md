# MSI Modern 15 Linux Fixes (B7M / C7M / A5M)

[🇷🇺 Читать на русском](README_RU.md)

A lightweight collection of kernel configurations, udev rules, and utility scripts resolving common hardware integration issues on **MSI Modern 15** laptops (specifically the AMD-based **B7M / C7M / A5M** series) under Linux.

---

## 🛠 Problems Solved

### 1. `msi-ec` Module Load Failure on Newer BIOS / EC Firmware
* **Issue:** On laptops running newer EC firmware versions (such as `15HKEMS1.600+`), the `msi-ec` driver (v0.13) fails to load with the kernel error:  
  `msi_ec: Your firmware version is not supported!`
* **Solution:** A configuration in `etc/modprobe.d/msi-ec.conf` passes `firmware=15HKEMS1.501` to use the compatible register memory map, restoring keyboard backlight controls, fan telemetry, battery limits, and LED sysfs nodes.

### 2. Broken Mute (F1) and Mic-Mute (F5) LED Key Indicators
* **Issue:** Under PipeWire and modern Linux desktop environments, digital audio muting does not trigger the kernel's hardware ALSA mute LED switches. Furthermore, the sysfs interfaces `/sys/class/leds/platform::mute` and `platform::micmute` require root permissions by default.
* **Solution:**
  * Custom udev rules grant read-write permissions (`0666`) to all platform LED nodes without needing root access.
  * A lightweight background daemon (`msi-mute-sync-daemon`) watches PipeWire audio state and keeps the physical LEDs accurately synchronized in real time.

### 3. Unrecognized `Fn + Esc` (Fn-Lock) Shortcut
* **Issue:** Pressing `Fn + Esc` produces an unmapped scancode (`translated set 2, code 0xf0` / raw `e070`), logging `atkbd: Unknown key pressed` warnings and failing to trigger Fn-Lock state properly in userspace.
* **Solution:** A hardware database rule (`90-msi-modern-keyboard.hwdb`) binds scancode `f0` directly to `KEY_FN_ESC`.

---

## 🚀 Quick Installation

Run the automated installer with superuser privileges:

```bash
git clone https://github.com/iy-cmd/msi-modern-15-linux-fix.git
cd msi-modern-15-linux-fix
sudo ./install.sh
```

To remove all installed configurations and restore defaults:

```bash
sudo ./install.sh --uninstall
```

---

## ⚙️ Manual Setup

If you prefer to configure the system manually:

1. **Enable the `msi-ec` Module:**
   ```bash
   echo "options msi_ec firmware=15HKEMS1.501" | sudo tee /etc/modprobe.d/msi-ec.conf
   echo "msi_ec" | sudo tee /etc/modules-load.d/msi-ec.conf
   sudo modprobe msi-ec firmware=15HKEMS1.501
   ```

2. **Set Non-Root LED Permissions:**
   Copy `etc/udev/rules.d/99-msi-leds.rules` to `/etc/udev/rules.d/` and reload:
   ```bash
   sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=leds
   ```

3. **Register the `Fn + Esc` Keymap:**
   Copy `etc/udev/hwdb.d/90-msi-modern-keyboard.hwdb` to `/etc/udev/hwdb.d/` and rebuild the hardware database:
   ```bash
   sudo systemd-hwdb update
   sudo udevadm trigger --subsystem-match=input
   ```

---

## 💡 Utilities Included

* **Manual LED control:**
  ```bash
  msi-mute-led speaker toggle  # Toggle speaker mute LED (F1)
  msi-mute-led mic toggle      # Toggle microphone mute LED (F5)
  ```

* **Automatic PipeWire LED Sync Daemon:**
  To keep LEDs synchronized automatically across any desktop environment (Hyprland, Sway, KDE, GNOME), enable the user service:
  ```bash
  mkdir -p ~/.config/systemd/user
  cp systemd/user/msi-mute-sync.service ~/.config/systemd/user/
  systemctl --user daemon-reload
  systemctl --user enable --now msi-mute-sync.service
  ```

---

## 📄 License

MIT License. Free to use, modify, and distribute.
