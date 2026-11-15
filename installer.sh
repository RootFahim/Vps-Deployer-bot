#!/bin/bash

# ═══════════════════════════════════════════════════════════════
#   ██████╗  ██████╗  ███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗
#   ██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║  ██║██║████╗ ████║
#   ██████╔╝██║   ██║█████╗  ███████║███████║██║██╔████╔██║
#   ██╔══██╗██║   ██║██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║
#   ██║  ██║╚██████╔╝██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║
#   ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
#                                                                
#           ⚡ RFRS VPS DEPLOYER BOT - INSTALLER v2.0 ⚡         
#                    © RootFahim | All Rights Reserved           
# ═══════════════════════════════════════════════════════════════

set -e

# ─── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
BLINK='\033[5m'

# ─── Watermark ─────────────────────────────────────────────────
WM="${MAGENTA}[${CYAN}ROOTFAHIM${MAGENTA}]${NC}"

# ─── Animation Functions ───────────────────────────────────────
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a -p "$pid" | awk '{print $5}' | sed 's/[0-9]//g' | sed 's/ //g')" != "" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN}[${MAGENTA}%c${CYAN}]${NC} " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "    \r"
}

typing() {
    local text="$1"
    local delay="${2:-0.02}"
    for (( i=0; i<${#text}; i++ )); do
        printf "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

progress_bar() {
    local duration=$1
    local msg="${2:-Processing}"
    local bar_len=40
    echo -e "\n${WM} ${CYAN}${msg}...${NC}"
    for (( i=0; i<=bar_len; i++ )); do
        local filled=$(printf "%${i}s" | tr ' ' '█')
        local empty=$(printf "%$((bar_len-i))s" | tr ' ' '░')
        local percent=$((i * 100 / bar_len))
        printf "\r${WM} ${GREEN}[${filled}${WHITE}${empty}${GREEN}]${YELLOW} ${percent}%%${NC}"
        sleep $(echo "scale=3; $duration/$bar_len" | bc)
    done
    echo -e "\n${WM} ${GREEN}✅ ${msg} Complete!${NC}\n"
}

line() {
    echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
}

wm_line() {
    echo -e "${WM} ${CYAN}$1${NC}"
}

success() { echo -e "${WM} ${GREEN}✅ $1${NC}"; }
info()    { echo -e "${WM} ${BLUE}ℹ️  $1${NC}"; }
warn()    { echo -e "${WM} ${YELLOW}⚠️  $1${NC}"; }
error()   { echo -e "${WM} ${RED}❌ $1${NC}"; }

# ─── Watermark Everywhere Footer ──────────────────────────────
footer() {
    line
    echo -e "${WM} ${MAGENTA}▓▒░ ROOTFAHIM © $(date +%Y) ░▒▓${NC}"
    echo -e "${WM} ${CYAN}GitHub: https://github.com/RootFahim${NC}"
    line
}

# ─── Banner ───────────────────────────────────────────────────
clear
echo -e "${CYAN}"
cat << "EOF"
    ██████╗  ██████╗  ███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗
    ██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║  ██║██║████╗ ████║
    ██████╔╝██║   ██║█████╗  ███████║███████║██║██╔████╔██║
    ██╔══██╗██║   ██║██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║
    ██║  ██║╚██████╔╝██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
EOF
echo -e "${NC}"
echo -e "${MAGENTA}          ⚡ RFRS VPS DEPLOYER BOT - INSTALLER v2.0 ⚡${NC}"
echo -e "${CYAN}               © RootFahim | All Rights Reserved${NC}"
line
echo -e "${WM} ${WHITE}${BOLD}Welcome to the Ultimate Installer!${NC}"
echo -e "${WM} ${YELLOW}Ye installer pura setup karega automatically 🚀${NC}"
line
sleep 1.5

# ─── Root Check ───────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    error "Bhai root user se run karo! Use: sudo bash installer.sh"
    exit 1
fi
success "Root privileges confirmed"

# ─── OS Detection ─────────────────────────────────────────────
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
    info "Detected OS: $PRETTY_NAME"
else
    warn "OS detection failed, assuming Debian-based"
fi

# ─── STEP 1: System Update ────────────────────────────────────
line
wm_line "STEP 1/7 → Updating System Packages"
line
progress_bar 1.5 "Updating apt cache"
apt update -y > /dev/null 2>&1 &
spinner $!
success "System packages updated"

# ─── STEP 2: Install Dependencies ─────────────────────────────
line
wm_line "STEP 2/7 → Installing System Dependencies"
line

deps=(git python3 python3-pip curl nano)
for dep in "${deps[@]}"; do
    if dpkg -s "$dep" >/dev/null 2>&1; then
        success "$dep already installed"
    else
        info "Installing $dep..."
        apt install -y "$dep" > /dev/null 2>&1 &
        spinner $!
        success "$dep installed"
    fi
done

# ─── STEP 3: Clone Repository ─────────────────────────────────
line
wm_line "STEP 3/7 → Cloning RootFahim's VPS Deployer Bot"
line

INSTALL_DIR="/opt/rfrs-bot"
if [ -d "/root/Vps-Deployer-bot" ]; then
    warn "Repo already exists, pulling latest..."
    cd /root/Vps-Deployer-bot && git pull > /dev/null 2>&1 &
    spinner $!
else
    progress_bar 2 "Cloning from GitHub"
    cd /root
    git clone https://github.com/RootFahim/Vps-Deployer-bot > /dev/null 2>&1 &
    spinner $!
    cd Vps-Deployer-bot
fi

# Move to /opt for systemd
rm -rf "$INSTALL_DIR"
cp -r /root/Vps-Deployer-bot "$INSTALL_DIR"
success "Bot files ready at $INSTALL_DIR"

# ─── STEP 4: Install Python Packages ──────────────────────────
line
wm_line "STEP 4/7 → Installing Python Libraries"
line

pkgs=("discord.py>=2.4.0" "python-dotenv>=1.0.0" "aiohttp>=3.9.0")
for p in "${pkgs[@]}"; do
    info "Installing ${p}..."
    pip install --break-system-packages "$p" > /dev/null 2>&1 &
    spinner $!
    success "${p} installed"
done

# ─── STEP 5: Setup .env Config ────────────────────────────────
line
wm_line "STEP 5/7 → Configure Environment Variables (.env)"
line

cd "$INSTALL_DIR"
[ -f test.env ] && cp test.env .env

echo -e "${WM} ${CYAN}Bhai, ab tum apne Discord bot ke credentials daalo.${NC}"
echo -e "${WM} ${YELLOW}(Enter dabao blank chhodne ke liye - baad me edit kar sakte ho)${NC}"
line

# Variables setup with visible watermark
declare -A VARS=(
    ["DISCORD_BOT_TOKEN"]="Discord Bot Token"
    ["DISCORD_APPLICATION_ID"]="Discord Application ID"
    ["DISCORD_GUILD_ID"]="Discord Guild/Server ID"
    ["DISCORD_LOG_CHANNEL_ID"]="Log Channel ID"
    ["DISCORD_ADMIN_ROLE_ID"]="Admin Role ID"
)

for key in "${!VARS[@]}"; do
    prompt_label="${VARS[$key]}"
    echo -e "${WM} ${GREEN}→${NC} ${BOLD}${prompt_label}${NC}"
    printf "${WM} ${CYAN}${key}${NC}=${WHITE}"
    read -r value
    echo -e "${NC}"
    if [ -n "$value" ]; then
        # Update or append
        if grep -q "^${key}=" .env 2>/dev/null; then
            sed -i "s|^${key}=.*|${key}=${value}|" .env
        else
            echo "${key}=${value}" >> .env
        fi
        success "${key} configured"
    else
        warn "${key} skipped (edit .env later)"
    fi
done

chmod 600 .env
success ".env file secured (chmod 600)"

# ─── STEP 6: Create systemd Service ───────────────────────────
line
wm_line "STEP 6/7 → Creating systemd Service (rfrs-bot.service)"
line

SERVICE_FILE="/etc/systemd/system/rfrs-bot.service"
cat > "$SERVICE_FILE" << EOF
# ═══════════════════════════════════════════════════════════
#   RFRS LXC BOT 1.0 PRO — Managed by RootFahim Installer
#   © RootFahim | https://github.com/RootFahim
# ═══════════════════════════════════════════════════════════
[Unit]
Description=RFRS LXC BOT 1.0 PRO | Powered by RootFahim
After=network-online.target snap.lxd.daemon.service
Wants=network-online.target

[Service]
User=root
WorkingDirectory=${INSTALL_DIR}
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
ExecStart=/usr/bin/python3 ${INSTALL_DIR}/bot.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

progress_bar 1 "Writing service file"
success "Service file created at $SERVICE_FILE"

systemctl daemon-reload > /dev/null 2>&1 &
spinner $!
success "systemd daemon reloaded"

# ─── STEP 7: Start Bot ────────────────────────────────────────
line
wm_line "STEP 7/7 → Enabling & Starting Bot Service"
line

systemctl enable rfrs-bot > /dev/null 2>&1 &
spinner $!
success "Service enabled on boot"

systemctl start rfrs-bot > /dev/null 2>&1 &
spinner $!
success "Bot service started"

sleep 2
line
wm_line "Service Status:"
line
systemctl status rfrs-bot --no-pager -l || true

# ─── FINAL SUMMARY ────────────────────────────────────────────
line
echo -e "${GREEN}${BOLD}"
cat << "EOF"
   ╔═══════════════════════════════════════════════════════╗
   ║     🎉  INSTALLATION COMPLETED SUCCESSFULLY!  🎉     ║
   ║              RFRS VPS DEPLOYER BOT v2.0              ║
   ║                  © RootFahim 2025                    ║
   ╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
line

wm_line "${BOLD}Useful Commands:${NC}"
echo -e "${WM} ${CYAN}• Check status  :${NC} systemctl status rfrs-bot"
echo -e "${WM} ${CYAN}• View logs     :${NC} journalctl -u rfrs-bot -f"
echo -e "${WM} ${CYAN}• Restart bot   :${NC} systemctl restart rfrs-bot"
echo -e "${WM} ${CYAN}• Stop bot      :${NC} systemctl stop rfrs-bot"
echo -e "${WM} ${CYAN}• Edit .env     :${NC} nano ${INSTALL_DIR}/.env"
line

wm_line "${BOLD}Installation Paths:${NC}"
echo -e "${WM} ${CYAN}• Bot directory :${NC} ${INSTALL_DIR}"
echo -e "${WM} ${CYAN}• Service file  :${NC} ${SERVICE_FILE}"
echo -e "${WM} ${CYAN}• Env file      :${NC} ${INSTALL_DIR}/.env"
line

echo -e "${WM} ${MAGENTA}${BOLD}Thank you for using RootFahim's installer! ❤️${NC}"
footer
