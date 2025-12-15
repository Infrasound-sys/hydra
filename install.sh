#!/data/data/com.termux/files/usr/bin/bash

# ==================================================
# HYDRA SYSTEM OPTIMIZER & DASHBOARD INSTALLER
# ==================================================

R='\033[1;31m'; G='\033[1;32m'; B='\033[1;34m'; C='\033[1;36m'; Y='\033[1;33m'; N='\033[0m'

clear
echo -e "${C}[*] Инициализация процесса установки...${N}"

# 1. БАЗОВАЯ НАСТРОЙКА И ПРАВА
termux-setup-storage
echo -e "${B}[*] Обновление репозиториев и установка ядра...${N}"
pkg update -y -o Dpkg::Options::="--force-confnew"
pkg upgrade -y -o Dpkg::Options::="--force-confnew"

# Установка расширенного набора утилит
# bc - для расчетов в дашборде, procps - для системной инфо
pkg install -y python git zsh termux-api termux-tools \
    procps neofetch htop vim nano curl wget bc \
    zsh-syntax-highlighting zsh-autosuggestions

# 2. КОНФИГУРАЦИЯ ZSH (С ИСПРАВЛЕНИЯМИ)
echo -e "${B}[*] Генерация конфигурации ZSH...${N}"

cat <<'EOF' > $HOME/.zshrc
# --- ZSH SETTINGS ---
export PATH=$HOME/bin:$PATH
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt PROMPT_SUBST  # КРИТИЧНО ДЛЯ ВАШЕЙ ТЕМЫ

# --- PLUGINS ---
source $PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# --- THEME (CYBERPUNK - USER PRESET) ---
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'
# Исправленный Prompt с рабочим git-статусом
PROMPT='%F{033}┌──[%F{045}%n%F{033}@%F{045}HYDRA%F{033}]─[%F{226}%~%F{033}] %F{240}${vcs_info_msg_0_}%f
%F{033}└─%F{049}❯%f '

# --- ALIASES / BINDS ---
alias c='clear'
alias q='exit'
alias update='pkg update -y && pkg upgrade -y && pkg autoclean'
alias install='pkg install'
alias remove='pkg uninstall'
alias list='pkg list-installed'
alias myip='curl ifconfig.me'
alias storage='termux-setup-storage'
alias cfg='nano $HOME/.zshrc'
alias py='python'
alias hydra='bash $PREFIX/bin/hydra_dash'
alias ll='ls -lFh'
alias la='ls -lFha'

# --- WELCOME ---
clear
echo -e "\033[1;36mSYSTEM READY. TYPE 'hydra' FOR STATUS.\033[0m"
EOF

# Смена шелла
chsh -s zsh

# 3. СОЗДАНИЕ HYDRA DASHBOARD (ВИЗУАЛИЗАЦИЯ)
echo -e "${B}[*] Компиляция графического интерфейса Hydra...${N}"
cat <<'DASHBOARD' > $PREFIX/bin/hydra_dash
#!/data/data/com.termux/files/usr/bin/bash

# Цвета и курсоры
tput civis # Скрыть курсор
trap "tput cnorm; clear; exit" SIGINT # Вернуть курсор при выходе

C=$(tput setaf 6); G=$(tput setaf 2); R=$(tput setaf 1); Y=$(tput setaf 3); W=$(tput setaf 7); N=$(tput sgr0)
BOLD=$(tput bold)

draw_bar() {
    # $1 = Label, $2 = Value (0-100), $3 = Color
    local width=20
    local fill=$(echo "$2 / 100 * $width" | bc -l | awk '{printf("%d",$1 + 0.5)}')
    local empty=$((width - fill))
    printf "${W}%-7s ${3}[" "$1"
    for ((i=0; i<fill; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "] ${W}%3d%%${N}\n" ${2%.*}
}

while true; do
    clear
    # --- HEADER ---
    echo "${C}${BOLD}"
    echo " █  █ █ █ ██▄ █▄▄ ▄▀▄ "
    echo " █▀▄█ ▀▄▀ █▄█ █▄▀ █▀█ "
    echo "──────────────────────${N}"
    
    # --- INFO GATHERING ---
    # Батарея
    BAT_STATUS=$(termux-battery-status)
    BAT_LVL=$(echo $BAT_STATUS | grep -o '"percentage": [0-9]*' | awk '{print $2}')
    BAT_TEMP=$(echo $BAT_STATUS | grep -o '"temperature": [0-9.]*' | awk '{print $2}')
    
    # RAM
    RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
    RAM_PERC=$(echo "$RAM_USED * 100 / $RAM_TOTAL" | bc)
    
    # Storage (Termux internal)
    DISK_USED=$(df /data | awk 'NR==2 {print $3}')
    DISK_TOTAL=$(df /data | awk 'NR==2 {print $2}')
    DISK_PERC=$(df /data | awk 'NR==2 {print $5}' | tr -d '%')
    
    # Uptime
    UPTIME=$(uptime -p | sed 's/up //')

    # --- DISPLAY ---
    echo "${Y}SYSTEM METRICS:${N}"
    draw_bar "RAM" "$RAM_PERC" "$G"
    draw_bar "DISK" "$DISK_PERC" "$C"
    draw_bar "PWR" "$BAT_LVL" "$R"
    
    echo ""
    echo "${Y}DETAILED STATS:${N}"
    echo "${W}Device   :: ${G}$(getprop ro.product.model)${N}"
    echo "${W}Android  :: ${G}$(getprop ro.build.version.release)${N}"
    echo "${W}Kernel   :: ${C}$(uname -r)${N}"
    echo "${W}Uptime   :: ${C}$UPTIME${N}"
    echo "${W}Bat Temp :: ${R}${BAT_TEMP}°C${N}"
    echo "${W}Packages :: ${G}$(pkg list-installed | wc -l)${N}"
    echo "${W}Storage  :: ${C}${DISK_USED} / ${DISK_TOTAL} (Internal)${N}"
    
    echo ""
    echo "${C}──────────────────────${N}"
    echo "${BOLD}PRESS CTRL+C TO EXIT${N}"
    
    sleep 2
done
DASHBOARD

chmod +x $PREFIX/bin/hydra_dash

echo -e "\n${G}>>> УСТАНОВКА ЗАВЕРШЕНА!${N}"
echo -e "Пожалуйста, ${R}перезапустите Termux${N} прямо сейчас."
echo -e "После запуска введите команду ${C}hydra${N} для проверки дэшборда."
