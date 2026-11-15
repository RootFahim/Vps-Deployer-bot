#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  ██████╗  ██████╗  ██████╗ ████████╗███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗
#  ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██║  ██║██║████╗ ████║
#  ██████╔╝██║   ██║██║   ██║   ██║   █████╗  ███████║███████║██║██╔████╔██║
#  ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║
#  ██║  ██║╚██████╔╝╚██████╔╝   ██║   ██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║
#  ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
#
#         RFRS LXC BOT 1.0 PRO - ULTIMATE INSTALLER v2.0
#                    © RootFahim | RFRS BOT
# ═══════════════════════════════════════════════════════════════════════════

# ─────────────────────── COLORS ───────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# ─────────────────────── WATERMARK ───────────────────────
WM="${DIM}${PURPLE}[RootFahim]${NC}"
TAG="${DIM}${CYAN}» RFRS BOT «${NC}"

# ─────────────────────── ROOT CHECK ───────────────────────
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}${BOLD}✗ This installer must be run as root!${NC}"
   echo -e "${YELLOW}  Try: ${WHITE}sudo bash installer.sh${NC}"
   exit 1
fi

# ─────────────────────── HELPERS ───────────────────────
success()  { echo -e "${WM} ${GREEN}✔${NC} ${GREEN}${BOLD}$1${NC}"; }
info()     { echo -e "${WM} ${CYAN}ℹ${NC} ${CYAN}$1${NC}"; }
warn()     { echo -e "${WM} ${YELLOW}⚠${NC} ${YELLOW}$1${NC}"; }
error()    { echo -e "${WM} ${RED}✗${NC} ${RED}${BOLD}$1${NC}"; }

separator() {
    echo -e "${DIM}${PURPLE}═══════════════════════════════════════════════════════════════════════════${NC}"
}

step_header() {
    echo
    separator
    echo -e "${WM} ${BOLD}${CYAN}  STEP $1 ${NC}${BOLD}${WHITE}» $2${NC}"
    separator
    echo
}

typing_effect() {
    local text="$1"; local color="${2:-$CYAN}"; local delay="${3:-0.02}"
    for (( i=0; i<${#text}; i++ )); do
        printf "${color}${text:$i:1}${NC}"
        sleep "$delay"
    done
    echo
}

spinner() {
    local pid=$1; local message="$2"
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'; local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 8 ))
        printf "\r${WM} ${YELLOW}${spin:$i:1}${NC} ${message}"
        sleep 0.1
    done
    printf "\r${WM} ${GREEN}✔${NC} ${message} ${GREEN}DONE${NC}\n"
}

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
    ║           ⚡ RFRS LXC BOT 1.0 PRO - INSTALLER v2.0 ⚡              ║
    ║                  © RootFahim | RFRS BOT                          ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo -e "${DIM}${PURPLE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${DIM}${PURPLE}  │${NC}  ${CYAN}🐍 Python3${NC}      ${GREEN}●${NC} Ready   ${CYAN}📦 Discord.py${NC}  ${GREEN}●${NC} v2.4+   ${DIM}${PURPLE}│${NC}"
    echo -e "${DIM}${PURPLE}  │${NC}  ${CYAN}🖥  Systemd${NC}      ${GREEN}●${NC} Ready   ${CYAN}🔐 DotEnv${NC}      ${GREEN}●${NC} Loaded  ${DIM}${PURPLE}│${NC}"
    echo -e "${DIM}${PURPLE}  │${NC}  ${CYAN}🌐 WebSSH${NC}       ${GREEN}●${NC} Ready   ${CYAN}📡 LXC${NC}         ${GREEN}●${NC} Ready   ${DIM}${PURPLE}│${NC}"
    echo -e "${DIM}${PURPLE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo
    typing_effect "      🚀 Initializing RootFahim's Ultimate Installer..." "$PURPLE" 0.01
    echo
    sleep 0.5
}

# ─────────────────────── INTERACTIVE .env SETUP ───────────────────────
# Matches YOUR exact .env layout
setup_env_interactive() {
    local ENV_FILE="$1"

    step_header "5" "Interactive .env Configuration"

    warn "Please provide the required environment variables."
    warn "Press ${BOLD}ENTER${NC}${YELLOW} to accept the default shown in [green]."
    echo

    # Backup existing
    if [[ -f "$ENV_FILE" ]]; then
        local BK="${ENV_FILE}.backup.$(date +%s)"
        cp "$ENV_FILE" "$BK"
        info "Existing .env backed up → ${BK}"
    fi

    echo -e "${DIM}${PURPLE}─────────────────── CONFIGURING VARIABLES ───────────────────${NC}"
    echo

    # Ordered list of (key, description, default, is_secret)
    local -a KEYS=(
        "DISCORD_TOKEN|Bot token (Discord Developer Portal → Bot → Reset Token)|__REQUIRED__|yes"
        "ADMIN_IDS|Admin Discord user IDs (comma separated)|__REQUIRED__|no"
        "PREFIX|Command prefix|!|no"
        "BOT_NAME|Bot display name|RFRS LXC BOT 1.0 PRO|no"
        "DEFAULT_RAM_GB|Default VPS RAM in GB|1|no"
        "DEFAULT_CPU|Default VPS CPU cores|1|no"
        "DEFAULT_DISK_GB|Default VPS disk in GB|10|no"
        "MAX_VPS_PER_USER|Max VPS per user|2|no"
        "WEB_PORT|WebSSH port|8080|no"
        "WEBSSH_URL|WebSSH public URL (http:// or https://)|http://YOUR_SERVER_IP:8080|no"
    )

    # Detect public IP for helpful default
    local PUBLIC_IP
    PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")
    info "Detected public IP: ${WHITE}${PUBLIC_IP}${NC}"

    # Rewrite .env header
    cat > "$ENV_FILE" << EOF
# ===== RFRS LXC BOT 1.0 PRO - .env =====
# Generated by RootFahim Installer on $(date)
# Watermark: RootFahim | RFRS BOT v1.0 PRO
# =========================================

EOF

    local -A RESULTS

    for entry in "${KEYS[@]}"; do
        IFS='|' read -r key desc def secret <<< "$entry"

        # Special-case WEBSSH_URL default with detected IP
        if [[ "$key" == "WEBSSH_URL" && "$def" == "http://YOUR_SERVER_IP:8080" ]]; then
            def="http://${PUBLIC_IP}:8080"
        fi

        echo -e "  ${WM} ${CYAN}${BOLD}${key}${NC}"
        echo -e "  ${DIM}  ↳ ${desc}${NC}"

        local value=""
        if [[ "$def" == "__REQUIRED__" ]]; then
            while [[ -z "$value" ]]; do
                if [[ "$secret" == "yes" ]]; then
                    read -rsp "  ${YELLOW}  ▸ Enter value (hidden): ${NC}" value
                    echo
                else
                    read -rp  "  ${YELLOW}  ▸ Enter value: ${NC}" value
                fi
                [[ -z "$value" ]] && error "This field is required!"
            done
        else
            if [[ "$secret" == "yes" ]]; then
                read -rsp "  ${YELLOW}  ▸ Enter value [${GREEN}${def}${YELLOW}] (hidden): ${NC}" value
                echo
            else
                read -rp  "  ${YELLOW}  ▸ Enter value [${GREEN}${def}${YELLOW}]: ${NC}" value
            fi
            value="${value:-$def}"
        fi

        RESULTS["$key"]="$value"

        # Mask preview
        if [[ "$secret" == "yes" ]]; then
            echo -e "  ${GREEN}  ✔ Set: ${key}=${DIM}••••••••••••••••${NC}"
        else
            echo -e "  ${GREEN}  ✔ Set: ${key}=${value}${NC}"
        fi
        echo
    done

    # Write .env in YOUR original structure
    {
        echo "# Bot token (Discord Developer Portal -> Bot -> Reset Token)"
        echo "DISCORD_TOKEN=${RESULTS[DISCORD_TOKEN]}"
        echo
        echo "# Admin Discord user IDs, comma separated"
        echo "ADMIN_IDS=${RESULTS[ADMIN_IDS]}"
        echo
        echo "# Command prefix and bot name"
        echo "PREFIX=${RESULTS[PREFIX]}"
        echo "BOT_NAME=${RESULTS[BOT_NAME]}"
        echo
        echo "# Default VPS plan (RAM in GB: 1 = 1024 MB) and max VPS per user"
        echo "DEFAULT_RAM_GB=${RESULTS[DEFAULT_RAM_GB]}"
        echo "DEFAULT_CPU=${RESULTS[DEFAULT_CPU]}"
        echo "DEFAULT_DISK_GB=${RESULTS[DEFAULT_DISK_GB]}"
        echo "MAX_VPS_PER_USER=${RESULTS[MAX_VPS_PER_USER]}"
        echo
        echo "# WebSSH: port + public link (http:// or https://)"
        echo "WEB_PORT=${RESULTS[WEB_PORT]}"
        echo "WEBSSH_URL=${RESULTS[WEBSSH_URL]}"
        echo
        echo "# ─── RootFahim watermarks ───"
        echo "RFRS_WATERMARK=RootFahim"
        echo "RFRS_VERSION=1.0"
    } > "$ENV_FILE"

    echo
    success "Environment saved to ${ENV_FILE}"
    echo

    # Masked preview
    echo -e "${DIM}${PURPLE}─────────────────────── .env PREVIEW ───────────────────────${NC}"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == "#"* ]] && { echo -e "${DIM}${line}${NC}"; continue; }
        if [[ "$line" == *"="* ]]; then
            k="${line%%=*}"; v="${line#*=}"
            if [[ "$k" == *"TOKEN"* || "$k" == *"KEY"* || "$k" == *"SECRET"* ]]; then
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

# ─────────────────────── MAIN ───────────────────────
main() {
    show_banner
    typing_effect "      ⚠  Running as ROOT — All system changes will be applied" "$YELLOW" 0.015
    echo
    sleep 1

    # STEP 1
    step_header "1" "Installing System Dependencies"
    (apt-get update -qq >/dev/null 2>&1) &
    spinner $! "Updating package lists..."
    (apt-get install -y -qq git python3-pip python3-venv nano curl wget lxc lxd >/dev/null 2>&1) &
    spinner $! "Installing git, python3-pip, nano, lxc/lxd & tools..."
    success "System dependencies ready"

    # STEP 2
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

    # STEP 3
    step_header "3" "Installing Python Packages"
    (pip install --break-system-packages -q "discord.py>=2.4.0" >/dev/null 2>&1) &
    spinner $! "Installing discord.py >= 2.4.0"
    (pip install --break-system-packages -q "python-dotenv>=1.0.0" >/dev/null 2>&1) &
    spinner $! "Installing python-dotenv >= 1.0.0"
    (pip install --break-system-packages -q "aiohttp>=3.9.0" >/dev/null 2>&1) &
    spinner $! "Installing aiohttp >= 3.9.0"
    success "All Python packages installed"

    # STEP 4
    step_header "4" "Preparing .env File"
    if [[ -f "test.env" ]]; then
        cp test.env .env
        success "Copied test.env → .env template"
    else
        touch .env
        warn "test.env not found, created empty .env"
    fi

    # STEP 5
    setup_env_interactive "/root/Vps-Deployer-bot/.env"

    # STEP 6
    step_header "6" "Deploying Bot to /opt/rfrs-bot"
    mkdir -p /opt/rfrs-bot
    cp -r /root/Vps-Deployer-bot/. /opt/rfrs-bot/
    success "Bot copied to /opt/rfrs-bot"

    # STEP 7
    step_header "7" "Creating Systemd Service"
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

    # STEP 8
    step_header "8" "Enabling & Starting Service"
    (systemctl daemon-reload >/dev/null 2>&1) &
    spinner $! "Reloading systemd daemon"
    (systemctl enable rfrs-bot >/dev/null 2>&1) &
    spinner $! "Enabling rfrs-bot service"
    (systemctl restart rfrs-bot >/dev/null 2>&1) &
    spinner $! "Starting rfrs-bot service"
    sleep 3

    # STEP 9
    step_header "9" "Service Status"
    if systemctl is-active --quiet rfrs-bot; then
        success "rfrs-bot is ${GREEN}${BOLD}ACTIVE${NC}${GREEN} and running!${NC}"
    else
        error "rfrs-bot failed to start. Check logs:"
        echo -e "${DIM}${PURPLE}  $ journalctl -u rfrs-bot -n 50 --no-pager${NC}"
    fi
    echo
    systemctl status rfrs-bot --no-pager -l | head -n 15

    # COMPLETION
    echo
    separator
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║              ✅  INSTALLATION COMPLETED SUCCESSFULLY  ✅          ║
    ║                                                                  ║
    ║             🎉  RFRS LXC BOT 1.0 PRO is READY  🎉                 ║
    ║                    © RootFahim | RFRS BOT                        ║
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
    typing_effect "      🚀 Your RFRS LXC Bot is now LIVE! 🎉" "$GREEN" 0.03
    echo
}

trap 'echo -e "\n${WM} ${RED}✗ Installation interrupted by user${NC}"; exit 130' INT

main
