#!/bin/bash

set -euo pipefail

DEFAULT_MODEL="gemma3:latest" #this model turns out to be the fastest for me.
MODEL="${CMDGEN_MODEL:-$DEFAULT_MODEL}"
OSTYPE="macOS"

if ! ollama list > /dev/null 2>&1; then
  echo "Error: cmdgen_silent: Ollama server is not running." >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <your natural language query>" >&2
  exit 1
fi
USER_QUERY="$*"

PROMPT=$(cat <<'EOM'
You are an expert '$OSTYPE' zsh command generator.
You must output a single, one-line shell command.
Output format:
<CMD>the single exact shell command</CMD>
Rules:
- Output ONLY the <CMD>...</CMD> block. No other text, no markdown, no explanations.
- The command must be a single line.
- Prioritize safety. Be cautious with destructive commands (rm, dd, >)
- Use common POSIX tools.

---
User request:
EOM
)

spinner() {
  local chars="⣾⣽⣻⢿⡿⣟⣯⣷" # Braille spinner characters
  local i=0
  while true; do
    # Print to stderr
    echo -ne "\r[${chars:i%${#chars}:1}] Generating command..." >&2
    sleep 0.05
    ((i++))
  done
}

spinner &
SPINNER_PID=$!

trap "kill $SPINNER_PID 2>/dev/null; echo -ne '\r\033[K' >&2" EXIT

GENERATED_CMD=$( {
  echo "$PROMPT"
  echo "$USER_QUERY"
} | ollama run "$MODEL" 2>/dev/null | sed -n 's/.*<CMD>\(.*\)<\/CMD>.*/\1/p' )

if [[ -z "$GENERATED_CMD" ]]; then
  # Note: The trap will fire AFTER this, clearing the spinner
  echo "Error: cmdgen_silent: AI did not return a valid command." >&2
  echo "Model '$MODEL' may not be available or did not follow the prompt." >&2
  exit 1 # This exit triggers the trapgg
fi

echo "$GENERATED_CMD"

