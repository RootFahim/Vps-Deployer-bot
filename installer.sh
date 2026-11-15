#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#   ██████╗  ██████╗  ██████╗ ████████╗███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗
#   ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██║  ██║██║████╗ ████║
#   ██████╔╝██║   ██║██║   ██║   ██║   █████╗  ███████║███████║██║██╔████╔██║
#   ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║
#   ██║  ██║╚██████╔╝╚██████╔╝   ██║   ██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║
#   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
# ═══════════════════════════════════════════════════════════════
#              RFRS LXC BOT 1.0 PRO - AUTO INSTALLER
#                   Powered by: ROOTFAHIM
# ═══════════════════════════════════════════════════════════════

set -e

# ─── Color Codes ───
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BLINK='\033[5m'
BOLD='\033[1m'

# ─── RootFahim Watermark (used everywhere) ───
WM="${MAGENTA}[ROOTFAHIM]${NC}"
LINE="${CYAN}═══════════════════════════════════════════════════════════════${NC}"

# ─── Utility Functions ───
typewriter() {
    local text="$1"
    local delay="${2:-0.01}"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

spinner() {
    local pid=$1
    local message="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r${CYAN}${spin:$i:1}${NC} ${message} ${WM}  "
        sleep 0.1
    done
    printf "\r${GREEN}✔${NC} ${message} ${WM}  \n"
}

progress_bar() {
    local duration=$1
    local msg="$2"
    local steps=30
    echo -ne "${BLUE}${msg}${NC} ${WM}\n"
    echo -ne "${YELLOW}[${NC}"
    for ((i=0; i<steps; i++)); do
        echo -ne "${GREEN}█${NC}"
        sleep "$(echo "scale=3; $duration/$steps" | bc 2>/dev/null || echo 0.03)"
    done
    echo -e "${YELLOW}]${NC} ${GREEN}100%${NC} ${WM}\n"
}

banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
   ██████╗  ██████╗  ██████╗ ████████╗███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗
   ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██║  ██║██║████╗ ████║
   ██████╔╝██║   ██║██║   ██║   ██║   █████╗  ███████║███████║██║██╔████╔██║
   ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║
   ██║  ██║╚██████╔╝╚██████╔╝   ██║   ██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║
   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
EOF
    echo -e "${NC}"
    echo -e "${MAGENTA}${BOLD}        ╔══════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}${BOLD}        ║   RFRS LXC BOT 1.0 PRO - AUTO INSTALLER      ║${NC}"
    echo -e "${MAGENTA}${BOLD}        ║           Powered by: ROOTFAHIM              ║${NC}"
    echo -e "${MAGENTA}${BOLD}        ╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

section_header() {
    echo ""
    echo -e "${LINE}"
    echo -e "${MAGENTA}${BOLD}  ▶ $1  ${WM}${NC}"
    echo -e "${LINE}"
}

success_msg() {
    echo -e "${GREEN}✔ $1${NC} ${WM}"
}

error_msg() {
    echo -e "${RED}✘ $1${NC} ${WM}"
    exit 1
}

info_msg() {
    echo -e "${BLUE}ℹ $1${NC} ${WM}"
}

warn_msg() {
    echo -e "${YELLOW}⚠ $1${NC} ${WM}"
}

# ─── Root Check ───
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✘ This installer must be run as root!${NC} ${WM}"
    echo -e "${YELLOW}  Try: sudo bash installer.sh${NC}"
    exit 1
fi

# ─── Intro Animation ───
banner
typewriter "${CYAN}  Initializing RFRS Bot Installer...${NC}" 0.02
sleep 0.3
progress_bar 1.5 "  ${YELLOW}Loading installer modules${NC}"

# ═══════════════════════════════════════════════════════════════
#  STEP 1: Install system dependencies
# ═══════════════════════════════════════════════════════════════
section_header "STEP 1/8 :: Installing System Dependencies"

info_msg "Updating package lists..."
apt-get update -y >/dev/null 2>&1 &
spinner $! "Updating apt cache"

apt-get install -y git curl wget nano python3 python3-pip >/dev/null 2>&1 &
spinner $! "Installing git, python3, pip, nano"

success_msg "System dependencies installed"

# ═══════════════════════════════════════════════════════════════
#  STEP 2: Clone Repository
# ═══════════════════════════════════════════════════════════════
section_header "STEP 2/8 :: Cloning Vps-Deployer-bot Repository"

cd /root
if [ -d "Vps-Deployer-bot" ]; then
    warn_msg "Existing directory found, removing old copy..."
    rm -rf Vps-Deployer-bot
fi

git clone https://github.com/RootFahim/Vps-Deployer-bot >/dev/null 2>&1 &
spinner $! "Cloning from github.com/RootFahim/Vps-Deployer-bot"

if [ ! -d "Vps-Deployer-bot" ]; then
    error_msg "Failed to clone repository! Check internet connection."
fi
success_msg "Repository cloned to /root/Vps-Deployer-bot"

# ═══════════════════════════════════════════════════════════════
#  STEP 3: Install Python Packages
# ═══════════════════════════════════════════════════════════════
section_header "STEP 3/8 :: Installing Python Packages"

cd /root/Vps-Deployer-bot

info_msg "Installing: discord.py, python-dotenv, aiohttp"

pip install --break-system-packages --quiet "discord.py>=2.4.0" >/dev/null 2>&1 &
spinner $! "Installing discord.py>=2.4.0"

pip install --break-system-packages --quiet "python-dotenv>=1.0.0" >/dev/null 2>&1 &
spinner $! "Installing python-dotenv>=1.0.0"

pip install --break-system-packages --quiet "aiohttp>=3.9.0" >/dev/null 2>&1 &
spinner $! "Installing aiohttp>=3.9.0"

success_msg "All Python packages installed successfully"

# ═══════════════════════════════════════════════════════════════
#  STEP 4: Setup .env File (Interactive Variable Input)
# ═══════════════════════════════════════════════════════════════
section_header "STEP 4/8 :: Configuring Environment Variables"

ENV_FILE="/root/Vps-Deployer-bot/.env"

# Backup test.env if exists
if [ -f "/root/Vps-Deployer-bot/test.env" ] && [ ! -f "$ENV_FILE" ]; then
    cp /root/Vps-Deployer-bot/test.env "$ENV_FILE"
    info_msg "Copied test.env → .env (template)"
fi

touch "$ENV_FILE"

echo ""
echo -e "${YELLOW}${BOLD}  ┌─────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}${BOLD}  │     ENVIRONMENT VARIABLE CONFIGURATION           │${NC}"
echo -e "${YELLOW}${BOLD}  │     Press ENTER to keep existing/default        │${NC}"
echo -e "${YELLOW}${BOLD}  └─────────────────────────────────────────────────┘${NC}"
echo ""

# Function to get existing value from .env
get_env_value() {
    local key="$1"
    if [ -f "$ENV_FILE" ]; then
        grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | head -n1 | cut -d'=' -f2- || true
    fi
}

# Function to set/replace value in .env
set_env_value() {
    local key="$1"
    local value="$2"
    if grep -qE "^${key}=" "$ENV_FILE" 2>/dev/null; then
        # Escape special chars for sed
        local esc=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')
        sed -i "s|^${key}=.*|${key}=${esc}|" "$ENV_FILE"
    else
        echo "${key}=${value}" >> "$ENV_FILE"
    fi
}

# List of variables to prompt for
# You can add more here — they will be prompted automatically
VARIABLES=(
    "DISCORD_BOT_TOKEN"
    "DISCORD_GUILD_ID"
    "DISCORD_CATEGORY_ID"
    "OWNER_ID"
    "LXD_API_URL"
)

for VAR in "${VARIABLES[@]}"; do
    EXISTING=$(get_env_value "$VAR")
    if [ -n "$EXISTING" ]; then
        echo -e "${CYAN}  ${VAR}=${NC}${WHITE}${EXISTING}${NC}  ${YELLOW}(existing)${NC}"
        read -rp "  ${YELLOW}→ Set new ${VAR} [Enter to keep]: ${NC}" NEW_VAL
        if [ -n "$NEW_VAL" ]; then
            set_env_value "$VAR" "$NEW_VAL"
            echo -e "  ${GREEN}✔ ${VAR} updated${NC} ${WM}"
        else
            echo -e "  ${BLUE}ℹ ${VAR} unchanged${NC} ${WM}"
        fi
    else
        echo -e "${CYAN}  Setting up ${VAR}=${NC}"
        read -rp "  ${YELLOW}→ Enter ${VAR}: ${NC}" NEW_VAL
        if [ -n "$NEW_VAL" ]; then
            set_env_value "$VAR" "$NEW_VAL"
            echo -e "  ${GREEN}✔ ${VAR} saved to .env${NC} ${WM}"
        else
            warn_msg "${VAR} is empty (skipped). You can edit .env later."
        fi
    fi
    sleep 0.2
done

success_msg ".env file configured at $ENV_FILE"
echo ""
info_msg "You can edit later: nano $ENV_FILE"

# ═══════════════════════════════════════════════════════════════
#  STEP 5: Copy Bot Files to /opt/rfrs-bot
# ═══════════════════════════════════════════════════════════════
section_header "STEP 5/8 :: Deploying Bot Files to /opt/rfrs-bot"

mkdir -p /opt/rfrs-bot
cp -r /root/Vps-Deployer-bot/* /opt/rfrs-bot/ 2>/dev/null || true
cp -r /root/Vps-Deployer-bot/.[!.]* /opt/rfrs-bot/ 2>/dev/null || true

if [ ! -f "/opt/rfrs-bot/bot.py" ]; then
    warn_msg "bot.py not found in expected location — checking repo structure..."
    ls /opt/rfrs-bot/
fi

success_msg "Bot files deployed to /opt/rfrs-bot"

# ═══════════════════════════════════════════════════════════════
#  STEP 6: Create systemd Service
# ═══════════════════════════════════════════════════════════════
section_header "STEP 6/8 :: Creating systemd Service (rfrs-bot)"

SERVICE_FILE="/etc/systemd/system/rfrs-bot.service"

cat > "$SERVICE_FILE" <<EOF
# ═══════════════════════════════════════════════════════════════
#   RFRS LXC BOT 1.0 PRO - systemd service
#   Powered by ROOTFAHIM
# ═══════════════════════════════════════════════════════════════
[Unit]
Description=RFRS LXC BOT 1.0 PRO (RootFahim)
After=network-online.target snap.lxd.daemon.service
Wants=network-online.target

[Service]
User=root
WorkingDirectory=/opt/rfrs-bot
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
EnvironmentFile=/opt/rfrs-bot/.env
ExecStart=/usr/bin/python3 /opt/rfrs-bot/bot.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
# ─── ROOTFAHIM WATERMARK ───
SyslogIdentifier=rfrs-bot-rootfahim

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$SERVICE_FILE"
success_msg "Service file created: $SERVICE_FILE"

# ═══════════════════════════════════════════════════════════════
#  STEP 7: Enable & Start Service
# ═══════════════════════════════════════════════════════════════
section_header "STEP 7/8 :: Enabling & Starting rfrs-bot Service"

systemctl daemon-reload >/dev/null 2>&1 &
spinner $! "Reloading systemd daemon"

systemctl enable rfrs-bot >/dev/null 2>&1 &
spinner $! "Enabling rfrs-bot at boot"

systemctl restart rfrs-bot >/dev/null 2>&1 &
spinner $! "Starting rfrs-bot service"

sleep 3

# ═══════════════════════════════════════════════════════════════
#  STEP 8: Verify & Show Status
# ═══════════════════════════════════════════════════════════════
section_header "STEP 8/8 :: Installation Summary"

sleep 0.5
echo ""
echo -e "${LINE}"
echo -e "${MAGENTA}${BOLD}       🎉 RFRS LXC BOT 1.0 PRO - INSTALLATION COMPLETE 🎉${NC}"
echo -e "${MAGENTA}${BOLD}                    Powered by ROOTFAHIM${NC}"
echo -e "${LINE}"
echo ""
echo -e "  ${CYAN}📦 Repository     :${NC} /root/Vps-Deployer-bot"
echo -e "  ${CYAN}⚙️  Bot Install    :${NC} /opt/rfrs-bot"
echo -e "  ${CYAN}🔐 Env File       :${NC} /opt/rfrs-bot/.env"
echo -e "  ${CYAN}🛠️  Service File   :${NC} /etc/systemd/system/rfrs-bot.service"
echo -e "  ${CYAN}🌐 Service Name   :${NC} rfrs-bot"
echo ""
echo -e "${LINE}"
echo -e "${YELLOW}${BOLD}  📋 SERVICE STATUS:${NC}  ${WM}"
echo -e "${LINE}"

systemctl status rfrs-bot --no-pager -l | head -20 || true

echo ""
echo -e "${LINE}"
echo -e "${GREEN}${BOLD}  ✅ COMMON COMMANDS:${NC}"
echo -e "${LINE}"
echo -e "  ${WHITE}▶ Start      :${NC} systemctl start rfrs-bot"
echo -e "  ${WHITE}▶ Stop       :${NC} systemctl stop rfrs-bot"
echo -e "  ${WHITE}▶ Restart    :${NC} systemctl restart rfrs-bot"
echo -e "  ${WHITE}▶ Status     :${NC} systemctl status rfrs-bot"
echo -e "  ${WHITE}▶ Live Logs  :${NC} journalctl -u rfrs-bot -f"
echo -e "  ${WHITE}▶ Edit .env  :${NC} nano /opt/rfrs-bot/.env"
echo -e "${LINE}"
echo ""
echo -e "${MAGENTA}${BOLD}  💡 Tip:${NC} If bot doesn't respond, check logs with:"
echo -e "     ${CYAN}journalctl -u rfrs-bot -n 100 --no-pager${NC}"
echo ""
echo -e "${LINE}"
echo -e "${MAGENTA}${BOLD}           ❤️  Thanks for using ROOTFAHIM's RFRS Installer  ❤️${NC}"
echo -e "${LINE}"
echo ""

# ─── Final animated flourish ───
typewriter "${GREEN}  Setup finished successfully. Enjoy your bot! 🚀${NC}" 0.015
echo ""
