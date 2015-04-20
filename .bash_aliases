alias profileme="history | cut -f 2- -d \"]\" | awk 'BEGIN{FS=\"|\"}{print \$1}' | sort | uniq -c | sort -n | tail -n 20 | sort -nr"
alias IPAddress="ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print \$2}' | cut -f1  -d'/'"
alias df="df -Tm"
alias cp="cp -i"
alias cpr="cp -r"
alias mv="mv -i"
alias mkdir="mkdir -p"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias .......="cd ../../../../../.."
alias ........="cd ../../../../../../.."
alias .........="cd ../../../../../../../.."
alias ..........="cd ../../../../../../../../.."
alias ...........="cd ../../../../../../../../../.."
alias ............="cd ../../../../../../../../../../.."
alias .............="cd ../../../../../../../../../../../.."
alias ..............="cd ../../../../../../../../../../../../.."

alias doihave="dpkg --get-selections | grep"
alias wru="dpkg -L"
alias j='jobs'
alias jl='jobs -l'
alias free='free -m'
alias openports='sudo netstat -nape --inet'
alias ns='netstat -alnp --protocol=inet|grep -v CLOSE_WAIT|cut -c-6,21-94|tail'
alias sysinfo='uname -a && grep MemTotal /proc/meminfo && grep "model name" /proc/cpuinfo && lspci -tv && lsusb -tv && head -n1 /etc/issue'
alias ai='apt-cache show' 
alias aq='apt-cache search'
alias ag='sudo apt-get install'
alias aup='sudo apt-get update && sudo apt-get upgrade'
alias aupd='sudo apt-get update'
alias aarm='sudo apt-get autoremove'
alias aun='sudo apt-get remove'

## COLORS ##
alias ls='ls --color=auto --ignore-backups --time-style="+%x %X"'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias Logs='colortail -n40 -f /var/log/syslog'

alias MplayerCaca="mplayer -vo caca"
alias Syslog='sudo colortail -n1000 /var/log/syslog'
alias sslscan2="nmap --script +ssl-enum-ciphers -p443"
alias composer="composer --ansi"
alias xmlto='xmlto --skip-validation'
 alias ll='ls -al'
 