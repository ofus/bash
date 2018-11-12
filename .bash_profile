export ROOT=/data/data/com.termux/files

# Add `~/bin` to the `$PATH`
PATH="$HOME/bin:$PATH"

# TERM=xterm-256color
# if [[ ! $TERM == *256color* ]]; then
#     if [ ! "$TERM" == "gnome-terminal" ] && [ ! "$TERM" == "xfce4-terminal" ]; then
#         if [ -n "$TMUX" ]; then
#             TERM=tmux-256color
#         elif [ -n "$STY" ]; then
#             TERM=screen-256color
#         else
#             TERM=xterm-256color
#         fi
#     fi
# fi

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
for file in ~/.{path,bash_functions,exports,bash_aliases,extra}; do
    [ -r "$file" ] && source "$file"
done
unset file

set_prompt

# After each command, append to the history file and reread it
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# * ~/.extra can be used for other settings you don’t want to commit.
[  -r "$HOME/.extra" ] && source "$HOME/.extra"

# Enable some Bash 4 features when possible:
for option in histappend checkwinsize autocd globstar direxpand; do
    shopt -s "$option" 2> /dev/null
done

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
#[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
#complete -W "NSGlobalDomain" defaults

# enable color support of ls and also add handy bash_aliases
if [ -x $ROOT/usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Check for interactive bash and that we haven't already been sourced.
[ -z "$BASH_VERSION" -o -z "$PS1" -o -n "$BASH_COMPLETION" ] && return

# Check for recent enough version of bash.
bash=${BASH_VERSION%.*}; bmajor=${bash%.*}; bminor=${bash#*.}
if [ $bmajor -gt 3 ] || [ $bmajor -eq 3 -a $bminor -ge 2 ]; then
    if ! shopt -oq posix; then
        if [ -f /data/data/com.termux/files/usr/share/bash-completion/bash_completion ]; then
            . /data/data/com.termux/files/usr/share/bash-completion/bash_completion
        elif [ -f $ROOT/usr/local/share/bash-completion/bash_completion ]; then
            . $ROOT/usr/local/share/bash-completion/bash_completion
        elif [ -f $ROOT/usr/share/bash-completion/bash_completion ]; then
            . $ROOT/usr/share/bash-completion/bash_completion
        elif [ -f ~/usr/share/bash-completion/bash_completion ]; then
            . ~/usr/share/bash-completion/bash_completion
        elif [ -f $ROOT/etc/bash_completion ]; then
            . $ROOT/etc/bash_completion
        fi
    fi
fi
unset bash bmajor bminor
[ -r "~/.bash_completion" ] && source "~/.bash_completion"
