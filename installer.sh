#!/bin/bash

# ============================================================
#   ██████╗  ██████╗  ███████╗██████╗ ███████╗
#   ██╔══██╗██╔═══██╗██╔════╝██╔══██╗██╔════╝
#   ██████╔╝██║   ██║█████╗  ██████╔╝███████╗
#   ██╔══██╗██║   ██║██╔══╝  ██╔══██╗╚════██║
#   ██║  ██║╚██████╔╝██║     ██║  ██║███████║
#   ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝
#
#   RFRS LXC BOT 1.0 PRO — AUTO INSTALLER
#   Watermark: ROOTFAHIM
#   Repo: github.com/RootFahim/Vps-Deployer-bot
# ============================================================

set -e

# ---------- COLORS ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ---------- WATERMARK ----------
WM="${MAGENTA}${BOLD}[ ROOTFAHIM ]${NC}"

# ---------- HELPERS ----------
log()     { echo -e "${WM} ${CYAN}➜${NC} $1"; }
ok()      { echo -e "${WM} ${GREEN}✔${NC} $1"; }
warn()    { echo -e "${WM} ${YELLOW}⚠${NC} $1"; }
err()     { echo -e "${WM} ${RED}✘${NC} $1"; }
step()    { echo -e "\n${WM} ${BLUE}${BOLD}▶ $1${NC}\n"; }

# ---------- SPINNER ----------
spinner() {
    local pid=$1 msg="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r${WM} ${CYAN}${spin:$i:1}${NC} %s" "$msg"
        sleep 0.08
    done
    printf "\r${WM} ${GREEN}✔${NC} %s\n" "$msg"
}

# ---------- TYPEWRITER ----------
typewriter() {
    local text="$1" delay="${2:-0.015}"
    for (( i=0; i<${#text}; i++ )); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

# ---------- PROGRESS BAR ----------
progress_bar() {
    local total=50 text="$1"
    printf "\n${WM} ${BOLD}%s${NC}\n" "$text"
    for (( i=0; i<=total; i++ )); do
        local pct=$(( i * 100 / total ))
        local filled=$(( i * 40 / total ))
        local empty=$(( 40 - filled ))
        local bar=""
        for (( j=0; j<filled; j++ )); do bar+="█"; done
        for (( j=0; j<empty; j++ ));  do bar+="░"; done
        printf "\r  ${GREEN}${bar}${NC} ${YELLOW}%3d%%${NC}" "$pct"
        sleep 0.02
    done
    echo -e "  ${GREEN}DONE${NC}"
}

# ---------- BANNER ----------
show_banner() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    cat << "EOF"
   ██████╗  ██████╗  ███████╗██████╗ ███████╗
   ██╔══██╗██╔═══██╗██╔════╝██╔══██╗██╔════╝
   ██████╔╝██║   ██║█████╗  ██████╔╝███████╗
   ██╔══██╗██║   ██║██╔══╝  ██╔══██╗╚════██║
   ██║  ██║╚██████╔╝██║     ██║  ██║███████║
   ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}${BOLD}   ╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}   ║${WHITE}    RFRS LXC BOT 1.0 PRO — AUTO INSTALLER   ${CYAN}║${NC}"
    echo -e "${CYAN}${BOLD}   ║${MAGENTA}          Watermark: ROOTFAHIM               ${CYAN}║${NC}"
    echo -e "${CYAN}${BOLD}   ╚══════════════════════════════════════════════╝${NC}"
    echo
}

# ---------- ROOT CHECK ----------
check_root() {
    if [[ $EUID -ne 0 ]]; then
        err "Must run as root!"
        echo -e "${WM} ${YELLOW}Try: sudo bash $0${NC}"
        exit 1
    fi
}

# ---------- .env WRITER ----------
set_env() {
    local key="$1" value="$2"
    # remove existing line, then append
    sed -i "/^${key}=/d" .env 2>/dev/null || true
    echo "${key}=${value}" >> .env
}

# ---------- PROMPT .env VALUE ----------
prompt_env() {
    local key="$1" desc="$2" default="$3" secret="$4"
    local value=""

    echo
    echo -e "${WM} ${BLUE}${BOLD}${key}${NC}"
    echo -e "   ${DIM}${desc}${NC}"
    [[ -n "$default" ]] && echo -e "   ${DIM}Default: ${default}${NC}"

    if [[ "$secret" == "yes" ]]; then
        read -rsp "   ${CYAN}➜ ${key}=${NC}" value
        echo
    else
        if [[ -n "$default" ]]; then
            read -rp "   ${CYAN}➜ ${key} [${default}]:${NC} " value
        else
            read -rp "   ${CYAN}➜ ${key}=${NC}" value
        fi
    fi

    [[ -z "$value" ]] && value="$default"

    if [[ -z "$value" ]]; then
        warn "Empty value for ${key} — skipped."
        return
    fi

    set_env "$key" "$value"
    ok "${key} saved"
}

# ============================================================
#   MAIN
# ============================================================
show_banner
check_root

typewriter "  Starting installation of RFRS LXC BOT 1.0 PRO ..." 0.01
echo

# ---------- STEP 1: SYSTEM UPDATE ----------
step "STEP 1/8 : Updating system packages"
(apt-get update -y >/dev/null 2>&1) &
spinner $! "Updating apt repositories"

# ---------- STEP 2: INSTALL DEPS ----------
step "STEP 2/8 : Installing Git & Python3-Pip"
(apt-get install -y git python3-pip python3-venv >/dev/null 2>&1) &
spinner $! "Installing git, python3-pip, venv"

# ---------- STEP 3: CLONE REPO ----------
step "STEP 3/8 : Cloning repository"
cd /root
if [[ -d "Vps-Deployer-bot/.git" ]]; then
    warn "Repo already exists — pulling latest..."
    (cd Vps-Deployer-bot && git pull >/dev/null 2>&1) &
    spinner $! "git pull origin main"
else
    rm -rf Vps-Deployer-bot
    (git clone https://github.com/RootFahim/Vps-Deployer-bot >/dev/null 2>&1) &
    spinner $! "Cloning RootFahim/Vps-Deployer-bot"
fi
cd Vps-Deployer-bot
ok "Repository ready: $(pwd)"

# ---------- STEP 4: REQUIREMENTS ----------
step "STEP 4/8 : Installing Python requirements"
(pip3 install --break-system-packages -r requirements.txt >/dev/null 2>&1) &
spinner $! "pip install -r requirements.txt"
ok "Python dependencies installed"

# ---------- STEP 5: .ENV SETUP ----------
step "STEP 5/8 : Configuring .env file"

if [[ ! -f test.env ]]; then
    err "test.env template not found inside repo!"
    exit 1
fi

cp test.env .env
ok ".env file created from test.env template"

echo
echo -e "${WM} ${YELLOW}${BOLD}Fill in your configuration below.${NC}"
echo -e "${WM} ${DIM}Press ENTER to accept the default value shown in [brackets].${NC}"

# ===== REQUIRED =====
prompt_env "DISCORD_TOKEN" \
    "Bot token (Discord Dev Portal → Bot → Reset Token)" \
    "" "yes"

prompt_env "ADMIN_IDS" \
    "Admin Discord user IDs (comma-separated, e.g. 123,456)" \
    "" "no"

# ===== BASIC =====
prompt_env "PREFIX" \
    "Command prefix" \
    "!" "no"

prompt_env "BOT_NAME" \
    "Display name of the bot" \
    "RFRS LXC BOT 1.0 PRO" "no"

# ===== VPS DEFAULTS =====
prompt_env "DEFAULT_RAM_GB" \
    "Default VPS RAM in GB (1 = 1024 MB)" \
    "1" "no"

prompt_env "DEFAULT_CPU" \
    "Default VPS CPU cores" \
    "1" "no"

prompt_env "DEFAULT_DISK_GB" \
    "Default VPS disk in GB" \
    "10" "no"

prompt_env "MAX_VPS_PER_USER" \
    "Max VPS instances per user" \
    "2" "no"

# ===== WEBSSH =====
prompt_env "WEB_PORT" \
    "WebSSH listening port" \
    "8080" "no"

prompt_env "WEBSSH_URL" \
    "WebSSH public URL (http:// or https://)" \
    "http://$(hostname -I | awk '{print $1}'):8080" "no"

echo
ok ".env file fully configured → $(pwd)/.env"

# ---------- STEP 6: SYSTEMD SERVICE ----------
step "STEP 6/8 : Creating systemd service unit"

BOT_PATH="$(pwd)/bot.py"
if [[ ! -f "$BOT_PATH" ]]; then
    err "bot.py not found at ${BOT_PATH}"
    exit 1
fi

cat > /etc/systemd/system/rfrs-bot.service << EOF
# ─────────────────────────────────────────────
#  RFRS LXC BOT 1.0 PRO — systemd unit
#  Watermark: ROOTFAHIM
# ─────────────────────────────────────────────
[Unit]
Description=RFRS LXC BOT 1.0 PRO
After=network.target snap.lxd.daemon.service

[Service]
User=root
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/python3 $(pwd)/bot.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

ok "Service file written: /etc/systemd/system/rfrs-bot.service"

# ---------- STEP 7: ENABLE & START ----------
step "STEP 7/8 : Enabling & starting service"

(systemctl daemon-reload) &
spinner $! "systemctl daemon-reload"

(systemctl enable rfrs-bot >/dev/null 2>&1) &
spinner $! "systemctl enable rfrs-bot"

(systemctl restart rfrs-bot >/dev/null 2>&1) &
spinner $! "systemctl start rfrs-bot"

sleep 2

# ---------- STEP 8: VERIFY ----------
step "STEP 8/8 : Verifying service"

if systemctl is-active --quiet rfrs-bot; then
    ok "rfrs-bot is RUNNING"
else
    err "rfrs-bot failed to start — showing logs:"
    journalctl -u rfrs-bot --no-pager -n 25 || true
    exit 1
fi

# ---------- FINAL ----------
progress_bar "Finalizing installation..."

echo
echo -e "${GREEN}${BOLD}"
cat << "EOF"
  ╔═══════════════════════════════════════════════════════╗
  ║                                                       ║
  ║     ✔ INSTALLATION COMPLETE — RFRS BOT IS LIVE! ✔     ║
  ║                                                       ║
  ╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${WM} ${BOLD}Service status:${NC}"
echo -e "${DIM}───────────────────────────────────────────────${NC}"
systemctl status rfrs-bot --no-pager -l | head -n 15 || true
echo -e "${DIM}───────────────────────────────────────────────${NC}"

echo
echo -e "${WM} ${BOLD}Useful commands:${NC}"
echo -e "  ${CYAN}systemctl status rfrs-bot${NC}    ${DIM}# status${NC}"
echo -e "  ${CYAN}systemctl restart rfrs-bot${NC}   ${DIM}# restart${NC}"
echo -e "  ${CYAN}systemctl stop rfrs-bot${NC}      ${DIM}# stop${NC}"
echo -e "  ${CYAN}journalctl -u rfrs-bot -f${NC}    ${DIM}# live logs${NC}"
echo -e "  ${CYAN}nano $(pwd)/.env${NC}             ${DIM}# edit config${NC}"

echo
echo -e "${MAGENTA}${BOLD}          ⚡ Powered by ROOTFAHIM ⚡${NC}"
echo -e "${MAGENTA}${BOLD}   github.com/RootFahim/Vps-Deployer-bot${NC}"
echo

exit 0
