#!/bin/bash
clear

RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; CYAN=$'\e[36m'
WHITE=$'\e[97m'; RESET=$'\e[0m'; BOLD=$'\e[1m'

ok()   { echo -e "  ${GREEN}[+]${RESET} $1"; }
err()  { echo -e "  ${RED}[-]${RESET} $1" >&2; exit 1; }
warn() { echo -e "  ${YELLOW}[!]${RESET} $1"; }
info() { echo -e "  ${CYAN}[i]${RESET} $1"; }
line() { printf '%60s\n' '' | tr ' ' '═'; }

PANEL_DIR="/etc/panel"
SBIN_DIR="$PANEL_DIR/sbin"
LIB_DIR="$PANEL_DIR/lib"
REPO_URL="https://github.com/Chechimk/THOMAS2.git"

# ── Root check ───────────────────────────────────────────────────
[[ "$(id -u)" -ne 0 ]] && err "Must be run as root."

# ── OS check ─────────────────────────────────────────────────────
. /etc/os-release
[[ "$ID" != "ubuntu" && "$ID" != "debian" ]] && \
    err "Unsupported OS. Requires Ubuntu or Debian."

# ── Uninstall mode ───────────────────────────────────────────────
if [[ "$1" == "--uninstall" ]]; then
    read -rp "  Confirm uninstall? [Y/N]: " ans
    [[ "${ans^^}" != "Y" ]] && exit 0
    rm -rf "$PANEL_DIR"
    rm -f /usr/local/bin/menu /usr/local/bin/monitor \
          /usr/local/bin/update-panel /usr/local/bin/api \
          /usr/local/bin/tgbot /usr/local/bin/wsbot
    sed -i '/source \/etc\/panel\/bashrc/d' /root/.bashrc 2>/dev/null
    systemctl disable --now update-panel 2>/dev/null
    rm -f /etc/systemd/system/update-panel.service
    systemctl daemon-reload 2>/dev/null
    ok "Panel removed."
    exit 0
fi

# ── Header ───────────────────────────────────────────────────────
echo -e "${CYAN}$(line)${RESET}"
echo -e "${CYAN}${BOLD}           VPN PANEL INSTALLER${RESET}"
echo -e "${CYAN}$(line)${RESET}"
echo -e "  OS: ${WHITE}${PRETTY_NAME}${RESET}"
echo -e "${CYAN}$(line)${RESET}"
echo ""
read -rp "  Continue with installation? [Y/N]: " ans
[[ "${ans^^}" != "Y" ]] && exit 0

# ── Dependencies ─────────────────────────────────────────────────
info "Updating packages..."
apt-get update -qq

info "Installing dependencies..."
apt-get install -y -qq \
    git curl wget nano openssl net-tools \
    iptables dnsutils lsb-release gnupg \
    software-properties-common python3 \
    libcurl4-openssl-dev libstdc++6 \
    || err "Failed to install dependencies."

# ── Clone repo ───────────────────────────────────────────────────
info "Cloning panel from GitHub..."
TMP_DIR=$(mktemp -d)
git clone --depth=1 "$REPO_URL" "$TMP_DIR/repo" \
    || err "Failed to clone. Check network connection."

# ── Copy panel files ─────────────────────────────────────────────
info "Installing panel to $PANEL_DIR..."
rm -rf "$PANEL_DIR"
mkdir -p "$SBIN_DIR" "$LIB_DIR"

cp -r "$TMP_DIR/repo/panel/lib/"*   "$LIB_DIR/"
cp -r "$TMP_DIR/repo/panel/sbin/"*  "$SBIN_DIR/"
cp    "$TMP_DIR/repo/panel/menu"    "$PANEL_DIR/menu"
cp    "$TMP_DIR/repo/panel/bashrc"  "$PANEL_DIR/bashrc"
cp    "$TMP_DIR/repo/panel/isRoot"  "$PANEL_DIR/isRoot"

chmod +x "$PANEL_DIR/menu"
chmod +x "$LIB_DIR/common.sh"
chmod +x "$PANEL_DIR/isRoot"
find "$SBIN_DIR" -type f -exec chmod +x {} \;

rm -rf "$TMP_DIR"

# ── System-wide commands ─────────────────────────────────────────
ln -sf "$PANEL_DIR/menu"        /usr/local/bin/menu
ln -sf "$SBIN_DIR/onlineUser"   /usr/local/bin/monitor
ln -sf "$SBIN_DIR/apiMenu"      /usr/local/bin/api
ln -sf "$SBIN_DIR/bottelegram"  /usr/local/bin/tgbot
ln -sf "$SBIN_DIR/botWhatsapp"  /usr/local/bin/wsbot

cat > /usr/local/bin/update-panel <<'UPDATESCRIPT'
#!/bin/bash
rm -f /root/install.sh
wget --no-cache -qO /root/install.sh \
    https://raw.githubusercontent.com/Chechimk/THOMAS2/main/panel/install.sh
chmod +x /root/install.sh
bash /root/install.sh
UPDATESCRIPT
chmod +x /usr/local/bin/update-panel

# ── Bashrc integration ───────────────────────────────────────────
grep -qF "source /etc/panel/bashrc" /root/.bashrc 2>/dev/null \
    || echo "source /etc/panel/bashrc" >> /root/.bashrc

# ── Done ─────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}$(line)${RESET}"
ok "Panel installed successfully!"
echo ""
echo -e "  ${CYAN}[*]${RESET} Commands ready:"
echo -e "      ${BOLD}menu${RESET}          — open the panel"
echo -e "      ${BOLD}monitor${RESET}       — view online users"
echo -e "      ${BOLD}update-panel${RESET}  — update to latest"
echo -e "${CYAN}$(line)${RESET}"
echo ""
