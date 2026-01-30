# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    #alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -l'
alias la='ls -al'
#alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Fetch and install latest runapp script
function getrunapp() {
    curl -o ~/runapp.sh https://raw.githubusercontent.com/jamiekohns/general/refs/heads/main/runapp.sh
    chmod +x ~/runapp.sh

    if [ ! -L /usr/bin/runapp ]; then
        sudo ln -s "$HOME/runapp.sh" /usr/bin/runapp
        echo "Symlink created at /usr/bin/runapp"
    fi
}

# Laravel cache clear function
function artisan-clear() {
    # Check if artisan file exists in current directory
    if [ ! -f "artisan" ]; then
        echo "Error: artisan file not found in current directory"
        return 1
    fi

    # Run Laravel clear commands
    php artisan view:clear && \
    php artisan cache:clear && \
    php artisan route:clear && \
    rm -f storage/framework/sessions/*

    if [ $? -eq 0 ]; then
        echo "✓ All caches cleared successfully"
    else
        echo "✗ An error occurred while clearing caches"
        return 1
    fi
}

export SVN_REPO_URL={{SVN_REPO_URL}}
export SVN_REPO_USERNAME={{SVN_REPO_USERNAME}}

function svn() {
    # Check if the command is 'status' or 'st'
    if [ "$1" = "status" ] || [ "$1" = "st" ]; then
        # Clear Laravel views if we're in a Laravel project
        if [ -d "storage/framework/views" ]; then
            rm -f storage/framework/views/*
            GREEN='\033[0;32m'
            NC='\033[0m' # No color
            echo -e "${GREEN}✓ Cleared Laravel views${NC}"
        fi
    fi

    # svn clone [REPO_NAME]
    # repo MUST have /trunk
    # e.g., svn clone project1 will checkout from SVN_REPO_URL/project1/trunk into ./project1
    if [ "$1" = "clone" ]; then
        # ensure that we are in the projects directory
        cd ~/projects || return

        # Prepend SVN_REPO_URL if not already present
        local repo_path="$2"
        if [[ ! "$repo_path" =~ ^"${SVN_REPO_URL}" ]]; then
            repo_path="${SVN_REPO_URL}${repo_path}/trunk"
        else
            repo_path="$2/trunk"
        fi

        command svn checkout "$repo_path" "$2" --username "${SVN_REPO_USERNAME}"
        return
    fi

    # Run the actual svn command with all arguments
    command svn "$@"
}