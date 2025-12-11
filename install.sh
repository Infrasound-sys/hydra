#!/data/data/com.termux/files/usr/bin/bash

# ==================================================
# HYDRA PUBLIC INSTALLER (Visual + Admin Core)
# ==================================================

# Цвета
R='\033[1;31m'; G='\033[1;32m'; B='\033[1;34m'; C='\033[1;36m'; N='\033[0m'

clear
echo -e "${B}"
echo "██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗ "
echo "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗"
echo "███████║ ╚████╔╝ ██║  ██║██████╔╝███████║"
echo "██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██╔══██║"
echo "██║  ██║   ██║   ██████╔╝██║  ██║██║  ██║"
echo "╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝"
echo -e "${N}"
echo -e "${C}>>> SYSTEM DEPLOYMENT INITIATED...${N}\n"

# 1. ЗАВИСИМОСТИ
echo -e "${B}[*] Установка компонентов...${N}"
pkg update -y -o Dpkg::Options::="--force-confnew" >/dev/null 2>&1
pkg install -y python rust binutils build-essential zsh termux-api termux-tools git wget >/dev/null 2>&1
pip install requests telethon >/dev/null 2>&1

# 2. ВИЗУАЛИЗАЦИЯ (ZSH + THEMES)
echo -e "${B}[*] Настройка интерфейса...${N}"
HYDRA_HOME="$HOME/hydra_core"
BIN_DIR="/data/data/com.termux/files/usr/bin"
mkdir -p "$HYDRA_HOME"

# Удаляем старое приветствие
if [ -f "/data/data/com.termux/files/usr/etc/motd" ]; then
    rm /data/data/com.termux/files/usr/etc/motd
    touch /data/data/com.termux/files/usr/etc/motd
fi

# Конфигурация ZSH
cat <<'ZSH' > $HOME/.zshrc
export PATH=$HOME/bin:/usr/local/bin:$PATH
export HYDRA_HOME="$HOME/hydra_core"
# Алиасы
alias cls='clear'
alias py='python'
alias ..='cd ..'
alias hydra='python $HYDRA_HOME/run.py'
alias cfg='nano $HYDRA_HOME/config.json'
alias update='pkg update -y && pkg upgrade -y'

# Стиль (Cyberpunk)
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'
PROMPT='%F{033}┌──[%F{045}%n%F{033}@%F{045}HYDRA%F{033}]─[%F{226}%~%F{033}] %F{240}${vcs_info_msg_0_}%f
%F{033}└─%F{049}❯%f '
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt SHARE_HISTORY

# Приветствие
clear
echo -e "\033[1;35mHYDRA TERMINAL ACCESS GRANTED\033[0m"
echo -e "\033[0;36mSystem Status: Online\033[0m\n"
ZSH

chsh -s zsh

# Утилита тем (ui)
cat <<'UI' > $BIN_DIR/ui
#!/data/data/com.termux/files/usr/bin/bash
echo -e "\033[1;34m=== HYDRA UI ===\033[0m"
echo "1. Cyber (Default)"
echo "2. Matrix"
echo "3. Red Alert"
read -p "> " t
mkdir -p ~/.termux
case $t in
    1) echo "background=#090c10" > ~/.termux/colors.properties; echo "foreground=#d2d9df" >> ~/.termux/colors.properties ;;
    2) echo "background=#001a00" > ~/.termux/colors.properties; echo "foreground=#00ff00" >> ~/.termux/colors.properties ;;
    3) echo "background=#1a0000" > ~/.termux/colors.properties; echo "foreground=#ff0000" >> ~/.termux/colors.properties ;;
esac
termux-reload-settings
echo -e "\033[1;32mTheme Applied.\033[0m"
UI
chmod +x $BIN_DIR/ui

# 3. ИНТЕРАКТИВНАЯ НАСТРОЙКА
echo -e "\n${C}>>> SECURITY SETUP${N}"
echo "Пожалуйста, введите ваши ключи доступа."
echo "(Они сохраняются только локально на вашем устройстве)"

read -p "1. Telegram App ID: " TG_ID
read -p "2. Telegram App Hash: " TG_HASH
read -p "3. Telegram Bot Token: " TG_TOKEN
read -p "4. Gemini API Key: " GEM_KEY
read -p "5. GitHub Token (Optional backup): " GIT_TOKEN

# Создаем конфиг
cat <<JSON > $HYDRA_HOME/config.json
{
    "telegram": {
        "api_id": $TG_ID,
        "api_hash": "$TG_HASH",
        "bot_token": "$TG_TOKEN"
    },
    "ai": {
        "gemini_key": "$GEM_KEY",
        "github_token": "$GIT_TOKEN",
        "model": "gemini-1.5-pro"
    }
}
JSON

# 4. ЯДРО (ADMIN CORE)
cat <<'PYTHON' > $HYDRA_HOME/run.py
import os, sys, json, requests, asyncio, subprocess, time, io
from telethon import TelegramClient, events, functions, types

BASE = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(BASE, "config.json"), "r") as f: CFG = json.load(f)
IMG = os.path.join(BASE, "capture.jpg")

class Sys:
    @staticmethod
    def sh(c):
        try: return subprocess.run(c, shell=True, capture_output=True, text=True, timeout=15).stdout.strip()[:4000]
        except: return "ERR"
    @staticmethod
    def snap():
        try:
            Sys.sh(f"termux-camera-photo -c 0 {IMG}"); time.sleep(1.5)
            if os.path.exists(IMG) and os.path.getsize(IMG)>0: return IMG
        except: pass
    @staticmethod
    def net(): return Sys.sh("ifconfig | grep inet | grep -v 127.0.0.1")

class AI:
    def __init__(self):
        self.k1 = CFG['ai']['gemini_key']
        self.k2 = CFG['ai'].get('github_token')
        self.mem = {}
        self.sys = "HYDRA OS. Role: Root Admin. Style: Terminal."
    
    def log(self, uid, u, m):
        if uid not in self.mem: self.mem[uid] = []
        self.mem[uid].extend([{"role":"user","parts":[{"text":u}]},{"role":"model","parts":[{"text":m}]}])
        if len(self.mem[uid])>10: self.mem[uid]=self.mem[uid][-10:]

    def query(self, uid, txt):
        try:
            r = requests.post(f"https://generativelanguage.googleapis.com/v1beta/models/{CFG['ai']['model']}:generateContent?key={self.k1}", json={"contents": self.mem.get(uid, [])+[{"role":"user","parts":[{"text":txt}]}],"systemInstruction":{"parts":[{"text":self.sys}]}}, timeout=25)
            if r.status_code==200: 
                ans=r.json()['candidates'][0]['content']['parts'][0]['text']
                self.log(uid,txt,ans); return ans
        except: pass
        return self.backup(uid, txt)

    def backup(self, uid, txt):
        if not self.k2: return "`[ERR]` GEMINI LIMIT & NO BACKUP KEY"
        try:
            h=[{"role":"system","content":self.sys}] + [{"role":"user" if m['role']=="user" else "assistant","content":m['parts'][0]['text']} for m in self.mem.get(uid,[])] + [{"role":"user","content":txt}]
            r=requests.post("https://models.inference.ai.azure.com/chat/completions", headers={"Authorization":f"Bearer {self.k2}"}, json={"messages":h,"model":"gpt-4o"}, timeout=20)
            if r.status_code==200:
                ans=r.json()['choices'][0]['message']['content']
                self.log(uid,txt,ans); return f"{ans}\n`[BKUP]`"
        except: return "`[FAIL]`"
    
    def flush(self, uid): self.mem[uid]=[]

bot = TelegramClient('hydra_session', CFG['telegram']['api_id'], CFG['telegram']['api_hash']).start(bot_token=CFG['telegram']['bot_token'])
core = AI()

async def menu():
    await bot(functions.bots.SetBotCommandsRequest(scope=types.BotCommandScopeDefault(),lang_code='en',commands=[
        types.BotCommand("sh","Shell"),types.BotCommand("py","Python"),types.BotCommand("net","NetScan"),types.BotCommand("reset","Clear"),types.BotCommand("cam","Spy")
    ]))

@bot.on(events.NewMessage)
async def main(ev):
    if ev.out: return
    uid,txt = ev.sender_id, ev.text.strip(); cmd=txt.split()[0].lower(); arg=txt[len(cmd):].strip()
    res,file=None,None
    if cmd=="/start": await menu(); res="**HYDRA ONLINE**"
    elif cmd=="/sh": res=f"```\n{Sys.sh(arg)}\n```"
    elif cmd=="/py": 
        try: old=sys.stdout; sys.stdout=io.StringIO(); exec(arg,globals()); out=sys.stdout.getvalue(); sys.stdout=old; res=f"```\n{out}\n```"
        except Exception as e: res=str(e)
    elif cmd=="/net": res=Sys.net()
    elif cmd=="/reset": core.flush(uid); res="WIPED"
    elif cmd=="/cam": file=await asyncio.get_event_loop().run_in_executor(None,Sys.snap); res="SECURE" if file else "ERR"
    else: 
        async with bot.action(uid,'typing'): res=await asyncio.get_event_loop().run_in_executor(None,core.query,uid,txt)
    if file: await bot.send_file(uid,file,caption=res)
    elif res: await ev.respond(res)

bot.loop.run_until_complete(menu())
bot.run_until_disconnected()
PYTHON

# 5. ЯРЛЫК ЗАПУСКА
echo "#!/data/data/com.termux/files/usr/bin/bash" > $PREFIX/bin/hydra
echo "cd $HYDRA_HOME && python run.py" >> $PREFIX/bin/hydra
chmod +x $PREFIX/bin/hydra

echo -e "\n${G}УСТАНОВКА ЗАВЕРШЕНА!${N}"
echo -e "Пожалуйста, ${R}перезапустите Termux${N}."
echo -e "Для запуска используйте команду: ${C}hydra${N}"
o -e "Пожалуйста, ${R}перезапустите Termux${N}, чтобы применилась тема оформления."
echo -e "После перезапуска введите: ${C}hydra${N}"
