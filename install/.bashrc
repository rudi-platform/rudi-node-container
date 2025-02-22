#!/usr/bin/env bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

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

# if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi

#----- Functions -----------------------------------------------------------------------------------
# Execute a mathematical operation expressed as a string
calc() { awk "BEGIN { print $* }"; }

# Gives the actual date in seconds as a string
now_s_str() { date +%Y-%m-%d_%H%M%S; }
export nowS

# Gives the actual date in Ms as an integer number
now_ms_int() { node -e 'console.log(Date.now())'; }
export now_ms_int

TIME_SOURCED=$(now_ms_int)
export TIME_SOURCED

# Calculate the time spent (s, float) between two dates expressed in ms, int
# Arg 1: reference time (ms, int) - defaulted to above ${TIME_SOURCED}
# Arg 2: actual time (ms, int) - defaulted to the result of above now_ms_int function
time_spent_s() {
    if [ $# -lt 2 ]; then now=$(now_ms_int); else now=$2; fi
    if [ $# -lt 1 ]; then ref_time=0${TIME_SOURCED}; else ref_time=$1; fi
    echo "$(calc "(${now}-${ref_time})/1000")"
}
export time_spent_s

# Access a folder like `cd` but creates the folder beforehand if it doesn't exist
ccd() { test -d "$1" || mkdir -p "$1" && cd "$1" || exit; }
export ccd

export LOG_DIR=./logs
logfile_path() {
    mkdir -p logs
    echo "${LOG_DIR}/${1}_$(now_s_str).log"
}
export logfile_path

log_msg() {
    echo
    echo "-----( $(time_spent_s)s )----------[ $* ]"
    echo
}
export log_msg

# log_in_file () { exec > >(tee "$(logfile_path "$1")") 2>&1; }
# export log_in_file

# Gives the name of the most recently modified file in a folder, excluding dot files and subfolders
last_modified() {
    if [ $# -lt 1 ]; then
        folder=.
    else
        folder=$*
    fi
    # find "${folder}" -maxdepth 1 -type f ! -name ".*" -exec stat -f "%m %N" {} + | sort -rn | head -n 1 | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}'
    # find "$folder" -maxdepth 1 -type f ! -name ".*" -printf "%T+ %p\n" | sort -r | head -n 1 | cut -d" " -f2-;
    # ls -ltp "$folder"
    ls -ltp "$folder" |
        grep -v '^[dl]' |
        grep -v '^\.' |
        grep -v '^total.*$' |
        head -1 |
        awk '{printf "%s", $9; for (i=10; i<=NF; i++) printf " %s", $i; print ""}'
}
export last_modified

#----- SSH -----------------------------------------------------------------------------------------
genssh() {
    if [[ $# -lt 2 ]]; then out="./$1"; else out="$2/$1"; fi
    ssh-keygen -t ed25519 -C "$1" -q -N '' -f "$out"
    chmod 400 "$out*"
}
export genssh

#----- NodeJS --------------------------------------------------------------------------------------
export NODE_PATH=$(npm root -g)

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
