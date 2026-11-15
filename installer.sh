#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  ██████╗  ██████╗  ██████╗ ████████╗███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗
#  ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██║  ██║██║████╗ ████║
#  ██████╔╝██║   ██║██║   ██║   ██║   █████╗  ███████║███████║██║██╔████╔██║
#  ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║
#  ██║  ██║╚██████╔╝╚██████╔╝   ██║   ██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║
#  ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
#                                                                            
#              VPS DEPLOYER BOT - ULTIMATE INSTALLER v1.0
#                        © RootFahim | RFRS BOT
# ═══════════════════════════════════════════════════════════════════════════

# ─────────────────────── COLOR CODES ───────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
BLINK='\033[5m'

# ─────────────────────── WATERMARK ───────────────────────
WM="${DIM}${PURPLE}[RootFahim]${NC}"
TAG="${DIM}${CYAN}» RFRS BOT «${NC}"

# ─────────────────────── ROOT CHECK ───────────────────────
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}${BOLD}✗ This installer must be run as root!${NC}"
   echo -e "${YELLOW}  Try: ${WHITE}sudo bash installer.sh${NC}"
   exit 1
fi

# ─────────────────────── HELPER FUNCTIONS ───────────────────────
print_watermark() {
    echo -e "${WM} ${TAG} ${DIM}${PURPLE}$1${NC}"
}

typing_effect() {
    local text="$1"
    local color="${2:-$CYAN}"
    local delay="${3:-0.02}"
    for (( i=0; i<${#text}; i++ )); do
        printf "${color}${text:$i:1}${NC}"
        sleep "$delay"
    done
    echo
}

spinner() {
    local pid=$1
    local message="$2"
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 8 ))
        printf "\r${WM} ${YELLOW}${spin:$i:1}${NC} ${message}"
        sleep 0.1
    done
    printf "\r${WM} ${GREEN}✔${NC} ${message} ${GREEN}DONE${NC}\n"
}

success() {
    echo -e "${WM} ${GREEN}✔${NC} ${GREEN}${BOLD}$1${NC}"
}

info() {
    echo -e "${WM} ${CYAN}ℹ${NC} ${CYAN}$1${NC}"
}

warn() {
    echo -e "${WM} ${YELLOW}⚠${NC} ${YELLOW}$1${NC}"
}

error() {
    echo -e "${WM} ${RED}✗${NC} ${RED}${BOLD}$1${NC}"
}

separator() {
    echo -e "${DIM}${PURPLE}═══════════════════════════════════════════════════════════════════════════${NC}"
}

step_header() {
    local step="$1"
    local title="$2"
    echo
    separator
    echo -e "${WM} ${BOLD}${CYAN}  STEP ${step} ${NC}${BOLD}${WHITE}» ${title}${NC}"
    separator
    echo
}

# ─────────────────────── BANNER ───────────────────────
show_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║    ██████╗  ██████╗  ██████╗ ████████╗███████╗ █████╗ ██╗  ██╗   ║
    ║    ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██║  ██║   ║
    ║    ██████╔╝██║   ██║██║   ██║   ██║   █████╗  ███████║███████║   ║
    ║    ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██║██╔══██║   ║
    ║    ██║  ██║╚██████╔╝╚██████╔╝   ██║   ██║     ██║  ██║██║  ██║   ║
    ║    ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ║
    ║                                                                  ║
    ║              ⚡ VPS DEPLOYER BOT INSTALLER v1.0 ⚡                 ║
    ║                    © RootFahim | RFRS BOT                        ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${DIM}${PURPLE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DIM}${PURPLE}  │${NC}  ${CYAN}🐍 Python3${NC}    ${GREEN}●${NC} Ready    ${CYAN}📦 Discord.py${NC}  ${GREEN}●${NC} v2.4+   ${DIM}${PURPLE}│${NC}"
    echo -e "${DIM}${PURPLE}  │${NC}  ${CYAN}🖥  Systemd${NC}    ${GREEN}●${NC} Ready    ${CYAN}🔐 DotEnv${NC}      ${GREEN}●${NC} Loaded  ${DIM}${PURPLE}│${NC}"
    echo -e "${DIM}${PURPLE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    typing_effect "      🚀 Initializing RootFahim's Ultimate Installer..." "$PURPLE" 0.01
    echo
    sleep 0.5
}

# ─────────────────────── ENV SETUP ───────────────────────
setup_env_interactive() {
    local ENV_FILE="$1"
    
    step_header "5" "Interactive .env Configuration"
    
    warn "Please provide the required environment variables."
    warn "Press ${BOLD}ENTER${NC}${YELLOW} to skip (default value will be used if applicable)."
    echo
    
    # Backup existing .env
    if [[ -f "$ENV_FILE" ]]; then
        cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%s)"
        info "Existing .env backed up"
    fi
    
    echo -e "${DIM}${PURPLE}─────────────────────── CONFIGURING VARIABLES ───────────────────────${NC}"
    echo
    
    # Prompt for variables
    declare -A vars
    vars["DISCORD_BOT_TOKEN"]="Discord Bot Token (from discord.com/developers)"
    vars["GUILD_ID"]="Discord Server/Guild ID"
    vars["ADMIN_ROLE_ID"]="Admin Role ID (users allowed to deploy)"
    vars["LOG_CHANNEL_ID"]="Log Channel ID (for deploy logs)"
    vars["LXC_HOST_NAME"]="LXC Host Name (e.g., rfrs-vps-01)"
    vars["MAX_CONTAINERS"]="Max Containers per User (default: 2)"
    vars["DEFAULT_OS"]="Default OS Template (default: ubuntu/22.04)"
    vars["DEFAULT_RAM"]="Default RAM in MB (default: 1024)"
    vars["DEFAULT_CPU"]="Default CPU Cores (default: 1)"
    vars["DEFAULT_DISK"]="Default Disk in GB (default: 10)"
    
    # Default values
    declare -A defaults
    defaults["MAX_CONTAINERS"]="2"
    defaults["DEFAULT_OS"]="ubuntu/22.04"
    defaults["DEFAULT_RAM"]="1024"
    defaults["DEFAULT_CPU"]="1"
    defaults["DEFAULT_DISK"]="10"
    
    > "$ENV_FILE"
    echo "# ═══════════════════════════════════════════════════════" >> "$ENV_FILE"
    echo "#  RootFahim VPS Deployer Bot - Environment Config       " >> "$ENV_FILE"
    echo "#  Generated: $(date)                                    " >> "$ENV_FILE"
    echo "# ═══════════════════════════════════════════════════════" >> "$ENV_FILE"
    echo "" >> "$ENV_FILE"
    
    for key in "${!vars[@]}"; do
        local desc="${vars[$key]}"
        local default="${defaults[$key]:-}"
        local prompt="${WM} ${CYAN}${key}${NC}"
        
        if [[ -n "$default" ]]; then
            echo -e "  ${prompt}"
            echo -e "  ${DIM}  ↳ ${desc}${NC}"
            read -rp "  ${YELLOW}  ▸ Enter value [${GREEN}${default}${YELLOW}]: ${NC}" value
            value="${value:-$default}"
        else
            echo -e "  ${prompt}"
            echo -e "  ${DIM}  ↳ ${desc}${NC}"
            read -rp "  ${YELLOW}  ▸ Enter value: ${NC}" value
            while [[ -z "$value" ]]; do
                error "This field is required!"
                read -rp "  ${YELLOW}  ▸ Enter value: ${NC}" value
            done
        fi
        
        echo "${key}=${value}" >> "$ENV_FILE"
        echo -e "  ${GREEN}  ✔ Set: ${key}=${value}${NC}"
        echo
    done
    
    echo "# ─── Auto Appended by RootFahim Installer ───" >> "$ENV_FILE"
    echo "RFRS_WATERMARK=RootFahim" >> "$ENV_FILE"
    echo "RFRS_VERSION=1.0" >> "$ENV_FILE"
    
    echo
    success "Environment configuration saved to ${ENV_FILE}"
    echo
    echo -e "${DIM}${PURPLE}─────────────────────── .env PREVIEW ───────────────────────${NC}"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == "#"* ]] && echo -e "${DIM}${line}${NC}" && continue
        if [[ "$line" == *"="* ]]; then
            k="${line%%=*}"; v="${line#*=}"
            if [[ "$k" == *"TOKEN"* ]] || [[ "$k" == *"KEY"* ]] || [[ "$k" == *"SECRET"* ]]; then
                echo -e "${WM} ${CYAN}${k}${NC}=${DIM}••••••••••••••••${NC}"
            else
                echo -e "${WM} ${CYAN}${k}${NC}=${WHITE}${v}${NC}"
            fi
        fi
    done < "$ENV_FILE"
    echo -e "${DIM}${PURPLE}────────────────────────────────────────────────────────────${NC}"
    echo
    read -rp "$(echo -e "${WM} ${YELLOW}Continue with these settings? [Y/n]: ${NC}")" confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        warn "Re-running environment setup..."
        setup_env_interactive "$ENV_FILE"
    fi
}

# ─────────────────────── MAIN INSTALLER ───────────────────────
main() {
    show_banner
    
    sleep 0.3
    typing_effect "      ⚠  Running as ROOT — All system changes will be applied" "$YELLOW" 0.015
    echo
    sleep 1
    
    # ═════════ STEP 1: System Update & Dependencies ═════════
    step_header "1" "Installing System Dependencies"
    
    (apt-get update -qq >/dev/null 2>&1) &
    spinner $! "Updating package lists..."
    
    (apt-get install -y -qq git python3-pip python3-venv nano curl wget >/dev/null 2>&1) &
    spinner $! "Installing git, python3-pip, nano & tools..."
    
    success "System dependencies ready"
    
    # ═════════ STEP 2: Clone Repository ═════════
    step_header "2" "Cloning Repository"
    
    cd /root || error "Cannot cd to /root"
    if [[ -d "Vps-Deployer-bot" ]]; then
        warn "Directory Vps-Deployer-bot already exists — removing old copy"
        rm -rf Vps-Deployer-bot
    fi
    
    (git clone -q https://github.com/RootFahim/Vps-Deployer-bot >/dev/null 2>&1) &
    spinner $! "Cloning https://github.com/RootFahim/Vps-Deployer-bot"
    
    if [[ ! -d "Vps-Deployer-bot" ]]; then
        error "Clone failed! Check network / repo URL"
        exit 1
    fi
    success "Repository cloned to /root/Vps-Deployer-bot"
    
    cd Vps-Deployer-bot || error "Cannot enter repo directory"
    
    # ═════════ STEP 3: Python Dependencies ═════════
    step_header "3" "Installing Python Packages"
    
    (pip install --break-system-packages -q "discord.py>=2.4.0" >/dev/null 2>&1) &
    spinner $! "Installing discord.py >= 2.4.0"
    
    (pip install --break-system-packages -q "python-dotenv>=1.0.0" >/dev/null 2>&1) &
    spinner $! "Installing python-dotenv >= 1.0.0"
    
    (pip install --break-system-packages -q "aiohttp>=3.9.0" >/dev/null 2>&1) &
    spinner $! "Installing aiohttp >= 3.9.0"
    
    success "All Python packages installed"
    
    # ═════════ STEP 4: Prepare .env ═════════
    step_header "4" "Preparing .env File"
    
    if [[ -f "test.env" ]]; then
        cp test.env .env
        success "Copied test.env → .env template"
    else
        touch .env
        warn "test.env not found, created empty .env"
    fi
    
    # ═════════ STEP 5: Interactive .env Setup ═════════
    setup_env_interactive "/root/Vps-Deployer-bot/.env"
    
    # ═════════ STEP 6: Create Service ═════════
    step_header "6" "Creating Systemd Service"
    
    # Detect bot path
    if [[ -f "/root/Vps-Deployer-bot/bot.py" ]]; then
        BOT_DIR="/root/Vps-Deployer-bot"
    elif [[ -f "/opt/rfrs-bot/bot.py" ]]; then
        BOT_DIR="/opt/rfrs-bot"
    else
        BOT_DIR="/root/Vps-Deployer-bot"
    fi
    
    # Copy bot to /opt for standard deployment (as per original script)
    mkdir -p /opt/rfrs-bot
    cp -r /root/Vps-Deployer-bot/. /opt/rfrs-bot/
    success "Bot copied to /opt/rfrs-bot"
    
    SERVICE_FILE="/etc/systemd/system/rfrs-bot.service"
    
    cat > "$SERVICE_FILE" << 'SVCEOF'
# ═════════════════════════════════════════════════════════════
#  RFRS BOT SERVICE — Managed by RootFahim
#  Watermark: RootFahim | RFRS-BOT v1.0 PRO
# ═════════════════════════════════════════════════════════════
[Unit]
Description=RFRS LXC BOT 1.0 PRO — by RootFahim
Documentation=https://github.com/RootFahim/Vps-Deployer-bot
After=network-online.target snap.lxd.daemon.service
Wants=network-online.target

[Service]
User=root
WorkingDirectory=/opt/rfrs-bot
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
Environment=PYTHONUNBUFFERED=1
Environment=RFRS_WATERMARK=RootFahim
ExecStart=/usr/bin/python3 /opt/rfrs-bot/bot.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF
    
    success "Service file written: $SERVICE_FILE"
    
    # ═════════ STEP 7: Enable & Start ═════════
    step_header "7" "Enabling & Starting Service"
    
    (systemctl daemon-reload >/dev/null 2>&1) &
    spinner $! "Reloading systemd daemon"
    
    (systemctl enable rfrs-bot >/dev/null 2>&1) &
    spinner $! "Enabling rfrs-bot service"
    
    (systemctl restart rfrs-bot >/dev/null 2>&1) &
    spinner $! "Starting rfrs-bot service"
    
    sleep 3
    
    # ═════════ STEP 8: Verify ═════════
    step_header "8" "Service Status"
    
    if systemctl is-active --quiet rfrs-bot; then
        success "rfrs-bot is ${GREEN}${BOLD}ACTIVE${NC}${GREEN} and running!${NC}"
    else
        error "rfrs-bot failed to start. Check logs:"
        echo -e "${DIM}${PURPLE}  $ journalctl -u rfrs-bot -n 50 --no-pager${NC}"
    fi
    
    echo
    systemctl status rfrs-bot --no-pager -l | head -n 15
    
    # ═════════ COMPLETION ═════════
    echo
    separator
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║              ✅  INSTALLATION COMPLETED SUCCESSFULLY  ✅          ║
    ║                                                                  ║
    ║              🎉  RootFahim VPS Deployer Bot Ready  🎉             ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    separator
    
    echo
    echo -e "${WM} ${BOLD}${GREEN}📋 QUICK COMMANDS:${NC}"
    echo
    echo -e "  ${WM} ${CYAN}▸ View logs:${NC}      ${WHITE}journalctl -u rfrs-bot -f${NC}"
    echo -e "  ${WM} ${CYAN}▸ Restart bot:${NC}     ${WHITE}systemctl restart rfrs-bot${NC}"
    echo -e "  ${WM} ${CYAN}▸ Stop bot:${NC}        ${WHITE}systemctl stop rfrs-bot${NC}"
    echo -e "  ${WM} ${CYAN}▸ Check status:${NC}    ${WHITE}systemctl status rfrs-bot${NC}"
    echo -e "  ${WM} ${CYAN}▸ Edit .env:${NC}       ${WHITE}nano /opt/rfrs-bot/.env${NC}"
    echo -e "  ${WM} ${CYAN}▸ Reconfigure:${NC}     ${WHITE}nano /opt/rfrs-bot/.env && systemctl restart rfrs-bot${NC}"
    echo
    separator
    echo
    echo -e "${DIM}${PURPLE}  Powered by ${NC}${BOLD}${CYAN}RootFahim${NC} ${DIM}${PURPLE}| RFRS BOT v1.0 PRO${NC}"
    echo -e "${DIM}${PURPLE}  GitHub: https://github.com/RootFahim${NC}"
    echo
    separator
    echo
    
    typing_effect "      🚀 Your VPS Deployer Bot is now LIVE! 🎉" "$GREEN" 0.03
    echo
}

# ─────────────────────── TRAP / CLEANUP ───────────────────────
trap 'echo -e "\n${WM} ${RED}✗ Installation interrupted by user${NC}"; exit 130' INT

# ─────────────────────── EXECUTE ───────────────────────
main
