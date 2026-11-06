#!/usr/bin/env bash
# ==============================================================================
#  KeePassXC + Google Chrome (Flatpak Integration Uninstaller)
#  Author: bratiska6-pixel
#  License: MIT
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

echo -e "${BOLD}${BLUE}"
echo "=============================================================="
echo "   KeePassXC + Google Chrome Integration Uninstaller          "
echo "   Полная очистка и сброс настроек моста Native Messaging     "
echo "=============================================================="
echo -e "${NC}"

CHROME_CONFIG_DIR="${HOME}/.var/app/com.google.Chrome/config/google-chrome"
WRAPPER_SCRIPT="${CHROME_CONFIG_DIR}/keepassxc-proxy-wrapper.sh"
HOST_MANIFEST="${CHROME_CONFIG_DIR}/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json"
EXTERNAL_EXT="${CHROME_CONFIG_DIR}/External Extensions/oboonakemofpalcgghocfoadofidjkkk.json"

# 1. Удаление файлов манифеста и моста
info "1/3. Удаление скрипта-моста и манифестов..."
if [ -f "${HOST_MANIFEST}" ]; then
    rm -f "${HOST_MANIFEST}"
    success "Манифест удален: ${HOST_MANIFEST}"
fi

if [ -f "${WRAPPER_SCRIPT}" ]; then
    rm -f "${WRAPPER_SCRIPT}"
    success "Скрипт-мост удален: ${WRAPPER_SCRIPT}"
fi

if [ -f "${EXTERNAL_EXT}" ]; then
    rm -f "${EXTERNAL_EXT}"
    success "Конфигурация внешнего расширения удалена."
fi

# 2. Сброс переопределений Flatpak
info "2/3. Сброс разрешений Flatpak для Google Chrome..."
if command -v flatpak &>/dev/null; then
    flatpak override --user --reset com.google.Chrome 2>/dev/null || true
    success "Разрешения Flatpak возвращены к значениям по умолчанию."
fi

# 3. Рекомендации по удалению расширения и ключей
info "3/3. Финализация..."
echo
echo -e "${BOLD}${GREEN}==============================================================${NC}"
echo -e "${BOLD}${GREEN}  Все созданные файлы и права успешно удалены!                 ${NC}"
echo -e "${BOLD}${GREEN}==============================================================${NC}"
echo
echo -e "${BOLD}Для полной очистки вручную рекомендуется:${NC}"
echo -e " 1. В Google Chrome удалите расширение ${BOLD}KeePassXC-Browser${NC} со страницы ${CYAN}chrome://extensions/${NC}."
echo -e " 2. В KeePassXC откройте ${BOLD}Инструменты → Параметры → Интеграция с браузерами${NC}:"
echo -e "    - На вкладке «Подключенные базы данных» удалите привязанный ключ."
echo -e "    - При необходимости снимите галочку «Включить интеграцию с браузерами»."
echo
