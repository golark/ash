#!/bin/bash
# Bash widget for ash - bind to Ctrl+G

ash_widget() {
    local input="$READLINE_LINE"
    local tmp="$(mktemp)"
    local interrupted=0

    # Check if model needs downloading (will have stderr output)
    local model_path="$HOME/.ash/models/qwen2.5-coder-3b-instruct-q4_k_m.gguf"
    local show_animation=1
    if [[ ! -f "$model_path" ]]; then
        show_animation=0
    fi

    # Save cursor position and clear line
    echo -ne "\r\033[K"

    # Run ash in background
    (ash "$input" > "$tmp" 2>&1) &
    local pid=$!

    # Set up trap for Ctrl+C
    trap 'interrupted=1; kill "$pid" 2>/dev/null' INT

    if (( show_animation )); then
        # Animation frames - bouncing bar (only when no download)
        local bar_frames=("|      " "||     " "|||    " " |||   " "  |||  " "   ||| " "    |||" "     ||" "      |" "     ||" "    |||" "   ||| " "  |||  " " |||   " "|||    " "||     ")
        local i=0
        local num_frames=${#bar_frames[@]}

        while kill -0 "$pid" 2>/dev/null && (( ! interrupted )); do
            local frame="${bar_frames[$((i % num_frames))]}"
            echo -ne "\r$input $frame"
            i=$(( (i + 1) % num_frames ))
            sleep 0.1
        done
        # Clear the animation line
        echo -ne "\r\033[K"
    else
        # No animation during download to avoid conflicts with progress bar
        # Let stderr output show through naturally
        wait "$pid" 2>/dev/null
    fi

    if (( ! show_animation && ! interrupted )); then
        wait "$pid" 2>/dev/null
    fi

    trap - INT

    if (( interrupted )); then
        # Restore original input
        READLINE_LINE="$input"
        READLINE_POINT=${#input}
    else
        # Replace with ash output
        local result="$(<"$tmp")"
        READLINE_LINE="$result"
        READLINE_POINT=${#result}
    fi

    rm -f "$tmp"
}

# Bind Ctrl+G to the widget
bind -x '"\C-g": ash_widget'
