# Example: Insert text at cursor position
zle -N insert-semicolon
insert-semicolon() {
    local input="${LBUFFER}${RBUFFER}"
    LBUFFER=""
    RBUFFER=""
    RBUFFER="$(./build/ash "$input")"
}
bindkey '^G' insert-semicolon