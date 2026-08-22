# VPN Panel Manager

Open-source VPN panel for Ubuntu/Debian — SSH, V2Ray, Xray, OpenVPN, Stunnel, WireGuard and more.

## Install

```bash
rm -rf /root/install.sh; wget --no-cache -O /root/install.sh https://raw.githubusercontent.com/Chechimk/THOMAS2/main/panel/install.sh; chmod +x /root/install.sh; bash /root/install.sh
```

> Requires root on Ubuntu 20.04 / 22.04 / 24.04 / Debian 10 / 11.

## Usage

After install, type:

```bash
menu        # open the panel
monitor     # view online users
update-panel  # pull latest updates
```

## Modules

| Section | Features |
|---|---|
| **Accounts** | Add/remove/block SSH users, expiry, online monitor |
| **Protocols** | SSH, V2Ray, Xray (WS / XHTTP / gRPC / Reality), OpenVPN, Stunnel, WireGuard, UDP-Custom, WS-ePro |
| **Tools** | SSL certs (acme.sh), Firewall, Fail2Ban, DDoS, BBR, Speed test, Timezone |

## Uninstall

```bash
bash /etc/panel/install --uninstall
```
