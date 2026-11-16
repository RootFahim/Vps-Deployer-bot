#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#   ██████╗  ██████╗  ██████╗ ████████╗███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗
#   ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██║  ██║██║████╗ ████║
#   ██████╔╝██║   ██║██║   ██║   ██║   █████╗  ███████║███████║██║██╔████╔██║
#   ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║
#   ██║  ██║╚██████╔╝╚██████╔╝   ██║   ██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║
#   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
# ═══════════════════════════════════════════════════════════════════
#   RFRS BOT INSTALLER  |  Powered by ROOTFAHIM
#   GitHub : https://github.com/RootFahim/Vps-Deployer-bot
# ═══════════════════════════════════════════════════════════════════

# ───────────── Colors ─────────────
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ───────────── Root Check ─────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root!${NC}"
    echo -e "${YELLOW}Try: sudo bash installer.sh${NC}"
    exit 1
fi

# ───────────── Helper Functions ─────────────
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC}  ${WHITE}%s${NC}" "$spinstr" "$2"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "\r\033[K"
}

type_text() {
    local text="$1"
    local color="${2:-$WHITE}"
    for ((i=0; i<${#text}; i++)); do
        printf "${color}%s${NC}" "${text:$i:1}"
        sleep 0.015
    done
    echo ""
}

section() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${CYAN}  $1${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
}

success() { echo -e "${GREEN}  ✅ $1${NC}"; }
info()    { echo -e "${CYAN}  ℹ️  $1${NC}"; }
warn()    { echo -e "${YELLOW}  ⚠️  $1${NC}"; }
error()   { echo -e "${RED}  ❌ $1${NC}"; }

run_with_spinner() {
    local msg="$1"; shift
    ( "$@" > /tmp/rfrs_install.log 2>&1 ) &
    local pid=$!
    
    spinner $pid "$msg"
    wait $pid
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        success "$msg — DONE"
    else
        error "$msg — FAILED"
        echo -e "${RED}Last 20 lines of log:${NC}"
        tail -n 20 /tmp/rfrs_install.log
        exit $exit_code
    fi
}

# ═══════════════════════════════════════════════════════════════════
#                      BANNER + INTRO ANIMATION
# ═══════════════════════════════════════════════════════════════════
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
echo -e "${MAGENTA}  ═══════════════════════════════════════════════════════════════${NC}"
echo ""
type_text "  🚀 Initializing installation sequence..." "$CYAN"
sleep 0.3
type_text "  🔧 Preparing environment..." "$CYAN"
sleep 0.3
type_text "  💎 Loading modules..." "$CYAN"
sleep 0.2
echo ""

# ═══════════════════════════════════════════════════════════════════
#                        STEP 1 : APT UPDATE
# ═══════════════════════════════════════════════════════════════════
section "STEP 1/6  •  System Update & Dependencies"
info "Updating apt packages (this may take a moment)..."
run_with_spinner "Updating apt package list" apt-get update -y
run_with_spinner "Installing git"               apt-get install -y git
run_with_spinner "Installing python3-pip"       apt-get install -y python3-pip
run_with_spinner "Installing python3-venv"      apt-get install -y python3-venv

# ═══════════════════════════════════════════════════════════════════
#                   STEP 2 : CLONE REPO
# ═══════════════════════════════════════════════════════════════════
section "STEP 2/6  •  Cloning Repository"
cd /root

if [[ -d "/root/Vps-Deployer-bot" ]]; then
    warn "Repo already exists — removing old copy..."
    rm -rf /root/Vps-Deployer-bot
fi

run_with_spinner "Cloning Vps-Deployer-bot" git clone https://github.com/RootFahim/Vps-Deployer-bot
cd /root/Vps-Deployer-bot
success "Repository cloned to /root/Vps-Deployer-bot"

# ═══════════════════════════════════════════════════════════════════
#                   STEP 3 : PYTHON DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════
section "STEP 3/6  •  Installing Python Dependencies"
if [[ -f "requirements.txt" ]]; then
    info "Detecting PIP configuration..."
    # Smart check for the new PEP 668 flag
    if pip install --help 2>/dev/null | grep -q "break-system-packages"; then
        PIP_CMD="pip install -r requirements.txt --break-system-packages"
    else
        PIP_CMD="pip install -r requirements.txt"
    fi
    
    # Try primary pip command first
    if run_with_spinner "Installing Python requirements" $PIP_CMD; then
        pass
    else
        warn "Primary pip failed, trying with 'python3 -m pip'..."
        PIP_CMD_ALT="python3 -m ${PIP_CMD}"
        run_with_spinner "Installing via python3 -m pip" $PIP_CMD_ALT
    fi
else
    warn "requirements.txt not found — skipping"
fi

# ═══════════════════════════════════════════════════════════════════
#                   STEP 4 : .ENV SETUP (INTERACTIVE)
# ═══════════════════════════════════════════════════════════════════
section "STEP 4/6  •  Environment Configuration"

ENV_FILE=".env"

if [[ -f "test.env" && ! -f "$ENV_FILE" ]]; then
    cp test.env "$ENV_FILE"
    success "Seeded .env from test.env"
fi

if [[ ! -f "$ENV_FILE" ]]; then
    cat > "$ENV_FILE" << 'EOF'
# ===== RFRS LXC BOT 1.0 PRO - .env =====

# Bot token (Discord Developer Portal -> Bot -> Reset Token)
DISCORD_TOKEN=your_bot_token_here

# Admin Discord user IDs, comma separated
ADMIN_IDS=123456789012345678

# Command prefix and bot name
PREFIX=!
BOT_NAME=RFRS LXC BOT 1.0 PRO

# Default VPS plan (RAM in GB: 1 = 1024 MB) and max VPS per user
DEFAULT_RAM_GB=1
DEFAULT_CPU=1
DEFAULT_DISK_GB=10
MAX_VPS_PER_USER=2

# WebSSH: port + public link (http:// or https://)
WEB_PORT=8080
WEBSSH_URL=http://YOUR_SERVER_IP:8080
EOF
    success "Created fresh .env with default template"
fi

set_env_var() {
    local key="$1"
    local value="$2"
    local esc_val
    esc_val=$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${esc_val}|" "$ENV_FILE"
    else
        echo "${key}=${value}" >> "$ENV_FILE"
    fi
}

get_env_var() {
    grep "^${1}=" "$ENV_FILE" 2>/dev/null | head -n1 | cut -d'=' -f2-
}

prompt_var() {
    local var="$1"
    local desc="$2"
    local secret="$3"
    local required="$4"
    local validate="$5"

    local current
    current=$(get_env_var "$var")
    local input=""

    echo ""
    echo -e "${CYAN}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}  ➤  ${var}${NC}  ${YELLOW}— ${desc}${NC}"
    [[ "$required" == "required" ]] && echo -e "${RED}     * REQUIRED${NC}"

    if [[ -n "$current" ]]; then
        if [[ "$secret" == "secret" ]]; then
            local masked
            masked=$(printf '%*s' ${#current} '' | tr ' ' '*')
            echo -e "${BLUE}     current : ${masked}${NC}"
        else
            echo -e "${BLUE}     current : ${current}${NC}"
        fi
    fi

    local prompt_msg
    if [[ -n "$current" ]]; then
        prompt_msg="${GREEN}     ${var}=${NC} ${BLUE}[Enter to keep]${NC} "
    else
        prompt_msg="${GREEN}     ${var}=${NC} "
    fi

    if [[ "$secret" == "secret" ]]; then
        read -rsp "$(echo -e "$prompt_msg")" input
        echo ""
    else
        read -rp "$(echo -e "$prompt_msg")" input
    fi

    if [[ -z "$input" ]]; then
        if [[ -z "$current" && "$required" == "required" ]]; then
            error "${var} is required — cannot be empty!"
            prompt_var "$var" "$desc" "$secret" "$required" "$validate"
            return
        fi
        if [[ -z "$current" ]]; then
            warn "${var} left as placeholder"
        else
            info "${var} kept existing value"
        fi
        return
    fi

    if [[ -n "$validate" ]] && ! eval "$validate \"\$input\""; then
        error "Invalid value for ${var} — try again"
        prompt_var "$var" "$desc" "$secret" "$required" "$validate"
        return
    fi

    set_env_var "$var" "$input"
    success "${var} saved"
}

is_number() { [[ "$1" =~ ^[0-9]+$ ]]; }
is_url()    { [[ "$1" =~ ^https?://.+ ]]; }
is_digits() { [[ "$1" =~ ^[0-9,]+$ ]]; }

echo ""
echo -e "${MAGENTA}  ╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}  ║${CYAN}   🤖  DISCORD BOT CONFIGURATION${NC}"
echo -e "${MAGENTA}  ╚══════════════════════════════════════════════════════════════╝${NC}"

prompt_var "DISCORD_TOKEN"  "Discord bot token (from Dev Portal)"           secret   required ""
prompt_var "ADMIN_IDS"      "Admin Discord user IDs (comma-separated)"      normal   required "is_digits"

echo ""
echo -e "${MAGENTA}  ╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}  ║${CYAN}   🎛️   BOT BEHAVIOUR${NC}"
echo -e "${MAGENTA}  ╚══════════════════════════════════════════════════════════════╝${NC}"

prompt_var "PREFIX"    "Command prefix (e.g. ! or .)"                     normal   ""       ""
prompt_var "BOT_NAME"  "Display name shown in embeds"                       normal   ""       ""

echo ""
echo -e "${MAGENTA}  ╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}  ║${CYAN}   🖥️   VPS PLAN DEFAULTS${NC}"
echo -e "${MAGENTA}  ╚══════════════════════════════════════════════════════════════╝${NC}"

prompt_var "DEFAULT_RAM_GB"    "Default RAM per VPS (GB)"                  normal   ""       "is_number"
prompt_var "DEFAULT_CPU"       "Default CPU cores per VPS"                 normal   ""       "is_number"
prompt_var "DEFAULT_DISK_GB"   "Default disk size per VPS (GB)"            normal   ""       "is_number"
prompt_var "MAX_VPS_PER_USER"  "Max VPS instances per user"                normal   ""       "is_number"

echo ""
echo -e "${MAGENTA}  ╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}  ║${CYAN}   🌐   WEBSSH / WEB PANEL${NC}"
echo -e "${MAGENTA}  ╚══════════════════════════════════════════════════════════════╝${NC}"

prompt_var "WEB_PORT"    "WebSSH port (e.g. 8080)"                         normal   ""       "is_number"
prompt_var "WEBSSH_URL"  "Public WebSSH URL (http://IP:PORT)"              normal   ""       "is_url"

echo ""
success "All .env variables configured"
echo -e "${BLUE}  ─────────────────────────────────────────────────────────────${NC}"
echo -e "${WHITE}  📄  Current .env (secrets hidden):${NC}"
while IFS='=' read -r k v; do
    [[ -z "$k" || "$k" =~ ^# ]] && continue
    k=$(echo "$k" | xargs)
    if [[ "$k" =~ (TOKEN|KEY|SECRET|PASSWORD) ]]; then
        echo -e "     ${GREEN}${k}${NC}=${YELLOW}$(printf '%*s' ${#v} '' | tr ' ' '*')${NC}"
    else
        echo -e "     ${GREEN}${k}${NC}=${YELLOW}${v}${NC}"
    fi
done < "$ENV_FILE"
echo -e "${BLUE}  ─────────────────────────────────────────────────────────────${NC}"

# ═══════════════════════════════════════════════════════════════════
#                   STEP 5 : SYSTEMD SERVICE
# ═══════════════════════════════════════════════════════════════════
section "STEP 5/6  •  Creating systemd Service"

BOT_FILE=""
for candidate in /root/Vps-Deployer-bot/bot.py /root/Vps-Deployer-bot/main.py /root/bot.py; do
    if [[ -f "$candidate" ]]; then BOT_FILE="$candidate"; break; fi
done
if [[ -z "$BOT_FILE" ]]; then
    warn "Could not auto-detect bot entry file — assuming /root/Vps-Deployer-bot/bot.py"
    BOT_FILE="/root/Vps-Deployer-bot/bot.py"
fi

cat > /etc/systemd/system/rfrs-bot.service << EOF
# ────────────────────────────────────────────────
#  RFRS LXC BOT 1.0 PRO  •  Made by ROOTFAHIM
#  Watermark: ROOTFAHIM
# ────────────────────────────────────────────────
[Unit]
Description=RFRS LXC BOT 1.0 PRO  [ROOTFAHIM]
After=network.target snap.lxd.daemon.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/Vps-Deployer-bot
ExecStart=/usr/bin/python3 ${BOT_FILE}
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1
EnvironmentFile=/root/Vps-Deployer-bot/.env
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

success "Service file created: /etc/systemd/system/rfrs-bot.service"
info "WorkingDirectory : /root/Vps-Deployer-bot"
info "ExecStart        : /usr/bin/python3 ${BOT_FILE}"

run_with_spinner "Reloading systemd daemon" systemctl daemon-reload
run_with_spinner "Enabling rfrs-bot service" systemctl enable rfrs-bot
run_with_spinner "Starting rfrs-bot service" systemctl start rfrs-bot

# ═══════════════════════════════════════════════════════════════════
#                   STEP 6 : VERIFY & COMPLETE
# ═══════════════════════════════════════════════════════════════════
section "STEP 6/6  •  Service Status"

sleep 2
systemctl --no-pager --full status rfrs-bot || true

echo ""
echo -e "${GREEN}${NC}"
cat << 'EOF'
   ██████╗  ██████╗  ██████╗ ████████╗███████╗ █████╗ ██╗  ██╗██╗███╗   ███╗
   ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██║  ██║██║████╗ ████║
   ██████╔╝██║   ██║██║   ██║   ██║   █████╗  ███████║███████║██║██╔████╔██║
   ██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██║██╔══██║██║██║╚██╔╝██║
   ██║  ██║╚██████╔╝╚██████╔╝   ██║   ██║     ██║  ██║██║  ██║██║██║ ╚═╝ ██║
   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
EOF
echo -e "${NC}"
echo -e "${GREEN}  ╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}  ║  🎉  INSTALLATION COMPLETE — RFRS LXC BOT IS LIVE!  🎉        ║${NC}"
echo -e "${GREEN}  ╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}  📌  Useful commands:${NC}"
echo -e "${WHITE}     • Status  : ${YELLOW}systemctl status rfrs-bot${NC}"
echo -e "${WHITE}     • Logs    : ${YELLOW}journalctl -u rfrs-bot -f${NC}"
echo -e "${WHITE}     • Restart : ${YELLOW}systemctl restart rfrs-bot${NC}"
echo -e "${WHITE}     • Stop    : ${YELLOW}systemctl stop rfrs-bot${NC}"
echo -e "${WHITE}     • Edit env: ${YELLOW}nano /root/Vps-Deployer-bot/.env${NC}"
echo ""
echo -e "${MAGENTA}  ═══════════════════════════════════════════════════════════════${NC}"
echo ""
