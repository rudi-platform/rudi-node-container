#!/usr/bin/env bash
# podman-context
set -euo pipefail

DEV="podman-machine-default"
BUILD="build"

get_default() {
        podman system connection list --format json 2>/dev/null |
                jq -r '.[] | select(.Default==true) | .Name'
}

is_running() {
        local m="$1"

        podman machine list --format json 2>/dev/null |
                jq -e --arg m "$m" '.[] | select(.Name==$m and .Running==true)' >/dev/null
}

ensure_running() {
        local m="$1"

        if is_running "$m"; then
                echo "Machine '$m' already running"
                return 0
    fi

        echo "Launching machine: '$m'"
        podman machine start "$m"
}

switch_connection() {
        local m="$1"

        echo "Switching default connection → '$m'"
        podman system connection default "$m"
}

wait_for_stable_state() {
        local m

        while true; do
                if podman machine list --format json | jq -e '
            all(.[]; (.Starting == false))
        ' >/dev/null; then
                        break
        fi

                echo "Waiting for Podman machine state to stabilize..."
                sleep 1
    done
}

switch_to() {
        local target="$1"
        local current
        current="$(get_default || true)"

        echo "Current: '${current:-none}'"
        echo "Target:  '$target'"

        if [[ "$current" == "$target" ]]; then
                echo "Already using '$target'"
                return 0
    fi

        # CRITICAL: wait for VM subsystem to settle
        wait_for_stable_state

        # stop current BEFORE starting new one (important on AppleHV)
        if [[ "$current" != "$target" ]]; then
                echo "Stopping current machine (if needed): $current"
                podman machine stop "$current" 2>/dev/null || true
    fi

        # ensure clean slate
        wait_for_stable_state

        echo "Starting target machine: $target"
        podman machine start "$target" || true

        echo "Switching connection..."
        podman system connection default "$target"

        echo "Now active: $(get_default)"
}

case "${1:-}" in
    dev | default)
        switch_to "$DEV"
        ;;
    build)
        switch_to "$BUILD"
        ;;
    status)
        echo "Default: '$(get_default)'"
        podman machine list
        ;;
    *)
        echo "Usage: podman-context {dev|build|status}"
        exit 1
        ;;
esac
echo
echo "podman machine list"
podman machine list
