# MSI Modern 15 Linux Fixes (B7M / C7M / A5M)

Набор системных конфигураций и скриптов для исправления аппаратных особенностей ноутбуков MSI Modern (в частности **Modern 15 B7M** на платформе AMD) в Linux.

---

## 🛠 Что исправляет этот репозиторий

1. **Загрузка драйвера `msi-ec` при новой прошивке EC:**
   * В версиях BIOS/EC `15HKEMS1.600+` драйвер `msi-ec` версии 0.13 падает с ошибкой несовместимости (`Your firmware version is not supported!`).
   * Конфигурация в `etc/modprobe.d/msi-ec.conf` передает совместимый идентификатор `firmware=15HKEMS1.501`, восстанавливая доступ к управлению подсветкой, кулерами и индикаторами.

2. **Индикаторы отключения звука (F1) и микрофона (F5):**
   * В Linux с аудиосервером PipeWire системные триггеры ALSA не переключают аппаратные индикаторы на клавиатуре.
   * Правило udev предоставляет права на запись в `/sys/class/leds/platform::mute/brightness` и `platform::micmute/brightness` без прав root.
   * Демон `msi-mute-sync-daemon` отслеживает события PipeWire/PulseAudio и синхронизирует светодиоды.

3. **Клавиша Fn + Esc (Fn-Lock):**
   * На клавиатуре Modern 15 нажатие Fn+Esc посылает сканкод `0xf0` (`e070`), который по умолчанию не распознается ядром (`atkbd unknown key pressed`).
   * Правило hwdb привязывает сканкод к событию `KEY_FN_ESC`.

4. **Ступенчатое затухание/засветление подсветки:**
   * Скрипт `msi-kbd-fade` обеспечивает плавное переключение между доступными уровнями яркости (0 ↔ 1 ↔ 2 ↔ 3) клавиатуры.

---

## 🚀 Установка

```bash
git clone https://github.com/YOUR_USERNAME/msi-modern-15-linux-fix.git
cd msi-modern-15-linux-fix
sudo ./install.sh
```

Для удаления:
```bash
sudo ./install.sh --uninstall
```

---

## ⌨️ Использование утилит

* **Плавная регулировка подсветки:**
  ```bash
  msi-kbd-fade in      # Плавно включить (0 -> 1 -> 2 -> 3)
  msi-kbd-fade out     # Плавно выключить (3 -> 2 -> 1 -> 0)
  msi-kbd-fade toggle  # Переключить состояние
  ```

* **Ручное управление светодиодами:**
  ```bash
  msi-mute-led speaker toggle
  msi-mute-led mic toggle
  ```

* **Автосинхронизация светодиодов (systemd user service):**
  ```bash
  systemctl --user enable --now msi-mute-sync.service
  ```
