#!/usr/bin/env bash
# ==============================================================================
#  KeePassXC + Google Chrome (Flatpak Integration Installer)
#  Author: bratiska6-pixel
#  License: MIT
# ==============================================================================

set -euo pipefail

# Цвета для терминала
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

echo -e "${BOLD}${BLUE}"
echo "=============================================================="
echo "   KeePassXC + Google Chrome Flatpak Integration Installer    "
echo "   IPC Native Messaging Bridge for Sandboxed Linux Apps       "
echo "=============================================================="
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHROME_CONFIG_DIR="${HOME}/.var/app/com.google.Chrome/config/google-chrome"
WRAPPER_SCRIPT="${CHROME_CONFIG_DIR}/keepassxc-proxy-wrapper.sh"
NATIVE_HOSTS_DIR="${CHROME_CONFIG_DIR}/NativeMessagingHosts"
HOST_MANIFEST="${NATIVE_HOSTS_DIR}/org.keepassxc.keepassxc_browser.json"
EXTERNAL_EXT_DIR="${CHROME_CONFIG_DIR}/External Extensions"
EXT_ID="oboonakemofpalcgghocfoadofidjkkk"

# 1. Проверка предварительных требований
info "1/5. Проверка окружения Flatpak и установленных пакетов..."
if ! command -v flatpak &>/dev/null; then
    error "Flatpak не установлен в системе. Пожалуйста, установите flatpak."
fi

KEEPASS_FOUND=false
CHROME_FOUND=false

if flatpak list | grep -q "org.keepassxc.KeePassXC"; then
    KEEPASS_FOUND=true
    success "KeePassXC (org.keepassxc.KeePassXC) найден."
else
    error "KeePassXC (Flatpak) не установлен. Установите: flatpak install flathub org.keepassxc.KeePassXC"
fi

if flatpak list | grep -q "com.google.Chrome"; then
    CHROME_FOUND=true
    success "Google Chrome (com.google.Chrome) найден."
else
    error "Google Chrome (Flatpak) не установлен. Установите: flatpak install flathub com.google.Chrome"
fi

# 2. Выдача прав через flatpak override
info "2/5. Настройка изоляции Flatpak: предоставление Chrome доступа к KeePassXC..."
flatpak override --user \
  --filesystem=/var/lib/flatpak/app/org.keepassxc.KeePassXC:ro \
  --filesystem=/var/lib/flatpak/runtime/org.kde.Platform:ro \
  --filesystem=xdg-data/flatpak/app/org.keepassxc.KeePassXC:ro \
  --filesystem=xdg-data/flatpak/runtime/org.kde.Platform:ro \
  --filesystem=xdg-run/app/org.keepassxc.KeePassXC:create \
  com.google.Chrome
success "Права доступа успешно обновлены (flatpak override --user)."

# 3. Установка скрипта-моста keepassxc-proxy-wrapper.sh
info "3/5. Создание и установка скрипта-моста..."
mkdir -p "${CHROME_CONFIG_DIR}"

if [ -f "${SCRIPT_DIR}/templates/keepassxc-proxy-wrapper.sh" ]; then
    cp "${SCRIPT_DIR}/templates/keepassxc-proxy-wrapper.sh" "${WRAPPER_SCRIPT}"
else
    cat << 'EOF' > "${WRAPPER_SCRIPT}"
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
EOF
fi

chmod +x "${WRAPPER_SCRIPT}"
success "Скрипт-мост сохранен: ${WRAPPER_SCRIPT}"

# 4. Регистрация Native Messaging манифеста
info "4/5. Создание манифеста org.keepassxc.keepassxc_browser.json..."
mkdir -p "${NATIVE_HOSTS_DIR}"

cat << EOF > "${HOST_MANIFEST}"
{
    "allowed_origins": [
        "chrome-extension://pdffhmdngciaglkoonimfcmckehcpafo/",
        "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
    ],
    "description": "KeePassXC integration with native messaging support",
    "name": "org.keepassxc.keepassxc_browser",
    "path": "${WRAPPER_SCRIPT}",
    "type": "stdio"
}
EOF
success "Манифест зарегистрирован: ${HOST_MANIFEST}"

# 5. Настройка автозагрузки расширения (External Extensions)
info "5/5. Преднастройка расширения KeePassXC-Browser..."
mkdir -p "${EXTERNAL_EXT_DIR}"
cat << 'EOF' > "${EXTERNAL_EXT_DIR}/${EXT_ID}.json"
{
  "external_update_url": "https://clients2.google.com/service/update2/crx"
}
EOF
success "Расширение добавлено в список External Extensions."

echo
echo -e "${BOLD}${GREEN}==============================================================${NC}"
echo -e "${BOLD}${GREEN}  Установка и настройка интеграции успешно завершена!          ${NC}"
echo -e "${BOLD}${GREEN}==============================================================${NC}"
echo
echo -e "${BOLD}Следующие шаги:${NC}"
echo -e " 1. Включите интеграцию в программе KeePassXC:"
echo -e "    ${CYAN}Инструменты → Параметры → Интеграция с браузерами → Google Chrome${NC}"
echo -e " 2. Полностью перезапустите Google Chrome."
echo -e " 3. Если расширение не появилось автоматически, установите его из Chrome Web Store:"
echo -e "    ${CYAN}https://chromewebstore.google.com/detail/keepassxc-browser/iopaggbppflmgagloepolggmgmgiligl${NC}"
echo -e " 4. Нажмите на значок расширения в браузере и нажмите ${BOLD}Connect (Подключить)${NC}."
echo
