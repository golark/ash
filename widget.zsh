# Example: Insert text at cursor position
zle -N insert-semicolon
insert-semicolon() {
    local input="${LBUFFER}${RBUFFER}"
    local tmp="$(mktemp)"
    local interrupted=0

    setopt local_options no_monitor no_notify
    (ash "$input" > "$tmp") & local pid=$!
    trap 'interrupted=1; kill "$pid" 2>/dev/null' INT

    # Animation frames - bouncing bar
    local bar_frames=("|      " "||     " "|||    " " |||   " "  |||  " "   ||| " "    |||" "     ||" "      |" "     ||" "    |||" "   ||| " "  |||  " " |||   " "|||    " "||     ")
    local i=0
    while kill -0 "$pid" 2>/dev/null && (( ! interrupted )); do
        BUFFER="$input ${bar_frames[$((i % ${#bar_frames[@]}))]}"
        zle redisplay
        i=$(( (i + 1) % ${#bar_frames[@]} ))
        zle -R && sleep 0.1
    done
    wait "$pid" 2>/dev/null

    trap - INT

    if (( interrupted )); then
        LBUFFER="$input"
        RBUFFER=""
    else
        LBUFFER=""
        RBUFFER="$(<"$tmp")"
    fi
    rm -f "$tmp"
}
bindkey '^G' insert-semicolon
