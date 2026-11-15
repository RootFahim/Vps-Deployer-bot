"""
=====================================================================
   RFRS LXC BOT 1.0 PRO
   Discord LXC VPS deployer  (bot + WebSSH backend in one file)
=====================================================================
"""
import os, re, json, time, shlex, secrets, asyncio, pty, fcntl, termios, struct, signal
from datetime import datetime, timezone
import discord
from discord.ext import commands
from aiohttp import web
from dotenv import load_dotenv

load_dotenv()
E = os.getenv
BOT_NAME = E("BOT_NAME", "RFRS 1.0 PRO")
HELP_NAME = "RFRS LXC BOT"  # name shown in the !help menu
START = time.time()
PREFIX = E("PREFIX", "!")
ADMINS = {int(x) for x in E("ADMIN_IDS", "").split(",") if x.strip()}
COLOR = int(E("EMBED_COLOR", "7C3AED"), 16)
MAX_VPS = int(E("MAX_VPS_PER_USER", "2"))
DEF_RAM, DEF_CPU, DEF_DISK = (int(E(k, d)) for k, d in
    [("DEFAULT_RAM_GB", "1"), ("DEFAULT_CPU", "1"), ("DEFAULT_DISK_GB", "10")])
WEB_HOST, WEB_PORT = E("WEB_HOST", "0.0.0.0"), int(E("WEB_PORT", "8080"))
WEBSSH_URL = E("WEBSSH_URL", f"http://127.0.0.1:{WEB_PORT}").rstrip("/")
DB_FILE = E("DB_FILE", "db.json")
LIVE_ON = E("LIVE_REFRESH", "true").strip().lower() in ("1", "true", "yes", "on")  # panel auto-refresh on/off
LIVE_SEC = max(5, int(E("LIVE_REFRESH_SEC", "10")))  # panel auto-refresh interval
OSES = [tuple(x.strip().split("|")) for x in E("OS_LIST",
    "Ubuntu 24.04|ubuntu:24.04;images:ubuntu/24.04|apt,Ubuntu 22.04|ubuntu:22.04;images:ubuntu/22.04|apt,Ubuntu 20.04|ubuntu:20.04;images:ubuntu/20.04|apt,Debian 13|debian/13;debian/trixie|apt,Debian 12|debian/12;debian/bookworm|apt,Debian 11|debian/11;debian/bullseye|apt,Alpine 3.20|alpine/3.20|apk,AlmaLinux 9|almalinux/9|dnf").split(",")]
SETUP = {
    "apt": "export DEBIAN_FRONTEND=noninteractive; apt-get update -y && apt-get install -y openssh-server curl nano sudo",
    "apk": "apk add --no-cache openssh bash curl nano && rc-update add sshd",
    "dnf": "dnf install -y openssh-server curl nano sudo && systemctl enable sshd"}

# ---------------------------------------------------------------- storage
db = {"vps": {}}
if os.path.exists(DB_FILE):
    db.update(json.load(open(DB_FILE)))
save = lambda: json.dump(db, open(DB_FILE, "w"), indent=2)
is_admin = lambda uid: uid in ADMINS
bar = lambda p, n=10: "▰" * round(min(max(p, 0), 100) / 100 * n) + "▱" * (n - round(min(max(p, 0), 100) / 100 * n))

# ---------------------------------------------------------------- shell / lxc
async def run(cmd, timeout=900):
    argv = ["bash", "-c", cmd]
    p = await asyncio.create_subprocess_exec(*argv, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT)
    try:
        out, _ = await asyncio.wait_for(p.communicate(), timeout)
    except asyncio.TimeoutError:
        p.kill(); return 124, "timeout"
    return p.returncode, out.decode(errors="ignore").strip()

lxc = lambda *a: run("lxc " + shlex.join(a))

def fmt_dur(sec):
    d, r = divmod(int(sec), 86400); h, r = divmod(r, 3600); m, sc = divmod(r, 60)
    return " ".join(p for p in [f"{d}d" if d else "", f"{h}h" if d or h else "", f"{m}m" if d or h or m else "", f"{sc}s"] if p)

def hb(n):
    for u in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024 or u == "TB": return f"{n:.0f} {u}" if u == "B" else f"{n:.1f} {u}"
        n /= 1024

def fmt_uptime(ts):
    """Real container uptime = now - the time LXD last started the instance."""
    try:
        t = datetime.fromisoformat(re.sub(r"\.\d+", "", ts).replace("Z", "+00:00"))
        sec = int((datetime.now(timezone.utc) - t).total_seconds())
        if t.year < 2000 or sec < 0: return "-"
    except Exception:
        return "-"
    return fmt_dur(sec)

CPU_PREV = {}  # name -> (time, cpu seconds) for CPU % calculation

async def vps_info(v, retry=True):
    rc, o = await lxc("list", v["name"], "--format", "json")
    try:
        c = next(x for x in json.loads(o) if x["name"] == v["name"])
    except Exception:
        return {"uptime": "-", "status": "Unknown", "ip": "-", "mem": 0, "cpu": 0, "cpu_pct": 0.0, "disk": None, "procs": 0, "mem_peak": 0, "swap": 0, "rx": 0, "tx": 0}
    s = c.get("state") or {}
    on = c["status"] == "Running"
    cpu = (s.get("cpu") or {}).get("usage", 0) / 1e9
    now, prev, pct = time.time(), CPU_PREV.get(v["name"]), 0.0
    if on and prev and now - prev[0] >= 0.5 and cpu >= prev[1]:
        pct = min(100.0, (cpu - prev[1]) / (now - prev[0]) / max(v["cpu"], 1) * 100)
    elif on and retry:  # first sample: wait 1s and measure again
        CPU_PREV[v["name"]] = (now, cpu); await asyncio.sleep(1); return await vps_info(v, False)
    if on: CPU_PREV[v["name"]] = (now, cpu)
    else: CPU_PREV.pop(v["name"], None)
    ips = [a["address"] for a in (s.get("network") or {}).get("eth0", {}).get("addresses", []) if a["family"] == "inet"]
    d = (s.get("disk") or {}).get("root")
    net = ((s.get("network") or {}).get("eth0") or {}).get("counters") or {}
    return {"uptime": fmt_uptime(c.get("last_used_at")) if on else "-", "status": c["status"], "ip": ips[0] if ips else "-",
            "mem": (s.get("memory") or {}).get("usage", 0) / 2**20, "cpu": cpu, "cpu_pct": pct, "procs": s.get("processes", 0),
            "disk": d["usage"] / 2**30 if d else None,
            "mem_peak": (s.get("memory") or {}).get("usage_peak", 0) / 2**20, "swap": (s.get("memory") or {}).get("swap_usage", 0) / 2**20,
            "rx": net.get("bytes_received", 0), "tx": net.get("bytes_sent", 0)}

# ---------------------------------------------------------------- deploy
async def build(os_t, full, ram, cpu, disk):
    """Create the container + install SSH. Returns (password, warning) or (None, error)."""
    label, image, fam = os_t
    pw = secrets.token_urlsafe(10)
    err = ""
    for img in image.split(";"):  # image fallback list: try each until one works
        img = img if ":" in img else f"images:{img}"
        rc, o = await lxc("launch", img, full, "-c", f"limits.memory={ram}GB", "-c", f"limits.cpu={cpu}",
                          "-c", "security.nesting=true", "-d", f"root,size={disk}GB")
        if not rc: break
        err = f"[{img}] {o}"; await lxc("delete", full, "--force")
    if rc: return None, err[-800:]
    for _ in range(40):
        if (await lxc("exec", full, "--", "true"))[0] == 0: break
        await asyncio.sleep(2)
    script = (f"{SETUP[fam]} && echo 'root:{pw}' | chpasswd && sed -i -E "
              "'s/^#?PermitRootLogin.*/PermitRootLogin yes/;s/^#?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config"
              " && (systemctl restart ssh sshd 2>/dev/null || rc-service sshd restart)")
    for _ in range(4):
        rc, o = await lxc("exec", full, "--", "sh", "-c", script)
        if rc == 0: break
        await asyncio.sleep(6)
    return pw, (o[-300:] if rc else "")

async def free_name(user):
    base = re.sub(r"[^a-z0-9-]", "", user.lower()).strip("-")[:30] or "vps"
    if not base[0].isalpha(): base = "u" + base
    n, name = 1, base
    while name in db["vps"] or (await lxc("info", name))[0] == 0:
        n += 1; name = f"{base}-{n}"
    return name

async def create_vps(owner, os_t, name, ram, cpu, disk):
    full = await free_name(name)
    pw, w = await build(os_t, full, ram, cpu, disk)
    if pw is None: return None, w
    db["vps"][full] = dict(name=full, owner=owner, os=os_t[0], ram=ram, cpu=cpu, disk=disk, created=int(time.time()))
    save()
    return (full, pw), w

async def send_ready(i, full, title):
    """DM the user that the VPS is ready (no username / password is ever sent)."""
    e = discord.Embed(title=title, color=0x22C55E, description=f"**{full}**\nUse `{PREFIX}manage` → 🖥️ WebSSH to open your terminal.")
    try:
        await i.user.send(embed=e); return "Details sent to your DMs 📩"
    except discord.Forbidden:
        return "Your DMs are closed – use the panel's WebSSH button to connect."

async def do_deploy(i, os_t):
    mine = [v for v in db["vps"].values() if v["owner"] == i.user.id]
    if len(mine) >= MAX_VPS and not is_admin(i.user.id):
        return await i.response.send_message(f"❌ You can only have {MAX_VPS} VPS.", ephemeral=True)
    ram, cpu, disk = DEF_RAM, DEF_CPU, DEF_DISK
    await i.response.edit_message(view=None, embed=discord.Embed(title="⏳ Deploying...", color=COLOR,
        description=f"**{os_t[0]}** • {ram}GB / {cpu}C / {disk}GB\nPlease wait (1-3 min).").set_footer(text=BOT_NAME))
    res, err = await create_vps(i.user.id, os_t, i.user.name, ram, cpu, disk)
    if not res:
        return await i.edit_original_response(embed=discord.Embed(title="❌ Deploy failed", description=f"```{err}```", color=0xEF4444))
    full, pw = res
    note = await send_ready(i, full, "✅ VPS Ready")
    await i.edit_original_response(content=note, embed=discord.Embed(title="✅ VPS Ready", description=f"`{full}`", color=0x22C55E))

async def do_reinstall(i, v, os_t):
    await i.response.edit_message(view=None, embed=discord.Embed(title="⏳ Reinstalling...", color=COLOR,
        description=f"**{v['name']}** → **{os_t[0]}** • {v['ram']}GB / {v['cpu']}C / {v['disk']}GB\nPlease wait (1-3 min).").set_footer(text=BOT_NAME))
    await lxc("delete", v["name"], "--force")
    pw, err = await build(os_t, v["name"], v["ram"], v["cpu"], v["disk"])
    if pw is None:
        return await i.edit_original_response(embed=discord.Embed(title="❌ Reinstall failed", color=0xEF4444,
            description=f"The old VPS was already removed. Run `{PREFIX}manage` → Reinstall to try again.\n```{err}```"))
    v["os"] = os_t[0]; save()
    note = await send_ready(i, v["name"], "✅ VPS Reinstalled")
    p = Panel(v); p.live(await i.edit_original_response(content=note, embed=await panel_embed(v, p), view=p))

class ReinstallView(discord.ui.View):
    """Select new OS -> confirm."""
    def __init__(s, v, os_t=None):
        super().__init__(timeout=300); s.v, s.os_t = v, os_t
        if os_t is None:
            sel = discord.ui.Select(placeholder="💿 Select new OS", options=[discord.SelectOption(label=o[0], value=o[1]) for o in OSES[:25]])
            async def cb(i):
                o = next(x for x in OSES if x[1] == sel.values[0])
                e = discord.Embed(title="♻️ Confirm Reinstall", color=0xF59E0B,
                    description=f"**{v['name']}** will be reinstalled with **{o[0]}**.\n⚠️ All data on this VPS will be permanently erased.")
                await i.response.edit_message(embed=e, view=ReinstallView(v, o))
            sel.callback = cb; s.add_item(sel)
        else:
            ok = discord.ui.Button(label="Confirm Reinstall", emoji="♻️", style=discord.ButtonStyle.danger)
            async def okcb(i): await do_reinstall(i, s.v, s.os_t)
            ok.callback = okcb; s.add_item(ok)
        cancel = discord.ui.Button(label="Cancel", style=discord.ButtonStyle.secondary)
        async def ccb(i):
            p = Panel(s.v); await i.response.defer(); p.live(await i.edit_original_response(embed=await panel_embed(s.v, p), view=p))
        cancel.callback = ccb; s.add_item(cancel)
    async def interaction_check(s, i):
        ok = i.user.id == s.v["owner"] or is_admin(i.user.id)
        if not ok: await i.response.send_message("❌ This VPS doesn't belong to you.", ephemeral=True)
        return ok

def step_embed(title, desc, os_l=None):
    e = discord.Embed(title=title, description=desc, color=COLOR).set_footer(text=BOT_NAME)
    if os_l: e.add_field(name="💿 OS", value=f"`{os_l}`")
    return e

class DeployView(discord.ui.View):
    """OS -> Deploy"""
    def __init__(s, uid, os_t=None):
        super().__init__(timeout=300); s.uid, s.os_t = uid, os_t
        if os_t is None:
            sel = discord.ui.Select(placeholder="💿 Select OS", options=[discord.SelectOption(label=o[0], value=o[1]) for o in OSES[:25]])
            async def cb(i):
                o = next(x for x in OSES if x[1] == sel.values[0])
                await i.response.edit_message(embed=step_embed("🚀 Deploy", "Now press **Deploy**.", o[0]), view=DeployView(s.uid, o))
            sel.callback = cb; s.add_item(sel)
        else:
            go = discord.ui.Button(label="Deploy", emoji="🚀", style=discord.ButtonStyle.success)
            async def gocb(i): await do_deploy(i, s.os_t)
            go.callback = gocb; s.add_item(go)
    async def interaction_check(s, i): return i.user.id == s.uid

# ---------------------------------------------------------------- manage panel
TOKENS = {}
async def panel_embed(v, view=None):
    f = await vps_info(v)
    on = f["status"] == "Running"
    if view: view.sync(on)  # enable/disable Start & Stop
    if on:
        lim = v["ram"] * 1024
        disk = f"{f['disk']:.1f}/{v['disk']} GB ({f['disk'] / v['disk'] * 100:.1f}%)" if f["disk"] is not None else "Unknown"
        live = f"**CPU Usage:** {f['cpu_pct']:.1f}%\n**Memory:** {f['mem']:.0f}/{lim} MB ({f['mem'] / lim * 100:.1f}%)\n**Disk:** {disk}"
    else:
        live = "**CPU Usage:** -\n**Memory:** -\n**Disk:** -"
    d = (f"Managing container: `{v['name']}`\n\n"
         f"**📊 Allocated Resources**\n"
         f"**Configuration:** {v['ram']}GB RAM / {v['cpu']} CPU / {v['disk']}GB Disk\n"
         f"**Status:** `{f['status'].upper()}`\n"
         f"**RAM:** {v['ram']}GB\n"
         f"**CPU:** {v['cpu']} Cores\n"
         f"**Storage:** {v['disk']}GB\n"
         f"**OS:** {v['os']}\n"
         f"**Uptime:** {f['uptime']}\n\n"
         f"**📈 Live Usage**\n{live}")
    e = discord.Embed(title=f"{'🟢' if on else '🔴'} {v['name']}", description=d, color=0x22C55E if on else 0xEF4444,
                      timestamp=discord.utils.utcnow())
    return e.set_footer(text=f"{BOT_NAME} • live, updates every {LIVE_SEC}s" if LIVE_ON else BOT_NAME)

class Live(discord.ui.View):
    """View whose message can auto-refresh (LIVE_REFRESH) and disables itself on timeout."""
    msg = None
    async def render(s): raise NotImplementedError
    def live(s, msg):
        s.msg = msg
        if LIVE_ON: asyncio.create_task(s._loop())
    async def _loop(s):
        while not s.is_finished():
            await asyncio.sleep(LIVE_SEC)
            if s.is_finished(): break
            try: await s.msg.edit(embed=await s.render(), view=s)
            except discord.HTTPException: break
    async def on_timeout(s):
        for c in s.children: c.disabled = True
        try: await s.msg.edit(view=s)
        except Exception: pass

async def stats_embed(v):
    f = await vps_info(v)
    on = f["status"] == "Running"
    lim = v["ram"] * 1024
    e = discord.Embed(title=f"📊 Full Stats • {v['name']}", color=0x22C55E if on else 0xEF4444, timestamp=discord.utils.utcnow())
    e.add_field(name="🧾 General", inline=False, value=(f"**Status:** `{f['status'].upper()}`  •  **Uptime:** {f['uptime']}\n"
        f"**OS:** {v['os']}\n**Created:** <t:{v.get('created', 0)}:f>"))
    e.add_field(name="📦 Plan", value=f"**RAM:** {v['ram']}GB\n**CPU:** {v['cpu']} Cores\n**Disk:** {v['disk']}GB")
    if on:
        disk = (f"{bar(f['disk'] / v['disk'] * 100)}\n`{f['disk']:.1f}` / `{v['disk']}` GB\n**{f['disk'] / v['disk'] * 100:.1f}%**"
                if f["disk"] is not None else "Unknown")
        e.add_field(name="⚙️ CPU", value=f"{bar(f['cpu_pct'])}\n**{f['cpu_pct']:.1f}%**\nTime: `{fmt_dur(f['cpu'])}`\nProcesses: `{f['procs']}`")
        e.add_field(name="🧠 Memory", value=f"{bar(f['mem'] / lim * 100)}\n`{f['mem']:.0f}` / `{lim}` MB\n**{f['mem'] / lim * 100:.1f}%**\nPeak: `{f['mem_peak']:.0f}` MB\nSwap: `{f['swap']:.0f}` MB")
        e.add_field(name="💾 Disk", value=disk)
        e.add_field(name="🌐 Network", value=f"⬇️ Received: `{hb(f['rx'])}`\n⬆️ Sent: `{hb(f['tx'])}`")
    else:
        e.add_field(name="⚙️ Live stats", inline=False, value="VPS is offline – start it to see CPU, memory, disk and network stats.")
    return e.set_footer(text=f"{BOT_NAME} • live, updates every {LIVE_SEC}s" if LIVE_ON else BOT_NAME)

class StatsView(Live):
    """Full stats page (opened from the panel's Stats button)."""
    def __init__(s, v): super().__init__(timeout=600); s.v = v
    async def render(s): return await stats_embed(s.v)
    async def interaction_check(s, i):
        ok = i.user.id == s.v["owner"] or is_admin(i.user.id)
        if not ok: await i.response.send_message("❌ This VPS doesn't belong to you.", ephemeral=True)
        return ok
    @discord.ui.button(label="Back", emoji="⬅️", style=discord.ButtonStyle.secondary)
    async def back(s, i, b):
        s.stop(); p = Panel(s.v); await i.response.defer()
        p.live(await i.edit_original_response(embed=await panel_embed(s.v, p), view=p))
    @discord.ui.button(label="Refresh", emoji="🔃", style=discord.ButtonStyle.secondary)
    async def refresh(s, i, b):
        await i.response.defer(); await i.edit_original_response(embed=await stats_embed(s.v), view=s)

class Panel(Live):
    def __init__(s, v): super().__init__(timeout=600); s.v, s.armed, s.msg = v, False, None
    async def render(s): return await panel_embed(s.v, s)
    def sync(s, on):
        s.b1.disabled = on        # VPS is ON  -> Start disabled
        s.b2.disabled = not on    # VPS is OFF -> Stop disabled
    async def interaction_check(s, i):
        ok = i.user.id == s.v["owner"] or is_admin(i.user.id)
        if not ok: await i.response.send_message("❌ This VPS doesn't belong to you.", ephemeral=True)
        return ok
    async def act(s, i, *cmd):
        await i.response.defer(); s.armed = False
        rc, o = await lxc(*cmd)
        await i.edit_original_response(embed=await panel_embed(s.v, s), view=s)
        if rc: await i.followup.send(f"⚠️ ```{o[-500:]}```", ephemeral=True)
    @discord.ui.button(label="Start", emoji="▶️", style=discord.ButtonStyle.success)
    async def b1(s, i, b): await s.act(i, "start", s.v["name"])
    @discord.ui.button(label="Stop", emoji="⏹️", style=discord.ButtonStyle.danger)
    async def b2(s, i, b): await s.act(i, "stop", s.v["name"], "--force")
    @discord.ui.button(label="Restart", emoji="🔄", style=discord.ButtonStyle.primary)
    async def b3(s, i, b): await s.act(i, "restart", s.v["name"], "--force")
    @discord.ui.button(label="Stats", emoji="📊", style=discord.ButtonStyle.secondary, row=1)
    async def b4(s, i, b):
        s.stop(); sv = StatsView(s.v); await i.response.defer()  # hand the message over to the stats page
        sv.live(await i.edit_original_response(embed=await stats_embed(s.v), view=sv))
    @discord.ui.button(label="Refresh", emoji="🔃", style=discord.ButtonStyle.secondary, row=0)
    async def b_refresh(s, i, b):
        await i.response.defer(); s.armed = False
        for c in s.children:
            if getattr(c, "label", "") == "Confirm Delete": c.label = "Delete"
        e = await panel_embed(s.v, s)
        e.timestamp = datetime.utcnow()
        await i.edit_original_response(embed=e, view=s)
    @discord.ui.button(label="WebSSH", emoji="🖥️", style=discord.ButtonStyle.primary, row=1)
    async def b5(s, i, b):
        t = secrets.token_urlsafe(24); TOKENS[t] = {"v": s.v, "exp": time.time() + 900}
        v = discord.ui.View(); v.add_item(discord.ui.Button(label="Open WebSSH", url=f"{WEBSSH_URL}/?token={t}"))
        await i.response.send_message("🔐 This link is valid for 15 minutes.", view=v, ephemeral=True)
    @discord.ui.button(label="Reinstall", emoji="♻️", style=discord.ButtonStyle.secondary, row=1)
    async def b_reinstall(s, i, b):
        s.armed = False; s.stop()
        e = discord.Embed(title="♻️ Reinstall VPS", color=0xF59E0B,
            description=f"Select a new OS for **{s.v['name']}**.\nThe plan stays the same ({s.v['ram']}GB / {s.v['cpu']}C / {s.v['disk']}GB).\n⚠️ All data will be erased.")
        await i.response.edit_message(embed=e, view=ReinstallView(s.v))
    @discord.ui.button(label="Delete", emoji="🗑️", style=discord.ButtonStyle.danger, row=1)
    async def b6(s, i, b):
        if not s.armed:
            s.armed = True; b.label = "Confirm Delete"; return await i.response.edit_message(view=s)
        await i.response.defer(); await lxc("delete", s.v["name"], "--force")
        db["vps"].pop(s.v["name"], None); save(); s.stop()
        await i.edit_original_response(embed=discord.Embed(title="🗑️ Deleted", description=s.v["name"], color=0xEF4444), view=None)

# ---------------------------------------------------------------- bot
intents = discord.Intents.default(); intents.message_content = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents, help_command=None)

def help_pages():
    def P(cat, body):
        e = discord.Embed(title=f"📚 {HELP_NAME} Command Help - {cat}", description=body, color=COLOR, timestamp=discord.utils.utcnow())
        return e.set_footer(text=f"{HELP_NAME} VPS Manager • {cat.split(' ', 1)[1]} • Need help? Contact admin")
    return {
        "user": P("👤 User Commands", f"**👤 User Commands**\nUse the dropdown below to switch categories.\n\n"
            f"💡 Tip: Use `{PREFIX}my-vps` to see all your VPS and `{PREFIX}manage` to control them.\n\n**Commands**\n"
            f"**{PREFIX}ping** - Check bot latency\n**{PREFIX}uptime** - Show host uptime\n**{PREFIX}my-vps** - List your VPS\n"
            f"**{PREFIX}manage** - Manage your VPS\n**{PREFIX}deploy** - Deploy a new VPS"),
        "deploy": P("🚀 Deploy Guide", f"**🚀 Deploy Guide**\nUse the dropdown below to switch categories.\n\n"
            f"1. Run `{PREFIX}deploy`\n2. Select an **OS**\n3. Press **Deploy** – your VPS is created automatically\n"
            f"4. Run `{PREFIX}manage` to manage your VPS\n\n"
            f"Plan: {DEF_RAM}GB RAM • {DEF_CPU} CPU • {DEF_DISK}GB Disk • max {MAX_VPS} VPS per user"),
        "admin": P("👑 Admin Commands", f"**👑 Admin Commands**\nUse the dropdown below to switch categories.\n\n**Commands**\n"
            f"**{PREFIX}manage [@user]** - Manage any user's VPS\n**{PREFIX}all-vps** - List all VPS")}

class HelpView(discord.ui.View):
    def __init__(s): super().__init__(timeout=300); s.p = help_pages()
    @discord.ui.select(placeholder="Select Category", options=[discord.SelectOption(label=l, value=v, emoji=e) for l, v, e in
        [("User Commands", "user", "👤"), ("Deploy Guide", "deploy", "🚀"), ("Admin Commands", "admin", "👑")]])
    async def sel(s, i, sel): await i.response.edit_message(embed=s.p[sel.values[0]], view=s)

@bot.command()
async def help(ctx): await ctx.send(embed=help_pages()["user"], view=HelpView())

@bot.command()
async def ping(ctx):
    await ctx.send(embed=discord.Embed(title="🏓 Pong!", description=f"Bot latency: `{round(bot.latency * 1000)} ms`", color=COLOR))

@bot.command()
async def uptime(ctx):
    rc, o = await run("uptime -p", 10)
    await ctx.send(embed=discord.Embed(title="⏱️ Uptime", color=COLOR,
        description=f"**Host:** {o if rc == 0 else 'unknown'}\n**Bot:** up {fmt_dur(time.time() - START)}"))

@bot.command(name="my-vps")
async def myvps(ctx):
    vs = [v for v in db["vps"].values() if v["owner"] == ctx.author.id]
    if not vs: return await ctx.send(f"❌ You don't have any VPS. Use `{PREFIX}deploy`.")
    d = "\n".join(f"**{n}.** `{v['name']}` • {v['os']} • {v['ram']}GB / {v['cpu']}C / {v['disk']}GB" for n, v in enumerate(vs, 1))
    await ctx.send(embed=discord.Embed(title="🖥️ Your VPS", description=d, color=COLOR).set_footer(text=f"Use {PREFIX}manage to control them."))

@bot.command()
async def deploy(ctx):
    await ctx.send(embed=step_embed("🚀 Deploy", "Select an **OS**."), view=DeployView(ctx.author.id))

@bot.command()
async def manage(ctx, target: discord.Member = None):
    if target and target.id != ctx.author.id and not is_admin(ctx.author.id):
        return await ctx.send("❌ Only admins can manage another user's VPS.")
    owner = target or ctx.author
    vs = [v for v in db["vps"].values() if v["owner"] == owner.id][:25]
    if not vs: return await ctx.send(f"❌ {'You don' if owner == ctx.author else owner.display_name + ' doesn'}'t have any VPS." + (f" Use `{PREFIX}deploy`." if owner == ctx.author else ""))
    if len(vs) == 1:  # ek hi VPS -> seedha panel
        p = Panel(vs[0]); p.live(await ctx.send(embed=await panel_embed(vs[0], p), view=p)); return
    view = discord.ui.View(timeout=300)
    sel = discord.ui.Select(placeholder="Select VPS", options=[discord.SelectOption(label=v["name"], description=v['os'], value=v["name"]) for v in vs])
    async def cb(i):
        if i.user.id != ctx.author.id: return await i.response.send_message("❌", ephemeral=True)
        v = db["vps"][sel.values[0]]; await i.response.defer()
        p = Panel(v); p.live(await i.edit_original_response(embed=await panel_embed(v, p), view=p))
    sel.callback = cb; view.add_item(sel)
    await ctx.send(embed=discord.Embed(title="🛠️ Your VPS", color=COLOR), view=view)

@bot.command(name="all-vps")
async def allvps(ctx):
    if not is_admin(ctx.author.id): return
    t = "\n".join(f"`{v['name']}` <@{v['owner']}> {v['os']} {v['ram']}G/{v['cpu']}C/{v['disk']}G" for v in db["vps"].values()) or "Empty"
    await ctx.send(embed=discord.Embed(title="📋 All VPS", description=t[:4000], color=COLOR))

# ---------------------------------------------------------------- WebSSH backend (pty <-> websocket <-> xterm.js)
def exec_argv(v):
    sh = "command -v bash >/dev/null && exec bash -l || exec sh -l"
    c = ["lxc", "exec", v["name"], "--env", "TERM=xterm-256color", "--", "sh", "-c", sh]
    return c

async def ws_handler(req):
    tk = TOKENS.get(req.query.get("token", ""))
    if not tk or tk["exp"] < time.time(): raise web.HTTPForbidden()
    ws = web.WebSocketResponse(heartbeat=20); await ws.prepare(req)
    argv = exec_argv(tk["v"]); pid, fd = pty.fork()
    if pid == 0: os.execvp(argv[0], argv)
    loop, q = asyncio.get_running_loop(), asyncio.Queue()
    def rd():
        try: d = os.read(fd, 65536)
        except OSError: d = b""
        q.put_nowait(d)
        if not d: loop.remove_reader(fd)
    loop.add_reader(fd, rd)
    async def pump():
        while d := await q.get(): await ws.send_bytes(d)
        await ws.close()
    task = asyncio.create_task(pump())
    try:
        async for m in ws:
            if m.type != web.WSMsgType.TEXT: continue
            j = json.loads(m.data)
            if j["t"] == "i": os.write(fd, j["d"].encode())
            elif j["t"] == "r": fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", j["rows"], j["cols"], 0, 0))
    finally:
        task.cancel()
        try: loop.remove_reader(fd); os.kill(pid, signal.SIGKILL); os.waitpid(pid, 0); os.close(fd)
        except Exception: pass
    return ws

async def index(req):
    if req.query.get("token", "") not in TOKENS: raise web.HTTPForbidden(text="Invalid / expired link")
    return web.FileResponse(os.path.join(os.path.dirname(__file__), "webssh.html"))

@bot.event
async def setup_hook():
    app = web.Application(); app.add_routes([web.get("/", index), web.get("/webssh.html", index), web.get("/ws", ws_handler)])
    r = web.AppRunner(app); await r.setup(); await web.TCPSite(r, WEB_HOST, WEB_PORT).start()

@bot.event
async def on_ready():
    await bot.change_presence(activity=discord.Game(f"{PREFIX}help • {BOT_NAME}"))
    print("=" * 56 + "\n   RFRS LXC BOT 1.0 PRO\n" + "=" * 56)
    print(f"{BOT_NAME} online as {bot.user} | WebSSH on {WEB_HOST}:{WEB_PORT}")

if not E("DISCORD_TOKEN"): raise SystemExit("DISCORD_TOKEN is missing - fill it in your .env file")
bot.run(E("DISCORD_TOKEN"))
