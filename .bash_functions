# Simple calculator
function calc() {
    local result=""
    result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')"
    #                       └─ default (when `--mathlib` is used) is 20
    #
    if [[ "$result" == *.* ]]; then
        # improve the output for decimal numbers
        printf "$result" |
        sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
            -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
            -e 's/0*$//;s/\.$//'   # remove trailing zeros
    else
        printf "$result"
    fi
    printf "\n"
}

# Determine size of a file or total size of a directory
function fs() {
    if du -b /dev/null > /dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi
    if [[ -n "$@" ]]; then
        du $arg -- "$@"
    else
        du $arg .[^.]* *
    fi
}

# Use Git’s colored diff when available
hash git &>/dev/null
if [ $? -eq 0 ]; then
    function diff() {
        git diff --no-index --color-words "$@"
    }
fi

# Create a data URL from a file
function dataurl() {
    local mimeType=$(file -b --mime-type "$1")
    if [[ $mimeType == text/* ]]; then
        mimeType="${mimeType};charset=utf-8"
    fi
    echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
    local port="${1:-8000}"
    sleep 1 && open "http://localhost:${port}/" &
    # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
    # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
    python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
function phpserver() {
    local port="${1:-4000}"
    local ip=$(ipconfig getifaddr en1)
    sleep 1 && open "http://${ip}:${port}/" &
    php -S "${ip}:${port}"
}

# Compare original and gzipped file size
function gz() {
    local origsize=$(wc -c < "$1")
    local gzipsize=$(gzip -c "$1" | wc -c)
    local ratio=$(echo "$gzipsize * 100/ $origsize" | bc -l)
    printf "orig: %d bytes\n" "$origsize"
    printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

# Test if HTTP compression (RFC 2616 + SDCH) is enabled for a given URL.
# Send a fake UA string for sites that sniff it instead of using the Accept-Encoding header. (Looking at you, ajax.googleapis.com!)
function httpcompression() {
    local encoding="$(curl -LIs -H 'User-Agent: Mozilla/5 Gecko' -H 'Accept-Encoding: gzip,deflate,compress,sdch' "$1" | grep '^Content-Encoding:')" && echo "$1 is encoded using ${encoding#* }" || echo "$1 is not using any encoding"
}

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
function json() {
    if [ -t 0 ]; then # argument
        python -mjson.tool <<< "$*" | pygmentize -l javascript
    else # pipe
        python -mjson.tool | pygmentize -l javascript
    fi
}

# All the dig info
function digga() {
    dig +nocmd "$1" any +multiline +noall +answer
}

# Escape UTF-8 characters into their 3-byte format
function escape() {
    printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
    echo # newline
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
    perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
    echo # newline
}

# Get a character’s Unicode code point
function codepoint() {
    perl -e "use utf8; print sprintf('U+%04X', ord(\"$@\"))"
    echo # newline
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
    if [ -z "${1}" ]; then
        echo "ERROR: No domain specified."
        return 1
    fi

    local str="${1}"
    if [[ $str == *"/"* ]]; then
        local domain="$(echo $str | awk -F/ '{print $3}')"
    else
        local domain="$str"
    fi

    echo "Testing ${domain}…"
    echo # newline

    local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
        | openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1);

    if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
        local certText=$(echo "${tmp}" \
            | openssl x509 -text -certopt "no_header, no_serial, no_version, \
            no_signame, no_validity, no_issuer, no_pubkey, no_sigdump, no_aux");
            echo "Common Name:"
            echo # newline
            echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//";
            echo # newline
            echo "Subject Alternative Name(s):"
            echo # newline
            echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
                | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
            return 0
    else
        echo "ERROR: Certificate not found.";
        return 1
    fi
}

function parse_bzr_dirty() {
    [[ $(bzr status 2> /dev/null | wc -l) != 0 ]] && echo "*"
}

function parse_bzr_changes() {
    BZR_CHANGES=$(bzr status 2> /dev/null | wc -l)
    [[ $BZR_CHANGES != 0 ]] && echo "[$BZR_CHANGES]"
}

function parse_git_dirty() {
    [[ $(git status 2> /dev/null | tail -n1) != *"working "*" clean"* ]] && echo "*"
}

function parse_git_branch() {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

function show_group_not_default() {
    if [ ! -f /etc/group ]; then
        return
    fi
    local u=$(whoami)
    local curgrp=$(id -gn)
    local defaultgrp=$(grep ":$(cat /etc/passwd | grep $u | cut -d: -f4):" /etc/group |  cut -d: -f1)
    [[ "$defaultgrp" == "" ]] && return 0
    if [ "$curgrp" != "$defaultgrp" ]; then
        echo "($curgrp)"
    fi
}

function aqg() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local aq="${1}"
    #apt-cache search $aq | grep -v "^lib"| grep -v "^python" | grep -v "^ttf" | grep -v "^ruby" | sort | grep -i --color $aq
    apt-cache search $aq | grep -v "^lib" | grep -v "^ttf" | sort | grep -i --color $aq
}

function pacqg() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local pacq="${1}"
    pacman -Sl | awk {' print $2 '} | grep -v "^lib" | sort | grep -i --color $pacq
}

function show_installed() {
    grep Install /var/log/apt/history.log | sed 's/Install: //g' | sed 's/:amd64//g' | sed 's/(/[/g' | sed 's/)/]/g' | sed -e 's/\[[^][]*\]//g' | sed 's/ , /\n/g'
}

function aiv() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local aq="${1}"
    apt-cache show $aq | grep Version
}

function psgrep() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local psquery="${1}"
    ps aux | head -n1
    ps aux | grep -v 'grep' | grep -i --color $psquery
}

function cq() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local foo="${@}"
    local cipherquery=$(echo $foo 2>/dev/null| sed 's/\ /\:/g' )
    local bar="$cipherquery:!eNULL:!aNULL:!ADH:!EXP:!PSK:!SRP:!DSS"
    cqn $bar | grep -v "PSK"
}

function cqn() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local foo="${@}"
    local cipherquery=$(echo $foo 2>/dev/null| sed 's/\ /\:/g' )
    local bar="$cipherquery"
    openssl ciphers -v "$bar" | column -t | grep -v "DH-"
}

function wp() {
    if ! type wikipedia2text > /dev/null; then
        echo "wikipedia2text not installed"
        return 1
    fi
    if [ -z "${1}" ]; then
        echo "E: You must give a hostname"
        return 1
    fi
    local host="${1}"
    wikipedia2text $host | $MANPAGER
}

function tlsscan() {
    if [ -z "${1}" ]; then
        echo "E: You must give a hostname"
        return 1
    fi
    local str="${1}"
    if [[ $str == *"/"* ]]; then
        local domain="$(echo $str | awk -F/ '{print $3}')"
    else
        local domain="$str"
    fi
    echo -e "GET / HTTP/1.0\nEOT" \
        | openssl s_client -connect $domain:443 -servername $domain -showcerts
}

function parse_svn_dirty() {
    [[ $(svn info 2> /dev/null | wc -l) >1 ]] && echo -n "*"
}

function svn_test() {
    if [ -d ".svn" ]; then
        echo "svn!"
    fi
}

function svn_check_for_remote_updates() {
    if [ -d ".svn" ]; then
        REMOTE_REVISION=$(svn info -r HEAD | grep -i "Last Changed Rev" | awk {' print $4 '} )
        MY_REVISION=$(svn info | grep -i "Last Changed Rev" | awk {' print $4 '} )
        [[ $REMOTE_REVISION == $MY_REVISION ]] && return
        SVN_REVISION_COUNT=$(calc $REMOTE_REVISION-$MY_REVISION)
        echo * $SVN_REVISION_COUNT CHANGES *
    fi
}

function rot13() {
    if [ -z "${1}" ]; then
        echo "E: You must give a string to convert"
        return 1
    fi
    local foo="${@}"
    echo "$foo" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
}

function get_sha() {
    git rev-parse --short HEAD 2>/dev/null
}

function get_dir() {
    printf "%s" $(pwd | sed "s:$HOME:~:")
}

function set_titlebar() {
    case $TERM in
        *xterm*|ansi|rxvt)
            printf "\033]0;%s\007" "$*"
            ;;
    esac
}

function getrandcolor() {
    local COLORNUM=$(shuf -i 17-231 -n 1)
    local NEWCOLOR=$(tput setaf $COLORNUM)
    echo $NEWCOLOR
}

function nolines() {
    tr '\n' ' '
    echo
}

function noblanklines() {
    sed '/^$/d'
}   

function 256colors() {
    local arg="${1}"
    if [ $arg == 2 ]; then
        for i in {0..255}; do echo -e "\e[38;05;${i}m${i}"; done | column -c 80 -s ' '; echo -e "\e[m"
    elif [ $arg == 3 ]; then
        T='gYw'   # The test text

        echo -e "\n                 40m     41m     42m     43m     44m     45m     46m     47m";

        for FGs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
                   '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
                   '  36m' '1;36m' '  37m' '1;37m';
          do FG=${FGs// /}
          echo -en " $FGs \033[$FG  $T  "
          for BG in 40m 41m 42m 43m 44m 45m 46m 47m;
            do echo -en "$EINS \033[$FG\033[$BG  $T  \033[0m";
          done
          echo;
        done
        echo
    else
        # This program is free software. It comes without any warranty, to
        # the extent permitted by applicable law. You can redistribute it
        # and/or modify it under the terms of the Do What The Fuck You Want
        # To Public License, Version 2, as published by Sam Hocevar. See
        # http://sam.zoy.org/wtfpl/COPYING for more details.
        for fgbg in 38 48 ; do #Foreground/Background
                for color in {0..256} ; do #Colors
                        #Display the color
                        if [ $color -lt 10 ]; then
                            echo -en "\e[${fgbg};5;${color}m ${color}   \e[0m"
                        elif [ $color -lt 100 ]; then
                            echo -en "\e[${fgbg};5;${color}m ${color}  \e[0m"
                        else
                            echo -en "\e[${fgbg};5;${color}m ${color} \e[0m"
                        fi

                        #Display 10 colors per lines
                        if [ $((($color - 15) % 36)) == 0 ] ; then
                            echo #New line
                        # elif [ $color == 15 ]; then
                        #     echo
                        elif [ $color == 231 ]; then
                            echo
                        fi
                done
                echo #New line
        done

    fi
}

function set_prompt() {
    OPTS=`getopt -o u:h:g:p:a:b: --long user:,host:,group:,pwd:,at:,bracket: -n 'parse-options' -- "$@"`

    if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

    # echo "$OPTS"
    eval set -- "$OPTS"

    BIWHITE='\e[1;97m'
    ORANGE=$(tput setaf 172)

    HOSTCOLOR=$(tput setaf 221)
    USERCOLOR=$(tput setaf 38)
    GROUPCOLOR=$(tput setaf 119)
    PWDCOLOR=$(tput setaf 11)
    ATCOLOR=$BIWHITE
    BRACKETCOLOR=$BIWHITE

    while true; do
      case "$1" in
        -u | --user )       USERCOLOR=$(tput setaf $2); shift 2 ;;
        -h | --host )       HOSTCOLOR=$(tput setaf $2); shift 2 ;;
        -g | --group )      GROUPCOLOR=$(tput setaf $2); shift 2 ;;
        -p | --pwd )        PWDCOLOR=$(tput setaf $2); shift 2 ;;
        -a | --at )         ATCOLOR=$(tput setaf $2); shift 2 ;;
        -b | --bracket )    BRACKETCOLOR=$(tput setaf $2); shift 2 ;;
        -- ) shift; break ;;
        * ) echo "Usage: $0 [-u <color>] [-h <color>] [-a <color>] [-g <color>] [-p <color>] [-b <color>]" 1>&2; exit 1; ;;
      esac
    done

    if [[ `whoami` = "root" ]]; then
        USERCOLOR='\e[48;5;160m'
    fi

    RESET=$(tput sgr0)

    export PS1="\[$BRACKETCOLOR\][ \[$USERCOLOR\]\u\[$RESET\]\[$GROUPCOLOR\]\$(show_group_not_default)\[$ATCOLOR\]@\[$HOSTCOLOR\]\H \[$PWDCOLOR\]\w\[$BRACKETCOLOR\] ]\[$RESET\]\[$BIWHITE\]\$([[ -n \$(git branch 2> /dev/null && parse_svn_branch 2> /dev/null) ]] && echo \" on \")\[$PURPLE\]\$(parse_git_branch && parse_svn_branch)\[$RESET\]\[$BIWHITE\]\$ \[$RESET\]"
    export PS2="\[$ORANGE\]→ \[$RESET\]"
}

# Determine the branch information for this subversion repository. No support
# for svn status, since that needs to hit the remote repository.
function set_svn_branch() {
    hash svn &>/dev/null
    if [ $? -eq 0 ]; then
        if [ -d ".svn" ]; then

            # Capture the output of the "git status" command.
            svn_info="$(svn info | egrep '^URL: ' 2> /dev/null)"

            # Get the name of the branch.
            branch_pattern="^URL: .*/(branches|tags)/([^/]+)"
            trunk_pattern="^URL: .*/trunk(/.*)?$"
            if [[ ${svn_info} =~ $branch_pattern ]]; then
            branch=${BASH_REMATCH[2]}
            elif [[ ${svn_info} =~ $trunk_pattern ]]; then
            branch='trunk'
            fi

            # Set the final branch string.
            BRANCH="(${branch}) "
        else
            BRANCH=""
        fi
    fi
}

function parse_svn_branch() {
    if hash svn &>/dev/null; then
        set_svn_branch
        echo -n "$BRANCH"
    fi
}

# Mimic git diff with color
function svndiff() {
    if hash svn &>/dev/null; then
        if hash colordiff 2>/dev/null; then
            svn diff -x -w -r "$1":"$2" "${@:3}" | colordiff
        else
            svn diff -x -w -r "$1":"$2" "${@:3}"
        fi
    fi
}

function speak_file() {
    FILENAME="$1"
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi
    local FILENAME="${1}"
    if [ ! -f "$FILENAME" ]; then
        echo "File not found"
        return 1
    fi
    if hash espeak 2>/dev/null; then
        cat "$FILENAME" | festival --tts
    elif hash festival 2>/dev/null; then
        espeak -f "$FILENAME"
    else
        echo "please install either espeak or festival"
        exit 1
    fi
}

function fingerprint_cert() {
    local FILENAME="${1}"
    if [ ! -f "$FILENAME" ]; then
        echo "File not found"
        return 1
    fi
    echo "$(openssl x509 -in $FILENAME -noout -fingerprint | sed -e 's/[[:space:]]*$//') $(openssl x509 -in $FILENAME -noout -subject | sed 's/subject= \///g' | sed -e 's/^[[:space:]]*//') $(openssl x509 -in $FILENAME -noout -text | grep DNS | sed -e 's/^[[:space:]]*//')"
}

function doihave() {
    if hash dpkg 2>/dev/null; then
        dpkg --get-selections \
        | grep -v deinstall \
        | awk {' print $1 '} \
        | grep "${@}"
        return 0
    elif hash pacman 2>/dev/null; then
        pacman -Q \
        | awk {' print $1 '} \
        | grep "${@}"
        return 0
    elif hash apt-cyg 2>/dev/null; then
        apt-cyg list \
        | grep "${@}"
        return 0
    fi
    echo "error: not implemented for your operating system"
    return 1
}
