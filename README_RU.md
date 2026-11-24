# Исправления для MSI Modern 15 под Linux (B7M / C7M / A5M)

[🇬🇧 Read in English](README.md)

Набор системных конфигураций, udev-правил и вспомогательных скриптов для исправления аппаратных особенностей ноутбуков **MSI Modern 15** (в частности серии **B7M / C7M / A5M** на базе AMD) в среде Linux.

---

## 🛠 Что исправляет этот репозиторий

### 1. Ошибка загрузки драйвера `msi-ec` при новой версии прошивки EC
* **Проблема:** На ноутбуках с обновленной версией EC `15HKEMS1.600+` драйвер `msi-ec` (v0.13) отказывается запускаться с ошибкой:  
  `msi_ec: Your firmware version is not supported!`
* **Решение:** Конфигурация в `etc/modprobe.d/msi-ec.conf` передает совместимый параметр `firmware=15HKEMS1.501`, открывая доступ к управлению подсветкой клавиатуры, вентиляторами, порогами зарядки батареи и интерфейсам светодиодов в `/sys/class/leds/`.

### 2. Неработающие индикаторы отключения звука (F1) и микрофона (F5)
* **Проблема:** В среде PipeWire программное отключение звука не активирует низкоуровневые триггеры ALSA. Кроме того, файлы яркости светодиодов в `/sys/class/leds/platform::mute` и `platform::micmute` по умолчанию требуют прав суперпользователя.
* **Решение:**
  * Добавлены правила udev, предоставляющие доступ на запись (`0666`) к индикаторам без прав root.
  * Создан фоновый демон (`msi-mute-sync-daemon`), который отслеживает состояние звука и микрофона через PipeWire и синхронизирует аппаратные индикаторы в реальном времени.

### 3. Нераспознанная комбинация клавиш `Fn + Esc` (Fn-Lock)
* **Проблема:** При нажатии `Fn + Esc` клавиатура выдает не привязанный сканкод (`code 0xf0` / raw `e070`), из-за чего ядро пишет ошибку `atkbd: Unknown key pressed`.
* **Решение:** Правило для базы hwdb (`90-msi-modern-keyboard.hwdb`) привязывает сканкод `f0` к стандартному коду `KEY_FN_ESC`.

---

## 🚀 Быстрая установка

Запустите автоматический установщик от имени суперпользователя:

```bash
git clone https://github.com/iy-cmd/msi-modern-15-linux-fix.git
cd msi-modern-15-linux-fix
sudo ./install.sh
```

Для полного удаления настроек и возврата к системным значениям:

```bash
sudo ./install.sh --uninstall
```

---

## ⚙️ Ручная настройка

Если вы хотите применить параметры вручную:

1. **Активация модуля `msi-ec`:**
   ```bash
   echo "options msi_ec firmware=15HKEMS1.501" | sudo tee /etc/modprobe.d/msi-ec.conf
   echo "msi_ec" | sudo tee /etc/modules-load.d/msi-ec.conf
   sudo modprobe msi-ec firmware=15HKEMS1.501
   ```

2. **Настройка прав на светодиоды:**
   Скопируйте `etc/udev/rules.d/99-msi-leds.rules` в `/etc/udev/rules.d/` и примените правила:
   ```bash
   sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=leds
   ```

3. **Регистрация клавиши `Fn + Esc`:**
   Скопируйте `etc/udev/hwdb.d/90-msi-modern-keyboard.hwdb` в `/etc/udev/hwdb.d/` и обновите базу:
   ```bash
   sudo systemd-hwdb update
   sudo udevadm trigger --subsystem-match=input
   ```

---

## 💡 Вспомогательные утилиты

* **Ручное управление светодиодами:**
  ```bash
  msi-mute-led speaker toggle  # Переключить индикатор звука (F1)
  msi-mute-led mic toggle      # Переключить индикатор микрофона (F5)
  ```

* **Автоматическая синхронизация светодиодов с PipeWire:**
  Для автозапуска демона синхронизации в любом окружении (Hyprland, Sway, KDE, GNOME):
  ```bash
  mkdir -p ~/.config/systemd/user
  cp systemd/user/msi-mute-sync.service ~/.config/systemd/user/
  systemctl --user daemon-reload
  systemctl --user enable --now msi-mute-sync.service
  ```

---

## 📄 Лицензия

MIT License. Свободно для использования и распространения.
