function is-valid-shell-command() {
  local cmd_name="$1"
  if [[ -z "$cmd_name" ]]; then
    return 1
  fi
  command -v -- "$cmd_name" >/dev/null 2>&1
}

if [[ -z "${ASH_ENABLED+x}" ]]; then
  ASH_ENABLED=0
fi

function ash-toggle() {
  if [[ "$ASH_ENABLED" -eq 0 ]]; then
    # Check if ash-server is running by sending a client request; if not, start it
    if ! ./dist/ash-client --ping >/dev/null 2>&1; then
      # Start Python server with custom model path if specified
      if [[ -n "$ASH_MODEL_PATH" ]]; then
        nohup python3 ash/server.py --port 8765 --model-path "$ASH_MODEL_PATH" >/dev/null 2>&1 &
      else
        nohup python3 ash/server.py --port 8765 >/dev/null 2>&1 &
      fi
      echo "starting ash mode"
      ash-client --wait
      if [[ $? -ne 0 ]]; then
        echo "❌ ash-server did not start in time. AI mode not enabled."
        return
      fi
    fi
    ASH_ENABLED=1
    echo "ash is now enabled"
  else
    ASH_ENABLED=0
    echo "ash is now disabled"
  fi
  ash-update-prompt
  zle reset-prompt
}

function ash-update-prompt() {
  if [[ "$ASH_ENABLED" -eq 1 ]]; then
    if [[ "$PROMPT" != *"[AI]"* ]]; then
      PROMPT="[AI] $PROMPT"
    fi
  else
    PROMPT="${PROMPT#"[AI] "}"
  fi
}

function ash-process-or-accept-line() {
  if [[ "$ASH_ENABLED" -ne 1 ]]; then
    zle accept-line
    return
  fi

  local current_line="${LBUFFER}${RBUFFER}"
  local cmd_name processed_cmd

  # Trim leading spaces
  current_line="${current_line#"${current_line%%[![:space:]]*}"}"
  # Extract the first word (the command)
  cmd_name="${current_line%% *}"

  # If the command is a valid shell command, accept the line as normal
  if is-valid-shell-command "$cmd_name"; then
    zle accept-line
    return
  fi

  # Otherwise, process through ASH
  processed_cmd=$(ash-client --quiet "$current_line" 2>/dev/null)
  if [[ -n "$processed_cmd" && "$processed_cmd" != "$current_line" ]]; then
    LBUFFER="$processed_cmd"
    RBUFFER=""
    zle reset-prompt
  else
    zle accept-line
  fi
}

# Only define zle widgets and bindings if not already defined
if ! zle -l ash-process-or-accept-line >/dev/null 2>&1; then
  zle -N ash-process-or-accept-line
  bindkey '^M' ash-process-or-accept-line  # Bind Enter to this widget
fi

if ! zle -l ash-toggle >/dev/null 2>&1; then
  zle -N ash-toggle
  bindkey '^G' ash-toggle
fi

ash-update-prompt
