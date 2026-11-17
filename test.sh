#!/bin/bash

# ═══════════════════════════════════════════════════════════════
#   ██████╗  ██████╗  ██████╗ ████████╗███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗
#   ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██║  ██║██║████╗ ████║
#   ██████╔╝██║   ██║██║   ██║   ██║   █████╗  ███████║███████║██║██╔████╔██║
#   ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║
#   ██║  ██║╚██████╔╝╚██████╔╝   ██║   ██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║
#   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
#
#         RFRS LXC BOT 1.0 PRO - AUTO INSTALLER v2.0
#                 ⚡ Powered by ROOTFAHIM ⚡
# ═══════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

WATERMARK="${PURPLE}【 ROOTFAHIM 】${NC}"

# ─── Root check ───
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}${BOLD}✗ Error: This installer must be run as root!${NC}"
   echo -e "${WATERMARK} ${YELLOW}Try: ${WHITE}sudo bash installer.sh${NC}"
   exit 1
fi

# ─── Helper Functions ───
typewriter() {
    local text="$1"
    local delay="${2:-0.02}"
    for (( i=0; i<${#text}; i++ )); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    printf "\n"
}

spinner() {
    local pid=$1
    local message="$2"
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 8 ))
        printf "\r${WATERMARK} ${CYAN}${spin:$i:1}${NC} ${message} "
        sleep 0.1
    done
    printf "\r${WATERMARK} ${GREEN}✓${NC} ${message} ${GREEN}DONE${NC}\n"
}

progress_bar() {
    local duration=$1
    local message="$2"
    local bar_width=40
    printf "\n${WATERMARK} ${WHITE}${message}${NC}\n"
    for (( i=0; i<=bar_width; i++ )); do
        local filled=$(printf "█%.0s" $(seq 1 $i 2>/dev/null))
        local empty=$(printf "░%.0s" $(seq 1 $((bar_width-i)) 2>/dev/null))
        local percent=$(( i * 100 / bar_width ))
        printf "\r${PURPLE}[${NC}${GREEN}${filled}${NC}${WHITE}${empty}${NC}${PURPLE}]${NC} ${YELLOW}${percent}%%${NC}"
        sleep $(awk "BEGIN{print $duration/$bar_width}")
    done
    printf "\n${WATERMARK} ${GREEN}✓ ${message} - COMPLETE${NC}\n\n"
}

print_header() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}${BOLD}$1${NC}"
    echo -e "${PURPLE}║${NC}  ${PURPLE}➤ ROOTFAHIM Automated Installer${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step()   { echo -e "${WATERMARK} ${BLUE}▶${NC} ${WHITE}$1${NC}"; }
print_success(){ echo -e "${WATERMARK} ${GREEN}✓${NC} ${WHITE}$1${NC}"; }
print_error()  { echo -e "${WATERMARK} ${RED}✗${NC} ${WHITE}$1${NC}"; }
print_info()   { echo -e "${WATERMARK} ${CYAN}ℹ${NC} ${WHITE}$1${NC}"; }
print_warn()   { echo -e "${WATERMARK} ${YELLOW}⚠${NC} ${WHITE}$1${NC}"; }

animate_ascii() {
    clear
    local lines=(
"${PURPLE}   ██████╗  ██████╗  ██████╗ ████████╗███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗${NC}"
"${PURPLE}   ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██║  ██║██║████╗ ████║${NC}"
"${PURPLE}   ██████╔╝██║   ██║██║   ██║   ██║   █████╗  ███████║███████║██║██╔████╔██║${NC}"
"${PURPLE}   ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║${NC}"
"${PURPLE}   ██║  ██║╚██████╔╝╚██████╔╝   ██║   ██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║${NC}"
"${PURPLE}   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝${NC}"
""
"${CYAN}${BOLD}              ▸ RFRS LXC BOT 1.0 PRO - AUTO INSTALLER ◂${NC}"
"${YELLOW}${BOLD}                    ⚡ Powered by ROOTFAHIM ⚡${NC}"
""
    )
    for line in "${lines[@]}"; do
        echo -e "$line"
        sleep 0.08
    done
    echo -e "${PURPLE}   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
animate_ascii

typewriter "${WATERMARK} ${CYAN}Initializing RootFahim Installer Engine v2.0...${NC}" 0.02
sleep 0.4
typewriter "${WATERMARK} ${CYAN}System check in progress...${NC}" 0.02
sleep 0.4
echo ""

# ─── STEP 1: Update System ───
print_header "STEP 1/8: SYSTEM UPDATE & PREREQUISITES"

print_step "Updating package lists..."
apt update -y &>/dev/null &
spinner $! "Updating apt package index"

print_step "Installing essential packages..."
(apt install -y git python3 python3-pip curl nano lxd-client &>/dev/null) &
spinner $! "Installing: git | python3 | python3-pip | curl | nano"

progress_bar 1 "Preparing environment"
print_success "System prerequisites installed"

# ─── STEP 2: Clone Repo ───
print_header "STEP 2/8: CLONING RFRS LXC BOT"

if [[ -d "Vps-Deployer-bot" ]]; then
    print_warn "Existing directory found, removing old clone..."
    rm -rf Vps-Deployer-bot
fi

print_step "Cloning repository from GitHub..."
(git clone https://github.com/RootFahim/Vps-Deployer-bot &>/dev/null) &
spinner $! "Cloning RootFahim/Vps-Deployer-bot"

if [[ ! -d "Vps-Deployer-bot" ]]; then
    print_error "Failed to clone repository!"
    exit 1
fi

cd Vps-Deployer-bot || { print_error "Cannot enter directory!"; exit 1; }
print_success "Repository cloned to $(pwd)"

# ─── STEP 3: Install Python Requirements ───
print_header "STEP 3/8: INSTALLING PYTHON DEPENDENCIES"

print_step "Installing pip dependencies..."
(pip3 install -r requirements.txt &>/dev/null) &
spinner $! "Installing Python packages (may take a moment)"

progress_bar 1 "Finalizing Python environment"
print_success "All Python dependencies installed"

# ─── STEP 4: Configure .env ───
print_header "STEP 4/8: CONFIGURING .env (INTERACTIVE SETUP)"

if [[ -f "test.env" ]]; then
    cp test.env .env
    print_success "Copied test.env → .env"
elif [[ -f ".env.example" ]]; then
    cp .env.example .env
    print_success "Copied .env.example → .env"
elif [[ -f ".env" ]]; then
    print_success "Existing .env found, will update in place"
else
    print_error "No template env file found (test.env / .env.example)"
    exit 1
fi

echo ""
print_info "Now we'll walk through each variable one by one."
echo -e "${WATERMARK} ${YELLOW}Press ENTER to keep the default value.${NC}"
echo ""

# ─────────────────────────────────────────────────────────────
#  Interactive Variable Setup - Tailored to RFRS .env format
# ─────────────────────────────────────────────────────────────

# Backup original
cp .env ".env.backup.$(date +%s)"

# Arrays to hold key-value pairs
declare -a ENV_LINES=()
declare -A ENV_VALUES=()
declare -A ENV_DESCRIPTIONS=(
    [DISCORD_TOKEN]="Bot token (Discord Developer Portal → Bot → Reset Token)"
    [ADMIN_IDS]="Admin Discord user IDs (comma separated)"
    [PREFIX]="Command prefix"
    [BOT_NAME]="Bot display name"
    [DEFAULT_RAM_GB]="Default VPS RAM in GB (1 = 1024 MB)"
    [DEFAULT_CPU]="Default VPS CPU cores"
    [DEFAULT_DISK_GB]="Default VPS disk size in GB"
    [MAX_VPS_PER_USER]="Max VPS instances per user"
    [WEB_PORT]="WebSSH port"
    [WEBSSH_URL]="WebSSH public URL (http:// or https://)"
)

# Read existing file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Preserve comments and empty lines
    if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
        ENV_LINES+=("$line")
        continue
    fi

    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        default="${BASH_REMATCH[2]}"

        echo ""
        echo -e "${PURPLE}───────────────────────────────────────────────${NC}"
        echo -e "${WATERMARK} ${CYAN}⚙ Configuring:${NC} ${BOLD}${YELLOW}${key}${NC}"
        echo -e "   ${WHITE}${ENV_DESCRIPTIONS[$key]:-Variable setup}${NC}"
        if [[ -n "$default" ]]; then
            echo -e "   ${YELLOW}Current/Default:${NC} ${CYAN}${default}${NC}"
        fi

        # Prompt with proper key display
        read -r -p "$(echo -e "${WATERMARK} ${WHITE}→ Enter value for ${GREEN}${key}${WHITE}= [${NC}${CYAN}ENTER${NC}${WHITE}=keep default${NC}${WHITE}]: ${NC}")" user_val

        if [[ -n "$user_val" ]]; then
            ENV_VALUES["$key"]="$user_val"
            echo -e "${WATERMARK} ${GREEN}✓${NC} ${GREEN}${key}=${user_val}${NC}"
        else
            ENV_VALUES["$key"]="$default"
            echo -e "${WATERMARK} ${YELLOW}→${NC} ${YELLOW}${key}=${default}${NC} ${WHITE}(default kept)${NC}"
        fi
    else
        # Keep any other line as-is
        ENV_LINES+=("$line")
    fi
done < .env

echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ── Rebuild .env with RootFahim header + updated values ──
> .env
cat >> .env <<'EOF'
# ═══════════════════════════════════════════════════════════════
#   RFRS LXC BOT 1.0 PRO - .env
#   ⚡ Powered by ROOTFAHIM ⚡
# ═══════════════════════════════════════════════════════════════

EOF

# Write out all values back, preserving original comment order from ENV_LINES
# Build an order map based on original file
declare -A WRITTEN
for line in "${ENV_LINES[@]}"; do
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)= ]]; then
        key="${BASH_REMATCH[1]}"
        if [[ -n "${ENV_VALUES[$key]+x}" ]]; then
            echo "${key}=${ENV_VALUES[$key]}" >> .env
            WRITTEN["$key"]=1
        fi
    elif [[ "$line" =~ ^# ]] && [[ -n "$line" ]]; then
        # Skip the original first header (we replaced it)
        if [[ "$line" != "# ===== RFRS LXC BOT 1.0 PRO - .env =====" ]]; then
            echo "$line" >> .env
        fi
    elif [[ -z "$line" ]]; then
        echo "" >> .env
    fi
done

# Add any keys that were present but somehow not written
for key in "${!ENV_VALUES[@]}"; do
    if [[ -z "${WRITTEN[$key]+x}" ]]; then
        echo "${key}=${ENV_VALUES[$key]}" >> .env
    fi
done

chmod 600 .env
print_success ".env configured successfully (permissions 600)"

# Preview final env (masked secrets)
echo ""
print_info "Final .env preview (secrets masked):"
echo -e "${PURPLE}───────────────────────────────────────────────${NC}"
while IFS= read -r line; do
    if [[ "$line" =~ ^(DISCORD_TOKEN|ADMIN_IDS)= ]]; then
        k="${BASH_REMATCH[1]}"
        v="${line#*=}"
        masked="${v:0:4}****${v: -2}"
        echo -e "${WATERMARK} ${CYAN}${k}${NC}=${GREEN}${masked}${NC}"
    elif [[ "$line" =~ ^([A-Za-z_]+)= ]]; then
        k="${BASH_REMATCH[1]}"
        v="${line#*=}"
        echo -e "${WATERMARK} ${CYAN}${k}${NC}=${YELLOW}${v}${NC}"
    fi
done < .env
echo -e "${PURPLE}───────────────────────────────────────────────${NC}"

# ─── STEP 5: Verify bot.py ───
print_header "STEP 5/8: VERIFYING BOT ENTRY POINT"

BOT_PATH="$(pwd)/bot.py"
if [[ ! -f "$BOT_PATH" ]]; then
    print_warn "bot.py not found in $(pwd), searching..."
    ALT=$(find "$(pwd)" -maxdepth 2 \( -name "bot.py" -o -name "main.py" \) | head -n 1)
    if [[ -n "$ALT" ]]; then
        BOT_PATH="$ALT"
        print_success "Found entry: $BOT_PATH"
    else
        print_error "No bot.py / main.py found! Aborting."
        exit 1
    fi
else
    print_success "Bot entry point: $BOT_PATH"
fi

WORKDIR="$(pwd)"

# ─── STEP 6: Create Systemd Service ───
print_header "STEP 6/8: CREATING SYSTEMD SERVICE"

SERVICE_FILE="/etc/systemd/system/rfrs-bot.service"
print_step "Writing systemd unit → $SERVICE_FILE"

cat > "$SERVICE_FILE" <<EOF
# ═══════════════════════════════════════════════════════
#   RFRS LXC BOT 1.0 PRO - Systemd Service
#   ⚡ Powered by ROOTFAHIM ⚡
# ═══════════════════════════════════════════════════════
[Unit]
Description=RFRS LXC BOT 1.0 PRO - by RootFahim
After=network.target snap.lxd.daemon.service

[Service]
User=root
WorkingDirectory=$WORKDIR
ExecStart=/usr/bin/python3 $BOT_PATH
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$SERVICE_FILE"
print_success "Service file created: $SERVICE_FILE"

# ─── STEP 7: Reload & Enable ───
print_header "STEP 7/8: RELOADING SYSTEMD & ENABLING SERVICE"

(systemctl daemon-reload &>/dev/null) &
spinner $! "Reloading systemd daemon"

(systemctl enable rfrs-bot &>/dev/null) &
spinner $! "Enabling rfrs-bot service on boot"

# ─── STEP 8: Start Service ───
print_header "STEP 8/8: STARTING RFRS BOT SERVICE"

(systemctl start rfrs-bot &>/dev/null) &
spinner $! "Starting rfrs-bot service"
sleep 3

# ─── Health check ───
echo ""
print_info "Checking service health..."
if systemctl is-active --quiet rfrs-bot; then
    print_success "Service is RUNNING ✓"
else
    print_error "Service is NOT running! Check logs:"
    echo -e "${WATERMARK} ${YELLOW}journalctl -u rfrs-bot -n 50 --no-pager${NC}"
fi

# ═══════════════════════════════════════════════════════════════
#                     FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════

clear
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}                ${GREEN}${BOLD}✓ INSTALLATION COMPLETE ✓${NC}                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                              ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}   ${CYAN}${BOLD}🤖 RFRS LXC BOT 1.0 PRO${NC}                                    ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}   ${YELLOW}⚡ Powered by ROOTFAHIM ⚡${NC}                                  ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                              ${PURPLE}║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WATERMARK} ${WHITE}Service Status:${NC}"
systemctl status rfrs-bot --no-pager -l 2>/dev/null | head -n 10
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WATERMARK} ${CYAN}Useful Commands:${NC}"
echo -e "   ${GREEN}▶${NC} ${WHITE}systemctl status rfrs-bot${NC}     ${YELLOW}→ Check status${NC}"
echo -e "   ${GREEN}▶${NC} ${WHITE}systemctl restart rfrs-bot${NC}    ${YELLOW}→ Restart bot${NC}"
echo -e "   ${GREEN}▶${NC} ${WHITE}systemctl stop rfrs-bot${NC}       ${YELLOW}→ Stop bot${NC}"
echo -e "   ${GREEN}▶${NC} ${WHITE}journalctl -u rfrs-bot -f${NC}     ${YELLOW}→ Live logs${NC}"
echo -e "   ${GREEN}▶${NC} ${WHITE}nano $WORKDIR/.env${NC}          ${YELLOW}→ Edit env vars${NC}"
echo -e "   ${GREEN}▶${NC} ${WHITE}cat /etc/systemd/system/rfrs-bot.service${NC} ${YELLOW}→ View unit file${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${PURPLE}${BOLD}        ⚡ Thank you for using RootFahim Installer! ⚡${NC}"
echo -e "${CYAN}                Made with ♥ by ROOTFAHIM${NC}"
echo ""
