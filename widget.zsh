# Example: Insert text at cursor position
zle -N insert-semicolon
insert-semicolon() {
    local input="${LBUFFER}${RBUFFER}"
    #LBUFFER=""
    #RBUFFER=""

    local tmp="$(mktemp)"

    setopt local_options no_monitor no_notify
    (ash "$input" > "$tmp") & local pid=$!

    # Animation frames - bouncing bar
    local bar_frames=("|      " "||     " "|||    " " |||   " "  |||  " "   ||| " "    |||" "     ||" "      |" "     ||" "    |||" "   ||| " "  |||  " " |||   " "|||    " "||     ")
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        BUFFER="$input ${bar_frames[$((i % ${#bar_frames[@]}))]}"
        zle redisplay
        i=$(( (i + 1) % ${#bar_frames[@]} ))
        zle -R && sleep 0.1
    done
    LBUFFER=""
    RBUFFER=""

    RBUFFER="$(<"$tmp")"
    rm -f "$tmp"
}
bindkey '^G' insert-semicolon
