#!/bin/bash
# Shared colors, formatting, and utility functions

RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'
CYAN='\e[36m'; WHITE='\e[97m'; BOLD='\e[1m'; RESET='\e[0m'
DIM='\e[2m'; BGREEN='\e[92m'; BRED='\e[91m'; BYELLOW='\e[93m'

PANEL_DIR="/etc/panel"
SBIN_DIR="$PANEL_DIR/sbin"
LIB_DIR="$PANEL_DIR/lib"

WIDTH=60

line()  { printf '%*s\n' "$WIDTH" '' | tr ' ' '═'; }
line2() { printf '%*s\n' "$WIDTH" '' | tr ' ' '─'; }

header() {
    clear
    echo -e "${CYAN}$(line)${RESET}"
    printf "${CYAN}${BOLD}%*s${RESET}\n" $(( (WIDTH + ${#1}) / 2 )) "$1"
    echo -e "${CYAN}$(line)${RESET}"
}

section() {
    echo -e "${YELLOW}$(line2)${RESET}"
    printf "${YELLOW}  %s${RESET}\n" "$1"
    echo -e "${YELLOW}$(line2)${RESET}"
}

ok()    { echo -e "  ${GREEN}[+]${RESET} $1"; }
err()   { echo -e "  ${RED}[-]${RESET} $1"; }
warn()  { echo -e "  ${YELLOW}[!]${RESET} $1"; }
info()  { echo -e "  ${CYAN}[i]${RESET} $1"; }

press_enter() {
    echo -e "\n${DIM}$(line2)${RESET}"
    read -rp "  Press enter to continue... " _
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

port_in_use() { ss -tlnp | grep -q ":${1} "; }

is_installed() { command -v "$1" &>/dev/null || dpkg -l "$1" &>/dev/null 2>&1; }

service_status() {
    if systemctl is-active --quiet "$1"; then
        echo -e "${GREEN}ACTIVE${RESET}"
    else
        echo -e "${RED}INACTIVE${RESET}"
    fi
}

require_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        err "This script must be run as root."
        exit 1
    fi
}

get_ip() { hostname -I | awk '{print $1}'; }

sys_ram_total()  { free -m | awk '/Mem:/{print $2}'; }
sys_ram_used()   { free -m | awk '/Mem:/{print $3}'; }
sys_ram_free()   { free -m | awk '/Mem:/{print $4}'; }
sys_disk_total() { df -h / | awk 'NR==2{print $2}'; }
sys_disk_used()  { df -h / | awk 'NR==2{print $3}'; }
sys_disk_free()  { df -h / | awk 'NR==2{print $4}'; }
sys_cpu_cores()  { nproc; }
sys_cpu_usage()  { top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1; }
sys_uptime()     { uptime -p | sed 's/up //'; }
