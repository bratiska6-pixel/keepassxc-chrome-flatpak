# 🔐 KeePassXC + Google Chrome (Flatpak Integration)

[![Linux](https://img.shields.io/badge/Linux-Ubuntu_%7C_Fedora_%7C_Debian_%7C_Arch-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/bratiska6-pixel/keepassxc-chrome-flatpak)
[![Flatpak](https://img.shields.io/badge/Flatpak-Sandboxed_Apps-4A90E2?style=for-the-badge&logo=flatpak&logoColor=white)](https://flatpak.org)
[![KeePassXC](https://img.shields.io/badge/KeePassXC-v2.8+-6CAE3E?style=for-the-badge&logo=keepassxc&logoColor=white)](https://keepassxc.org)
[![Google Chrome](https://img.shields.io/badge/Google_Chrome-Extension_Bridge-4285F4?style=for-the-badge&logo=googlechrome&logoColor=white)](https://www.google.com/chrome/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> 🤖 **Дисклеймер:** Данный проект, архитектура решения, скрипты автоматизации и документация разработаны и сформированы с помощью искусственного интеллекта (AI Assistant).

> **Надежное, автоматизированное и безопасное решение для интеграции менеджера паролей KeePassXC с браузером Google Chrome, когда оба приложения установлены в изолированных песочницах Flatpak.**

---

## 📋 Оглавление
1. [В чем проблема по умолчанию?](#-в-чем-проблема-по-умолчанию)
2. [Архитектура решения](#-архитектура-решения)
3. [Быстрый старт (Автоматическая установка)](#-быстрый-старт-автоматическая-установка)
4. [Пошаговая ручная настройка и разбор параметров](#-пошаговая-ручная-настройка-и-разбор-параметров)
5. [Безопасность и учетные данные (Credentials)](#-безопасность-и-учетные-данные-credentials)
6. [Детальные тесты работоспособности](#-детальные-тесты-работоспособности)
7. [Удаление и откат изменений (Uninstall)](#-удаление-и-откат-изменений-uninstall)

---

## 🧩 В чем проблема по умолчанию?

При стандартной установке из Flathub:
- **Google Chrome** запускается внутри изолированного пространства имен `com.google.Chrome`.
- **KeePassXC** запускается в песочнице `org.keepassxc.KeePassXC`.
- Официальное расширение **KeePassXC-Browser** использует стандартный протокол браузеров **Native Messaging** (двоичный JSON-обмен через `stdin` / `stdout`).
- Браузер пытается запустить исполняемый файл хоста на хостовой машине или внутри своего контейнера. Из-за изоляции Bubblewrap браузер Chrome не видит бинарные файлы KeePassXC и не имеет прав доступа к его сокету взаимодействия. В результате расширение выдает ошибку `Key exchange was not successful` или `Native host has exited`.

---

## 🌐 Архитектура решения

Решение организует мост между двумя контейнерами Flatpak без отключения общей изоляции системы:

```text
┌──────────────────────────────────────────────┐
│        Google Chrome (Flatpak Sandbox)       │
│  ┌───────────────────────┐                   │
│  │  KeePassXC-Browser    │ (WebExtension)    │
│  └───────────┬───────────┘                   │
│              │ stdio (JSON Native Messaging) │
│  ┌───────────▼───────────────────────────┐   │
│  │  keepassxc-proxy-wrapper.sh           │   │
│  └───────────┬───────────────────────────┘   │
└──────────────┼───────────────────────────────┘
               │ flatpak-spawn
               │ (монтирование рантайма KDE и библиотек)
┌──────────────▼───────────────────────────────┐
│        KeePassXC Runtime Context             │
│  ┌───────────────────────────────────────┐   │
│  │  keepassxc-proxy                      │   │
│  └───────────┬───────────────────────────┘   │
└──────────────┼───────────────────────────────┘
               │ UNIX Domain Socket
               │ (/run/user/<UID>/app/org.keepassxc.KeePassXC/...)
┌──────────────▼───────────────────────────────┐
│       KeePassXC App (Flatpak Sandbox)        │
│  ┌───────────────────────────────────────┐   │
│  │  KeePassXC Server (Browser Integration│   │
│  │  Локальная зашифрованная база (.kdbx) │   │
│  └───────────────────────────────────────┘   │
└──────────────────────────────────────────────┘
```

---

## ⚡ Быстрый старт (Автоматическая установка)

Клонируйте репозиторий и запустите установщик «в 1 клик»:

```bash
git clone https://github.com/bratiska6-pixel/keepassxc-chrome-flatpak.git
cd keepassxc-chrome-flatpak
chmod +x install.sh
./install.sh
```

Скрипт автоматически:
1. Проверит наличие Flatpak и установленных пакетов Chrome и KeePassXC.
2. Применит минимально необходимые правила изоляции `flatpak override --user`.
3. Развернет исполняемый скрипт-мост `keepassxc-proxy-wrapper.sh`.
4. Сформирует корректный абсолютный путь в манифесте `org.keepassxc.keepassxc_browser.json`.
5. Добавит манифест расширения Chrome для быстрой загрузки.

---

## 🛠 Пошаговая ручная настройка и разбор параметров

Если вы хотите выполнить настройку вручную без скрипта, следуйте этим шагам:

### 1. Настройка графического интерфейса KeePassXC
Откройте **KeePassXC** → меню **Инструменты** → **Параметры** → вкладка **Интеграция с браузерами**:
* **Включить интеграцию с браузерами** (`Browser.Enabled=true`): активирует прослушивание входящих подключений на локальном UNIX-сокете `org.keepassxc.KeePassXC.BrowserServer`.
* **Поддерживаемые браузеры → Google Chrome**: регистрирует поддержку Chromium-семейства.
* **Искать во всех открытых базах данных** (`Browser.SearchInAllDatabases=true`): позволяет находить учетные данные, если у вас одновременно открыта рабочая и личная база.
* **Сопоставлять схему URL** (`Browser.MatchUrlScheme=true`): предотвращает подстановку паролей от `https://` ресурсов на фишинговые `http://` копии.

### 2. Предоставление прав контейнеру Chrome
Выполните в терминале команду:
```bash
flatpak override --user \
  --filesystem=/var/lib/flatpak/app/org.keepassxc.KeePassXC:ro \
  --filesystem=/var/lib/flatpak/runtime/org.kde.Platform:ro \
  --filesystem=xdg-data/flatpak/app/org.keepassxc.KeePassXC:ro \
  --filesystem=xdg-data/flatpak/runtime/org.kde.Platform:ro \
  --filesystem=xdg-run/app/org.keepassxc.KeePassXC:create \
  com.google.Chrome
```
* **Значение параметров:**
  - `--filesystem=...:ro`: режим *Read-Only* (только для чтения) для каталогов программы и библиотек KDE. Chrome не имеет права изменять файлы KeePassXC.
  - `--filesystem=xdg-run/app/org.keepassxc.KeePassXC:create`: открывает доступ к каталогу в оперативной памяти (`/run/user/<UID>/...`), где расположен IPC-сокет взаимодействия.

### 3. Создание моста `keepassxc-proxy-wrapper.sh`
Создайте файл `~/.var/app/com.google.Chrome/config/google-chrome/keepassxc-proxy-wrapper.sh`:
```bash
#!/bin/bash
APP_REF="org.keepassxc.KeePassXC/x86_64/stable"

for inst in "$HOME/.local/share/flatpak" "/var/lib/flatpak"; do
    if [ -d "$inst/app/$APP_REF" ]; then
        FLATPAK_INST="$inst"
        break
    fi
done
[ -z "$FLATPAK_INST" ] && exit 1

APP_PATH="$FLATPAK_INST/app/$APP_REF/active"
RUNTIME_REF=$(awk -F'=' '$1=="runtime" { print $2 }' < "$APP_PATH/metadata")
RUNTIME_PATH="$FLATPAK_INST/runtime/$RUNTIME_REF/active"

exec flatpak-spawn \
    --env=LD_LIBRARY_PATH=/app/lib \
    --app-path="$APP_PATH/files" \
    --usr-path="$RUNTIME_PATH/files" \
    -- /app/bin/keepassxc-proxy "$@"
```
Сделайте файл исполняемым:
```bash
chmod +x ~/.var/app/com.google.Chrome/config/google-chrome/keepassxc-proxy-wrapper.sh
```

### 4. Регистрация манифеста Native Messaging
Создайте файл `~/.var/app/com.google.Chrome/config/google-chrome/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json`:
```json
{
    "allowed_origins": [
        "chrome-extension://pdffhmdngciaglkoonimfcmckehcpafo/",
        "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
    ],
    "description": "KeePassXC integration with native messaging support",
    "name": "org.keepassxc.keepassxc_browser",
    "path": "/home/<ВАШЕ_ИМЯ_ПОЛЬЗОВАТЕЛЯ>/.var/app/com.google.Chrome/config/google-chrome/keepassxc-proxy-wrapper.sh",
    "type": "stdio"
}
```
* **Значение параметров:**
  - `"name"`: уникальный идентификатор хоста, зашитый в расширение.
  - `"path"`: строго абсолютный путь к скрипту (тильда `~` не поддерживается).
  - `"allowed_origins"`: идентификаторы официальных расширений из Chrome Web Store и Microsoft Edge Add-ons.

---

## 🔒 Безопасность и учетные данные (Credentials)

При сопряжении браузера с KeePassXC:
1. **Мастер-пароль не раскрывается:** Ваш мастер-пароль от базы `.kdbx` **никогда не покидает память KeePassXC** и не передается браузеру.
2. **Сквозное шифрование:**
   - KeePassXC и расширение генерируют пары асимметричных ключей **Curve25519**.
   - По открытому каналу Native Messaging передаются только публичные ключи.
   - Все передаваемые логины и пароли шифруются симметричным шифром **AES-256-GCM**.
3. **Идентификатор клиента (Key ID):**
   - При первом нажатии кнопки **Connect** KeePassXC запрашивает имя ключа (например, `chrome-workstation`).
   - Ключ сохраняется в KeePassXC в списке сопряженных клиентов (*Параметры → Интеграция с браузерами → Подключенные базы данных*).
   - Вы в любой момент можете отозвать доступ одного клика.

---

## 🧪 Детальные тесты работоспособности

### Тест 1: Диагностика IPC-моста (Connection Status Test)
* **Цель:** Убедиться, что процесс-мост корректно запускается и обменивается сообщениями.
* **Порядок действий:**
  1. В Google Chrome нажмите правой кнопкой мыши по значку расширения **KeePassXC-Browser** → **Параметры**.
  2. Перейдите во вкладку **Подключение** (Connected Databases).
* **Контрольные параметры:**
  - `Индикатор соединения`: Зеленый кружок.
  - `Текст статуса`: *«KeePassXC-Browser подключен к KeePassXC (версия 2.8.x)»*.
  - `База данных`: Отображается название вашей `.kdbx` базы и имя ключа.
* **Возможные ошибки:**
  - `Specified native messaging host not found` → Проверьте путь и название JSON-манифеста в `NativeMessagingHosts`.
  - `Host process exited` → Ошибка запуска скрипта (проверьте `chmod +x` и команду `flatpak-spawn`).

### Тест 2: Автозаполнение и защита от фишинга (Strict Domain Test)
* **Цель:** Проверить подстановку учетных данных и доменную изоляцию.
* **Порядок действий:**
  1. Создайте в KeePassXC запись:
     - Имя пользователя: `demo_user@corp.local`
     - Пароль: `SuperSecretP@ss1`
     - URL: `https://httpbin.org/forms/post`
  2. Откройте в Chrome `https://httpbin.org/forms/post`.
  3. В поле ввода должен появиться зеленый логотип KeePassXC. Нажмите на него или комбинацию `Alt+Shift+U` — учетные данные успешно подставятся.
  4. Перейдите на `https://example.com`: расширение **не должно** предлагать данный пароль, что подтверждает защиту от поддельных доменов.

---

## 🗑 Удаление и откат изменений (Uninstall)

Для полного удаления всех компонентов и сброса прав песочницы:

```bash
cd keepassxc-chrome-flatpak
./uninstall.sh
```

Или вручную:
```bash
# Удаление файлов моста и манифестов
rm -f ~/.var/app/com.google.Chrome/config/google-chrome/keepassxc-proxy-wrapper.sh
rm -f ~/.var/app/com.google.Chrome/config/google-chrome/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json
rm -f ~/.var/app/com.google.Chrome/config/google-chrome/External\ Extensions/oboonakemofpalcgghocfoadofidjkkk.json

# Сброс разрешений Flatpak
flatpak override --user --reset com.google.Chrome
```

---

## 📄 Лицензия

Проект распространяется под открытой лицензией [MIT License](LICENSE).
Copyright (c) 2026 [bratiska6-pixel](https://github.com/bratiska6-pixel).
