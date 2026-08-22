#!/bin/bash
set -e
clear

RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; CYAN='\e[36m'; RESET='\e[0m'; BOLD='\e[1m'

ok()   { echo -e "  ${GREEN}[+]${RESET} $1"; }
err()  { echo -e "  ${RED}[-]${RESET} $1"; exit 1; }
warn() { echo -e "  ${YELLOW}[!]${RESET} $1"; }
info() { echo -e "  ${CYAN}[i]${RESET} $1"; }

line() { printf '%60s\n' '' | tr ' ' '═'; }

[[ "$(id -u)" -ne 0 ]] && err "Must be run as root."

. /etc/os-release
[[ "$ID" != "ubuntu" && "$ID" != "debian" ]] && err "Unsupported OS: $ID. Requires Ubuntu or Debian."

PANEL_DIR="/etc/panel"
SBIN_DIR="$PANEL_DIR/sbin"
LIB_DIR="$PANEL_DIR/lib"

# ── Uninstall mode ──────────────────────────────────────────────
if [[ "$1" == "--uninstall" ]]; then
    echo -e "${RED}$(line)${RESET}"
    echo -e "${RED}${BOLD}          UNINSTALLING PANEL${RESET}"
    echo -e "${RED}$(line)${RESET}"
    read -rp "  Confirm uninstall? [Y/N]: " ans
    [[ "${ans^^}" != "Y" ]] && { warn "Cancelled." ; exit 0; }
    rm -rf "$PANEL_DIR"
    sed -i '/source \/etc\/panel\/bashrc/d' /root/.bashrc
    systemctl disable update-panel 2>/dev/null
    rm -f /etc/systemd/system/update-panel.service
    systemctl daemon-reload
    ok "Panel removed." ; exit 0
fi

# ── Header ──────────────────────────────────────────────────────
echo -e "${CYAN}$(line)${RESET}"
echo -e "${CYAN}${BOLD}              VPN PANEL INSTALLER${RESET}"
echo -e "${CYAN}$(line)${RESET}"
echo -e "  OS: ${WHITE}${PRETTY_NAME}${RESET}"
echo -e "${CYAN}$(line)${RESET}"
echo ""
read -rp "  Continue with installation? [Y/N]: " ans
[[ "${ans^^}" != "Y" ]] && { warn "Cancelled." ; exit 0; }

# ── Dependencies ────────────────────────────────────────────────
info "Updating packages..."
apt-get update -qq

info "Installing dependencies..."
apt-get install -y -qq \
    git curl wget nano openssl net-tools \
    iptables dnsutils lsb-release gnupg \
    software-properties-common python3 \
    libcurl4-openssl-dev libstdc++6 \
    || err "Failed to install dependencies."

# ── Install panel files ─────────────────────────────────────────
info "Installing panel to $PANEL_DIR..."

REPO_URL="https://github.com/Chechimk/THOMAS2.git"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Always clone — supports both bash <(curl ...) and local execution
info "Cloning panel from GitHub..."
git clone --depth=1 "$REPO_URL" "$TMP_DIR/repo" \
    || err "Failed to clone repository. Check network connection."

SCRIPT_DIR="$TMP_DIR/repo/panel"

mkdir -p "$SBIN_DIR" "$LIB_DIR"

cp -r "$SCRIPT_DIR/lib/"*   "$LIB_DIR/"
cp -r "$SCRIPT_DIR/sbin/"*  "$SBIN_DIR/"
cp    "$SCRIPT_DIR/menu"    "$PANEL_DIR/menu"
cp    "$SCRIPT_DIR/bashrc"  "$PANEL_DIR/bashrc"
cp    "$SCRIPT_DIR/isRoot"  "$PANEL_DIR/isRoot"

# Keep a full git repo in panel dir for update-panel to work
cp -r "$TMP_DIR/repo/.git" "$PANEL_DIR/.git"

chmod +x "$PANEL_DIR/menu"
chmod +x "$LIB_DIR/common.sh"
find "$SBIN_DIR" -type f -exec chmod +x {} \;

# ── Shell integration ────────────────────────────────────────────
grep -qF "source /etc/panel/bashrc" /root/.bashrc \
    || echo "source /etc/panel/bashrc" >> /root/.bashrc

# Install system-wide commands so they work immediately without sourcing bashrc
ln -sf "$PANEL_DIR/menu"            /usr/local/bin/menu
ln -sf "$SBIN_DIR/onlineUser"       /usr/local/bin/monitor
ln -sf "$SBIN_DIR/apiMenu"          /usr/local/bin/api
ln -sf "$SBIN_DIR/bottelegram"      /usr/local/bin/tgbot
ln -sf "$SBIN_DIR/botWhatsapp"      /usr/local/bin/wsbot

cat > /usr/local/bin/update-panel <<'EOF'
#!/bin/bash
git -C /etc/panel pull
EOF
chmod +x /usr/local/bin/update-panel

# ── Auto-update service ──────────────────────────────────────────
cat > /etc/systemd/system/update-panel.service <<EOF
[Unit]
Description=Panel auto-update check
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/git -C ${PANEL_DIR} pull --ff-only

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable update-panel &>/dev/null

# ── Done ─────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}$(line)${RESET}"
ok "Panel installed successfully!"
echo ""
info "Commands available immediately:"
echo -e "  ${BOLD}menu${RESET}          — open the panel"
echo -e "  ${BOLD}monitor${RESET}       — view online users"
echo -e "  ${BOLD}update-panel${RESET}  — update to latest version"
echo -e "${CYAN}$(line)${RESET}"
echo ""
