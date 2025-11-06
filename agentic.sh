#!/bin/bash

set -euo pipefail

DEFAULT_MODEL="gemma3:latest"
MODEL="${CMDGEN_MODEL:-$DEFAULT_MODEL}"
OSTYPE="macOS"
MAX_ITERATIONS=5
MAX_CONTEXT_LINES=15  # Keep context from last ~3 steps (5 lines per step)

if ! ollama list > /dev/null 2>&1; then
  echo "Error: agentic: Ollama server is not running." >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <your natural language task>" >&2
  echo "Example: $(basename "$0") find all log files larger than 10MB and show their sizes" >&2
  exit 1
fi

USER_TASK="$*"
INTERACTIVE="${AGENTIC_INTERACTIVE:-true}"

# Function to display a spinner
spinner() {
  local chars="⣾⣽⣻⢿⡿⣟⣯⣷"
  local i=0
  while true; do
    echo -ne "\r[${chars:i%${#chars}:1}] $1..." >&2
    sleep 0.05
    ((i++))
  done
}

# Function to ask the agent to plan the task
plan_task() {
  local task="$1"
  
  local prompt=$(cat <<EOM
You are an expert task planner for $OSTYPE shell commands.
Break down the user's task into a numbered list of simple, atomic steps.
Each step should be executable as a single shell command.
Output format:
<PLAN>
1. [brief description of step 1]
2. [brief description of step 2]
...
</PLAN>
Rules:
- Output ONLY the <PLAN>...</PLAN> block. No other text.
- Each step should be a brief description that can be converted to a command.
- Maximum 10 steps.
- Order steps logically.
- Prioritize safety.

---
User task:
EOM
)
  
  spinner "Planning task" &
  local spinner_pid=$!
  trap "kill $spinner_pid 2>/dev/null; echo -ne '\r\033[K' >&2" RETURN
  
  local plan=$( {
    echo "$prompt"
    echo "$task"
  } | ollama run "$MODEL" 2>/dev/null | sed -n '/<PLAN>/,/<\/PLAN>/p' | sed '/<PLAN>/d;/<\/PLAN>/d' )
  
  kill $spinner_pid 2>/dev/null
  echo -ne '\r\033[K' >&2
  
  if [[ -z "$plan" ]]; then
    echo "Error: Failed to generate plan." >&2
    return 1
  fi
  
  echo "$plan"
}

# Function to convert a step description to a command
step_to_command() {
  local step="$1"
  local context="$2"
  
  local prompt=$(cat <<EOM
You are an expert $OSTYPE zsh command generator.
Convert the given step description into a single shell command.
Output format:
<CMD>the single exact shell command</CMD>
Rules:
- Output ONLY the <CMD>...</CMD> block. No other text.
- The command must be a single line.
- Prioritize safety.
- Use common POSIX tools.

Context from previous steps:
EOM
)
  
  local generated_cmd=$( {
    echo "$prompt"
    echo "$context"
    echo ""
    echo "Step to convert:"
    echo "$step"
  } | ollama run "$MODEL" 2>/dev/null | sed -n 's/.*<CMD>\(.*\)<\/CMD>.*/\1/p' )
  
  if [[ -z "$generated_cmd" ]]; then
    echo "Error: Failed to generate command for step." >&2
    return 1
  fi
  
  echo "$generated_cmd"
}

# Main execution
echo "=== Agentic Task Execution ===" >&2
echo "Task: $USER_TASK" >&2
echo "" >&2

# Phase 1: Planning
echo "Phase 1: Planning..." >&2
plan=$(plan_task "$USER_TASK")

if [[ -z "$plan" ]]; then
  echo "Failed to create plan. Exiting." >&2
  exit 1
fi

echo "Plan:" >&2
echo "$plan" | sed 's/^/  /' >&2
echo "" >&2

# Phase 2: Execution
echo "Phase 2: Execution" >&2
context=""
iteration=0

while IFS= read -r step; do
  if [[ -z "$step" ]]; then
    continue
  fi
  
  ((iteration++))
  if [[ $iteration -gt $MAX_ITERATIONS ]]; then
    echo "Maximum iterations reached. Stopping." >&2
    break
  fi
  
  echo "" >&2
  echo "[$iteration] Step: $step" >&2
  
  spinner "Generating command" &
  spinner_pid=$!
  trap "kill $spinner_pid 2>/dev/null; echo -ne '\r\033[K' >&2" EXIT
  
  cmd=$(step_to_command "$step" "$context")
  
  kill $spinner_pid 2>/dev/null
  echo -ne '\r\033[K' >&2
  
  if [[ -z "$cmd" ]]; then
    echo "  ⚠ Failed to generate command. Skipping." >&2
    continue
  fi
  
  echo "  Command: $cmd" >&2
  
  if [[ "$INTERACTIVE" == "true" ]]; then
    echo -n "  Execute? [Y/n/q]: " >&2
    read -r response
    case "$response" in
      [Qq]*)
        echo "  Aborted by user." >&2
        exit 0
        ;;
      [Nn]*)
        echo "  Skipped." >&2
        continue
        ;;
    esac
  fi
  
  echo "  Executing..." >&2
  output=$(eval "$cmd" 2>&1 || true)
  
  if [[ -n "$output" ]]; then
    echo "  Output:" >&2
    echo "$output" | head -20 | sed 's/^/    /' >&2
    if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
      echo "    ... (truncated)" >&2
    fi
  fi
  
  # Update context with step and output (keep context limited)
  local step_context="Step: $step
Command: $cmd
Output: $(echo "$output" | head -5)"
  
  # Keep context from last 3 steps to avoid command line length issues
  context=$(echo "$context" | tail -$MAX_CONTEXT_LINES)
  context="$context
$step_context"
  
done <<< "$plan"

echo "" >&2
echo "=== Task Complete ===" >&2
