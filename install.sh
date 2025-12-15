#!/data/data/com.termux/files/usr/bin/bash

# Установка необходимых пакетов для расчетов и интерфейса
pkg install -y bc termux-api termux-tools zsh curl >/dev/null 2>&1

# 1. ОБНОВЛЕНИЕ .ZSHRC (Конфигурация терминала)
cat <<'EOF' > $HOME/.zshrc
# --- HYDRA ENV ---
export PATH=$HOME/bin:$PATH
export FORCE_COLOR=1
setopt PROMPT_SUBST
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# --- THEME & PROMPT ---
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'
PROMPT='%F{033}┌──[%F{045}%n%F{033}@%F{045}HYDRA%F{033}]─[%F{226}%~%F{033}] %F{240}${vcs_info_msg_0_}%f
%F{033}└─%F{049}❯%f '

# --- ALIASES (Бинды) ---
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

# --- STARTUP ART ---
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

# 2. СОЗДАНИЕ HYDRA DASHBOARD (Мониторинг без мерцания)
cat <<'DASH' > $PREFIX/bin/hydra_dash
#!/data/data/com.termux/files/usr/bin/bash

# Подготовка экрана
tput civis # Скрыть курсор
clear

# Цвета
C=$(tput setaf 6); G=$(tput setaf 2); R=$(tput setaf 1); Y=$(tput setaf 3); B=$(tput setaf 4); W=$(tput setaf 7); N=$(tput sgr0)

# Статические данные (получаем 1 раз при запуске)
KERNEL=$(uname -r | cut -d'-' -f1)
ANDROID=$(getprop ro.build.version.release)
MODEL=$(getprop ro.product.model)
IP_INT=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -n 1)
IP_EXT=$(curl -s --max-time 2 ifconfig.me || echo "Offline")

# Функция отрисовки бара
bar() {
    # $1=Label, $2=Value(%), $3=Color
    local w=16
    local f=$(echo "$2 / 100 * $w" | bc -l | awk '{printf("%d",$1 + 0.5)}')
    local e=$((w - f))
    printf "${W}%-6s ${3}[" "$1"
    for ((i=0; i<f; i++)); do printf "█"; done
    for ((i=0; i<e; i++)); do printf "░"; done
    printf "] ${W}%3d%%${N}" ${2%.*}
}

# Основной цикл
while true; do
    # Курсор в начало (0,0) - УБИРАЕТ МЕРЦАНИЕ
    tput cup 0 0

    # Сбор динамических данных
    # RAM
    R_TOT=$(free -m | awk '/Mem:/ {print $2}')
    R_USE=$(free -m | awk '/Mem:/ {print $3}')
    R_PRC=$(echo "$R_USE * 100 / $R_TOT" | bc)
    
    # Disk (Termux)
    D_USE=$(df /data | awk 'NR==2 {print $3}')
    D_TOT=$(df /data | awk 'NR==2 {print $2}')
    D_PRC=$(df /data | awk 'NR==2 {print $5}' | tr -d '%')
    
    # Battery & Load
    BAT=$(termux-battery-status 2>/dev/null)
    B_LVL=$(echo $BAT | grep -o '"percentage": [0-9]*' | awk '{print $2}' || echo "0")
    B_TMP=$(echo $BAT | grep -o '"temperature": [0-9.]*' | awk '{print $2}' || echo "0")
    LOAD=$(cat /proc/loadavg | awk '{print $1" "$2}')

    # --- ОТРИСОВКА ИНТЕРФЕЙСА ---
    echo "${B}"
    echo "██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗ "
    echo "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗"
    echo "███████║ ╚████╔╝ ██║  ██║██████╔╝███████║"
    echo "██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██╔══██║"
    echo "██║  ██║   ██║   ██████╔╝██║  ██║██║  ██║"
    echo "╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝"
    echo "${C}   >>> SYSTEM MONITORING ACTIVE <<<   ${N}"
    echo "─────────────────────────────────────────"
    
    # Секция Метрик
    echo "${Y}[ RESOURCES ]${N}"
    bar "RAM" "$R_PRC" "$G"; echo ""
    bar "DISK" "$D_PRC" "$C"; echo ""
    bar "BATT" "$B_LVL" "$R"; echo " ${R}${B_TMP}°C${N}"
    
    echo ""
    echo "${Y}[ SYSTEM INFO ]${N}"
    printf "${W}%-10s : ${G}%s${N}\n" "Device" "$MODEL (And $ANDROID)"
    printf "${W}%-10s : ${C}%s${N}\n" "Kernel" "$KERNEL"
    printf "${W}%-10s : ${B}%s${N}\n" "CPU Load" "$LOAD"
    printf "${W}%-10s : ${Y}%s${N}\n" "Local IP" "$IP_INT"
    printf "${W}%-10s : ${R}%s${N}\n" "Public IP" "$IP_EXT"
    
    echo ""
    echo "─────────────────────────────────────────"
    echo "${Y}[ COMMANDS REFERENCE ]${N}"
    printf "${C}%-8s${N} : %s\n" "cls" "Очистить экран"
    printf "${C}%-8s${N} : %s\n" "update" "Полное обновление пакетов"
    printf "${C}%-8s${N} : %s\n" "cfg" "Редактировать .zshrc"
    printf "${C}%-8s${N} : %s\n" "myip" "Узнать свой IP"
    printf "${C}%-8s${N} : %s\n" "py" "Запуск Python"
    
    echo ""
    echo "${W}Press ${R}CTRL+C${W} to exit dashboard${N}"
    
    sleep 2
done
DASH

# Финализация
chmod +x $PREFIX/bin/hydra_dash
echo -e "\n\033[1;32mDONE! Перезапустите Termux.\033[0m"
EOF

chmod +x $HOME/.zshrc
bash $HOME/.zshrc >/dev/null 2>&1
