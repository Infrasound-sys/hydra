#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# HYDRA: SYSTEM PERMISSIONS & CORE INSTALLER
# ==========================================

# Цвета
R='\033[1;31m'; G='\033[1;32m'; C='\033[1;36m'; Y='\033[1;33m'; N='\033[0m'

clear
echo -e "${C}>>> HYDRA INITIALIZATION SEQUENCE...${N}"

# [1] УСТАНОВКА ПАКЕТОВ (Исправлено: добавлен ncurses-utils)
echo -e "${Y}[*] Installing dependencies...${N}"
pkg update -y -o Dpkg::Options::="--force-confnew" >/dev/null 2>&1
pkg install -y bc termux-api termux-tools zsh curl ncurses-utils procps git >/dev/null 2>&1

# [2] ГРАНТ ВСЕХ РАЗРЕШЕНИЙ (PERMISSIONS GRANT)
echo -e "${Y}[*] Requesting System Permissions...${N}"

# 2.1 Доступ к хранилищу (Storage)
if [ ! -d "$HOME/storage" ]; then
    echo -e "${C}> Запрос доступа к памяти...${N}"
    termux-setup-storage
    sleep 2
fi

# 2.2 Блокировка сна (Wake Lock - чтобы скрипт работал в фоне)
echo -e "${C}> Активация Wake-Lock (High Performance)...${N}"
termux-wake-lock

# 2.3 Триггер API разрешений (Камера, Локация)
# Мы делаем "холостые" вызовы, чтобы Android показал диалог разрешения сейчас, а не потом.
echo -e "${C}> Инициализация API драйверов...${N}"
timeout 1 termux-location -r last >/dev/null 2>&1 & # Триггер GPS
timeout 1 termux-camera-photo -c 0 /dev/null >/dev/null 2>&1 & # Триггер Камеры

# [3] КОНФИГУРАЦИЯ ZSH
echo -e "${Y}[*] Configuring Shell...${N}"
cat <<'EOF' > $HOME/.zshrc
# --- HYDRA ENVIRONMENT ---
export PATH=$HOME/bin:$PATH
export FORCE_COLOR=1
setopt PROMPT_SUBST
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# --- THEME (Cyberpunk) ---
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'
PROMPT='%F{033}┌──[%F{045}%n%F{033}@%F{045}HYDRA%F{033}]─[%F{226}%~%F{033}] %F{240}${vcs_info_msg_0_}%f
%F{033}└─%F{049}❯%f '

# --- ALIASES (BINDINGS) ---
alias cls='clear'
alias c='clear'
alias q='exit'
alias update='pkg update -y && pkg upgrade -y && pkg autoclean'
alias inst='pkg install'
alias myip='curl -s ifconfig.me'
alias cfg='nano $HOME/.zshrc'
alias py='python'
alias hydra='bash $PREFIX/bin/hydra_dash'
alias speed='termux-info'
alias perm='termux-setup-storage' # Быстрый доступ к правам

# --- STARTUP SCREEN ---
clear
echo -e "\033[1;34m"
echo "██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗ "
echo "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗"
echo "███████║ ╚████╔╝ ██║  ██║██████╔╝███████║"
echo "██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██╔══██║"
echo "██║  ██║   ██║   ██████╔╝██║  ██║██║  ██║"
echo "╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝"
echo -e "\033[0m"
echo -e "\033[1;36mSystem Ready. Type \033[1;33mhydra\033[1;36m to open Dashboard.\033[0m"
EOF

# [4] УСТАНОВКА HYDRA DASHBOARD (С фиксом tput)
cat <<'DASH' > $PREFIX/bin/hydra_dash
#!/data/data/com.termux/files/usr/bin/bash

# Скрытие курсора и очистка
tput civis
clear

# Цветовая палитра
C=$(tput setaf 6); G=$(tput setaf 2); R=$(tput setaf 1); Y=$(tput setaf 3); B=$(tput setaf 4); W=$(tput setaf 7); N=$(tput sgr0)

# Сбор статических данных
KERNEL=$(uname -r | cut -d'-' -f1)
ANDROID=$(getprop ro.build.version.release)
MODEL=$(getprop ro.product.model)
# Безопасное получение IP (без спама ошибок)
IP_INT=$(ifconfig 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -n 1)
IP_EXT=$(curl -s --max-time 2 ifconfig.me || echo "Offline")

# Графический бар
bar() {
    local w=16
    local f=$(echo "$2 / 100 * $w" | bc -l | awk '{printf("%d",$1 + 0.5)}')
    local e=$((w - f))
    printf "${W}%-6s ${3}[" "$1"
    for ((i=0; i<f; i++)); do printf "█"; done
    for ((i=0; i<e; i++)); do printf "░"; done
    printf "] ${W}%3d%%${N}" ${2%.*}
}

# MAIN LOOP
while true; do
    tput cup 0 0 # Курсор в начало (No Flicker)

    # 1. RAM Calculation
    R_TOT=$(free -m | awk '/Mem:/ {print $2}')
    R_USE=$(free -m | awk '/Mem:/ {print $3}')
    R_PRC=$(echo "$R_USE * 100 / $R_TOT" | bc)
    
    # 2. Disk Usage (Termux partition only)
    D_USE=$(df /data | awk 'NR==2 {print $3}')
    D_TOT=$(df /data | awk 'NR==2 {print $2}')
    D_PRC=$(df /data | awk 'NR==2 {print $5}' | tr -d '%')
    
    # 3. Battery & Temps
    BAT=$(termux-battery-status 2>/dev/null)
    B_LVL=$(echo $BAT | grep -o '"percentage": [0-9]*' | awk '{print $2}' || echo "0")
    B_TMP=$(echo $BAT | grep -o '"temperature": [0-9.]*' | awk '{print $2}' || echo "0")
    B_STA=$(echo $BAT | grep -o '"status": "[^"]*"' | awk -F'"' '{print $4}')
    
    # 4. Processes (Safe Load Avg replacement)
    PROCS=$(ps -e | wc -l)

    # UI DRAW
    echo "${B}"
    echo "██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗ "
    echo "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗"
    echo "███████║ ╚████╔╝ ██║  ██║██████╔╝███████║"
    echo "██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██╔══██║"
    echo "██║  ██║   ██║   ██████╔╝██║  ██║██║  ██║"
    echo "╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝"
    echo "${C}   >>> SYSTEM MONITORING ACTIVE <<<   ${N}"
    echo "─────────────────────────────────────────"
    
    echo "${Y}[ RESOURCES ]${N}"
    bar "RAM" "$R_PRC" "$G"; echo ""
    bar "DISK" "$D_PRC" "$C"; echo ""
    bar "BATT" "$B_LVL" "$R"; echo " ${R}${B_TMP}°C${N} ($B_STA)"
    
    echo ""
    echo "${Y}[ SYSTEM INFO ]${N}"
    printf "${W}%-10s : ${G}%s${N}\n" "Device" "$MODEL (And $ANDROID)"
    printf "${W}%-10s : ${C}%s${N}\n" "Kernel" "$KERNEL"
    printf "${W}%-10s : ${B}%s${N}\n" "Procs" "$PROCS running"
    printf "${W}%-10s : ${Y}%s${N}\n" "Local IP" "$IP_INT"
    printf "${W}%-10s : ${R}%s${N}\n" "Public IP" "$IP_EXT"
    
    echo ""
    echo "─────────────────────────────────────────"
    echo "${Y}[ SHORTCUTS ]${N}"
    printf "${C}%-8s${N} : %s\n" "cls" "Очистка экрана"
    printf "${C}%-8s${N} : %s\n" "update" "Обновление системы"
    printf "${C}%-8s${N} : %s\n" "perm" "Сброс прав доступа"
    
    echo ""
    echo "${W}Press ${R}CTRL+C${W} to exit dashboard${N}"
    
    sleep 2
done
DASH

# [5] ФИНАЛИЗАЦИЯ
chmod +x $PREFIX/bin/hydra_dash
chmod +x $HOME/.zshrc

echo -e "\n${G}DONE! Termux настроен.${N}"
echo -e "${Y}Если появились окна разрешений — подтвердите их.${N}"
echo -e "Перезапустите Termux."

# Попытка применить конфиг сразу
bash $HOME/.zshrc >/dev/null 2>&1
