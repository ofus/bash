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

alias wru="dpkg -L"
alias j='jobs'
alias jl='jobs -l'
alias free='free -m'
alias openports='sudo netstat -nape --inet'
alias ns='netstat -alnp --protocol=inet|grep -v CLOSE_WAIT|cut -c-6,21-94|tail'
alias sysinfo='uname -a && grep MemTotal /proc/meminfo && grep "model name" /proc/cpuinfo && lspci -tv && lsusb -tv && head -n1 /etc/issue'
alias meminfo="sudo dmidecode -t memory && sudo lshw -class memory"
alias ai='apt-cache show' 
alias aidl='sudo apt-get install --download-only -y'
alias aq='apt-cache search'
alias ag='sudo apt-get install'
alias aupdl='sudo apt-get upgrade --download-only -y && sudo apt-get dist-upgrade --download-only -y'
alias aup='sudo apt-get update && sudo apt-get upgrade'
alias aupd='sudo apt-get update'
alias adup='sudo apt-get dist-upgrade'
alias aarm='sudo apt-get autoremove'
alias aun='sudo apt-get remove'
alias alist='dpkg --list | grep ^i'

alias pacg='sudo pacman -S'
alias pacq='sudo pacman -Ss'
alias pacup='sudo pacman -Syu'
alias pacun='sudo pacman -Rs'
alias pacarm='sudo pacman -Qdtq'
alias pacdl='sudo pacman -Sw'
alias paci='pacman -Si'
alias paclist='pacman -Q'

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

alias grm='git branch -D'
alias bb=bitbucket

alias now="date +%Y%m%d%H%M%S"
alias entropy="cat /proc/sys/kernel/random/entropy_avail"
alias m4a="youtube-dl -f 140"
alias mp3='youtube-dl -f 140 --extract-audio --audio-format mp3 --add-metadata --metadata-from-title "%(artist)s - %(title)s"'

# Decoding URL encoding (percent encoding)
# https://unix.stackexchange.com/a/159254
alias urldecode='python -c "import sys, urllib as ul; \
    print ul.unquote_plus(sys.argv[1])"'
alias urlencode='python -c "import sys, urllib as ul; \
    print ul.quote_plus(sys.argv[1])"'

###### SVN ########################
# add everything that needs to be added based on results of svn status
alias svnadd="svn st | grep \? | awk '''{print \"svn add \"$2 }''' | bash" 

# show svn status, sans the noise from externals
alias svnst='svn st --ignore-externals'

# edit svn:externals for the current folder in the editor
alias svnext='svn pe svn:externals .'

# edit svn:ignore for the current folder in the editor
alias svnign='svn pe svn:ignore .'

# recursively delete .svn folders from current directory
alias delsvn="find . -name .svn | xargs rm -rf"

# https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/nyan/nyan.plugin.zsh
if [[ -x `which nc` ]]; then
  alias nyan='nc -v nyancat.dakko.us 23' # nyan cat
fi
