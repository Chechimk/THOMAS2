#!/bin/bash
# $'...' syntax makes escape codes work in read -rp prompts
RED=$'\e[31m'    ; GREEN=$'\e[32m'  ; YELLOW=$'\e[33m' ; BLUE=$'\e[34m'
CYAN=$'\e[36m'   ; WHITE=$'\e[97m'  ; BOLD=$'\e[1m'    ; RESET=$'\e[0m'
DIM=$'\e[2m'     ; BGREEN=$'\e[92m' ; BRED=$'\e[91m'   ; BYELLOW=$'\e[93m'
LRED=$'\e[1;31m' ; LCYAN=$'\e[1;36m'

PANEL_DIR="/etc/panel"
SBIN_DIR="$PANEL_DIR/sbin"
LIB_DIR="$PANEL_DIR/lib"

WIDTH=64

# ── Border drawing ────────────────────────────────────────────────
line_top() { printf "${RED}╔"; printf '═%.0s' $(seq 1 $((WIDTH-2))); printf "╗${RESET}\n"; }
line_bot() { printf "${RED}╚"; printf '═%.0s' $(seq 1 $((WIDTH-2))); printf "╝${RESET}\n"; }
line_mid() { printf "${RED}╠"; printf '═%.0s' $(seq 1 $((WIDTH-2))); printf "╣${RESET}\n"; }
line_sep() { printf "${RED}"; printf '─%.0s' $(seq 1 $WIDTH); printf "${RESET}\n"; }

# Backward-compat helpers used in module scripts
line()  { printf "${RED}"; printf '═%.0s' $(seq 1 $WIDTH); printf "${RESET}\n"; }
line2() { line_sep; }

_center() {
    local t="$1" tlen="${#1}"
    local pad=$(( (WIDTH - 2 - tlen) / 2 ))
    printf "${RED}║${RESET}%*s${BOLD}${YELLOW}%-${tlen}s${RESET}%*s${RED}║${RESET}\n" \
        "$pad" "" "$t" "$((WIDTH - 2 - tlen - pad))" ""
}

header() {
    clear
    line_top
    _center "$1"
    line_bot
    echo ""
}

section() {
    line_sep
}

ok()    { echo -e "  ${BGREEN}[+]${RESET} ${WHITE}$1${RESET}"; }
err()   { echo -e "  ${BRED}[-]${RESET} ${WHITE}$1${RESET}" >&2; }
warn()  { echo -e "  ${BYELLOW}[!]${RESET} ${WHITE}$1${RESET}"; }
info()  { echo -e "  ${CYAN}[i]${RESET} ${WHITE}$1${RESET}"; }

press_enter() {
    echo ""
    line_sep
    read -rp "  >> Press enter to continue << " _
}

confirm() {
    local prompt="${1:-Do you want to continue?}"
    read -rp "  ${YELLOW}${prompt} [Y/N]: ${RESET}" ans
    [[ "${ans^^}" == "Y" ]]
}

get_input() {
    local prompt="$1" var_name="$2"
    read -rp "  ${CYAN}${prompt}: ${RESET}" "$var_name"
}

port_in_use() { ss -tlnp 2>/dev/null | grep -q ":${1} " || ss -ulnp 2>/dev/null | grep -q ":${1} "; }

is_installed() { command -v "$1" &>/dev/null || dpkg -l "$1" &>/dev/null 2>&1; }

service_status() {
    systemctl is-active --quiet "$1" 2>/dev/null \
        && echo -e "${BGREEN}[ON]${RESET}" \
        || echo -e "${BRED}[OFF]${RESET}"
}

require_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        err "This script must be run as root."
        exit 1
    fi
}

get_ip() { hostname -I | awk '{print $1}'; }

sys_ram_total()  { free -m 2>/dev/null | awk '/Mem:/{printf "%.2fGB", $2/1024}'; }
sys_ram_used()   { free -m 2>/dev/null | awk '/Mem:/{printf "%.2fMB", $3}'; }
sys_ram_free()   { free -m 2>/dev/null | awk '/Mem:/{printf "%.2fGB", $4/1024}'; }
sys_ram_buffer() { free -m 2>/dev/null | awk '/Mem:/{printf "%.2fMB", $6}'; }
sys_ram_cache()  { free -m 2>/dev/null | awk '/Mem:/{printf "%.2fMB", $7}'; }
sys_disk_total() { df -h / 2>/dev/null | awk 'NR==2{print $2}'; }
sys_disk_used()  { df -h / 2>/dev/null | awk 'NR==2{print $3}'; }
sys_disk_free()  { df -h / 2>/dev/null | awk 'NR==2{print $4}'; }
sys_cpu_cores()  { nproc 2>/dev/null; }
sys_cpu_usage()  { grep 'cpu ' /proc/stat | awk '{u=$2+$4; t=$2+$3+$4+$5; printf "%.1f%%", (u/t)*100}'; }
sys_uptime()     { uptime -p 2>/dev/null | sed 's/up //'; }
