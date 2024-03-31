# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# enable alias expansion
shopt -s expand_aliases

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

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

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
# alias l='ls -CF'
alias l="ls -lah"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi


#----- Functions -----------------------------------------------------------------------------------
# Execute a mathematical operation expressed as a string
calc () { awk "BEGIN { print "$*" }"; }

# Gives the actual date in seconds as a string
now_s_str () { date +%Y-%m-%d_%H%M%S; }
export nowS

# Gives the actual date in Ms as an integer number
now_ms_int () { node -e 'console.log(Date.now())'; }
export now_ms_int

TIME_SOURCED=$(now_ms_int)
export TIME_SOURCED

# Calculate the time spent (s, float) between two dates expressed in ms, int
# Arg 1: reference time (ms, int) - defaulted to above ${TIME_SOURCED}
# Arg 2: actual time (ms, int) - defaulted to the result of above now_ms_int function
time_spent_s () { 
    if [ $# -lt 2 ]; then 
        now=`now_ms_int`; 
    else
        now=$2
    fi
    if [ $# -lt 1 ]; then 
        ref_time=0${TIME_SOURCED}; 
    else
        ref_time=$1
    fi
    echo "$( calc "(${now}-${ref_time})/1000" )"; 
}
export time_spent_s

# Access a folder like `cd` but creates the folder beforehand if it doesn't exist
ccd () { test -d "$1" || mkdir -p "$1" && cd "$1"; }
export ccd 

logfile_path () { mkdir -p logs; echo "logs/${1}_$(now_s_str).log"; }
export logfile_path

log_msg () { echo; echo "-----( $(time_spent_s)s )----------[ $@ ]"; echo; }
export log_msg 

log_in_file () { exec > >(tee `logfile_path "$1"`) 2>&1; }
export log_in_file

# Gives the name of the most recently modified file in a folder, excluding dot files and subfolders 
last_modified () {
    if [ $# -lt 1 ]; then 
        folder=.
    else
        folder=$*
    fi
    # find "${folder}" -maxdepth 1 -type f ! -name ".*" -exec stat -f "%m %N" {} + | sort -rn | head -n 1 | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}'
    # find "$folder" -maxdepth 1 -type f ! -name ".*" -printf "%T+ %p\n" | sort -r | head -n 1 | cut -d" " -f2-; 
    # ls -ltp "$folder"
    ls -ltp "$folder" | grep -v '^[dl]' | grep -v '^\.' | grep -v '^total.*$' | head -1 | awk '{for (i=9; i<=NF; i++) printf $i " "; print ""}'
}
export last_modified

#----- SIGTERM -------------------------------------------------------------------------------------

# Function to handle SIGTERM
cleanup() {
  echo "Signal received, shutting down..."
  # Use 'kill 0' to terminate all processes in the current process group
  kill 0
}
export cleanup

# Trap SIGTERM and call the cleanup function
trap 'cleanup' SIGTERM
