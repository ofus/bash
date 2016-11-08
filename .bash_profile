# Add `~/bin` to the `$PATH`
PATH="$HOME/bin:$PATH"
TERM=xterm-256color
# if [ "$COLORTERM" == "gnome-terminal" ] || [ "$COLORTERM" == "xfce4-terminal" ]
# then
    # TERM=xterm-256color
    # elif [ "$COLORTERM" == "rxvt-xpm" ]
    # then
        # TERM=rxvt-256color
# fi

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
for file in $HOME/.{path,bash_functions,exports,bash_aliases}; do
	[ -r "$file" ] && source "$file"
done
unset file

set_prompt

# * $HOME/.extra can be used for other settings you don’t want to commit.
[  -r "$HOME/.extra" ] && source "$HOME/.extra"

# Enable some Bash 4 features when possible:
for option in histappend checkwinsize autocd globstar; do
	shopt -s "$option" 2> /dev/null
done

# Flush Bash_history After Each Command (useful for tmux, screen, etc)
#export PROMPT_COMMAND='history -a'
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# Enable some Bash 4 features when possible:
# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
#[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh
# Flush Bash_history After Each Command (useful for tmux, screen, etc)
#export PROMPT_COMMAND='history -a'
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
#complete -W "NSGlobalDomain" defaults

# enable color support of ls and also add handy bash_aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Check for interactive bash and that we haven't already been sourced.
[ -z "$BASH_VERSION" -o -z "$PS1" -o -n "$BASH_COMPLETION" ] && return

# Check for recent enough version of bash.
bash=${BASH_VERSION%.*}; bmajor=${bash%.*}; bminor=${bash#*.}
if [ $bmajor -gt 3 ] || [ $bmajor -eq 3 -a $bminor -ge 2 ]; then
	if ! shopt -oq posix; then
	    if shopt -q progcomp && [ -r /usr/local/Cellar/bash-completion/1.3/etc/bash_completion ]; then
	        . /usr/local/Cellar/bash-completion/1.3/etc/bash_completion
		elif [ -f /usr/local/share/bash-completion/bash_completion ]; then
	        . /usr/local/share/bash-completion/bash_completion
	    elif [ -f /usr/share/bash-completion/bash_completion ]; then
	        . /usr/share/bash-completion/bash_completion
	    elif [ -f /etc/bash_completion ]; then
	        . /etc/bash_completion
	    fi
	fi
	#[ -r "~/.bash_completion" ] && source "~/.bash_completion"
fi
unset bash bmajor bminor
[ -r "~/.bash_completion" ] && source "~/.bash_completion"
