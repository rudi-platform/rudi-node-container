test -r /etc/timezone && TZ=$(cat /etc/timezone)
alias ll='ls -alF'
umask 0027

error() {
    echo "error:  $@" >&2
    exit 1
}

# Gives the actual date in seconds as a string
now_s_str() { date +%Y-%m-%d_%H%M%S; }

# Gives the actual date in Ms as an integer number
now_ms_int() { date +%s.%N; }

TIME_SOURCED=$(now_ms_int)
time_spent_s() {
    [ $# -ge 2 ] && local now=$2 || local now=$(now_ms_int)
    [ $# -ge 1 ] && local start=$1 || local start=${TIME_SOURCED}
    echo "scale=2; $now - $start" | bc
}

log_msg() { printf -- "-----( %ss )----------[ %s ]\n" "$(time_spent_s)" "$*" >&2; }
