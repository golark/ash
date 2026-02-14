# Example: Insert text at cursor position
zle -N insert-semicolon
insert-semicolon() {
    local input="${LBUFFER}${RBUFFER}"
    local tmp="$(mktemp)"
    local interrupted=0

    # Check if model needs downloading (will have stderr output)
    local model_path="$HOME/.ash/models/qwen2.5-coder-3b-instruct-q4_k_m.gguf"
    local show_animation=1
    if [[ ! -f "$model_path" ]]; then
        show_animation=0
    fi

    setopt local_options no_monitor no_notify
    (ash "$input" > "$tmp") & local pid=$!
    trap 'interrupted=1; kill "$pid" 2>/dev/null' INT

    if (( show_animation )); then
        # Animation frames - bouncing bar (only when no download)
        local bar_frames=("|      " "||     " "|||    " " |||   " "  |||  " "   ||| " "    |||" "     ||" "      |" "     ||" "    |||" "   ||| " "  |||  " " |||   " "|||    " "||     ")
        local i=0
        while kill -0 "$pid" 2>/dev/null && (( ! interrupted )); do
            BUFFER="$input ${bar_frames[$((i % ${#bar_frames[@]}))]}"
            zle redisplay
            i=$(( (i + 1) % ${#bar_frames[@]} ))
            zle -R && sleep 0.1
        done
    else
        # No animation during download to avoid conflicts with progress bar
        while kill -0 "$pid" 2>/dev/null && (( ! interrupted )); do
            sleep 0.1
        done
    fi
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
