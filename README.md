# warp-term — AI-powered shell tools

A collection of AI-powered shell utilities using Ollama models.

## Tools

### cmdgen — zsh command generator
Small helper that turns a natural-language prompt into a single, safe, one-line shell command using an Ollama model. The script prints a spinner to stderr while generating; stdout contains only the extracted command.

### agentic — autonomous task executor
Intelligent agent that breaks down complex tasks into multiple steps, plans the execution, and runs commands sequentially with safety confirmations. Uses the same Ollama model as cmdgen for consistent behavior.

## Prerequisites
- Ollama installed and its daemon running (`ollama list` must succeed).
- zsh if you want the interactive widgets.
- Scripts must be executable (see Install section).

## Install
1. Make scripts executable:
   ```sh
   chmod +x cmdgen.sh agentic.sh
   ```
2. (Optional) Install to your PATH:
   ```sh
   mkdir -p ~/bin
   ln -sf "$(pwd)/cmdgen.sh" ~/bin/cmdgen
   ln -sf "$(pwd)/agentic.sh" ~/bin/agentic
   ```
3. If using the zsh widgets, update the script paths in the widget files (if necessary) and source them in your ~/.zshrc:
   ```sh
   # Add to your ~/.zshrc file
   # For cmdgen widget (Control+G)
   source /path/to/warp-term/.zshrc
   # For agentic widget (Control+A)
   source /path/to/warp-term/.zshrc-agentic
   ```

## Usage

### cmdgen (single command generation)

- From the shell:
  ```sh
  cmdgen "list files modified in the last 7 days"
  ```
  stdout will contain a single one-line shell command; a spinner is printed to stderr while the model responds.

- Interactive zsh widget:
  - Type a natural-language prompt directly at your zsh command line.
  - Press Control + g to generate and replace the current buffer with the one-line command.

  (The provided `.zshrc` binds the widget to Control + g; edit the path if you installed the script elsewhere.)

### agentic (multi-step task execution)

- From the shell (interactive mode):
  ```sh
  agentic "find all log files larger than 10MB and show their sizes"
  ```
  The agent will:
  1. Break down the task into steps
  2. Generate a command for each step
  3. Ask for confirmation before executing each command
  4. Show output from each step
  5. Use context from previous steps to inform next commands

- Non-interactive mode (auto-execute):
  ```sh
  AGENTIC_INTERACTIVE=false agentic "compress all CSV files in current directory"
  ```

- Interactive zsh widget:
  - Type a complex natural-language task at your zsh command line.
  - Press Control + a to launch the agentic task executor.

  (The provided `.zshrc-agentic` binds the widget to Control + a.)

## Configuration
- Override model per invocation (works for both cmdgen and agentic):
  ```sh
  CMDGEN_MODEL="gemma3:latest" cmdgen "find large files"
  CMDGEN_MODEL="gemma3:latest" agentic "analyze system performance"
  ```
- Default model is defined in `cmdgen.sh` and `agentic.sh` (`DEFAULT_MODEL`).
- Control agentic interactivity:
  ```sh
  AGENTIC_INTERACTIVE=false agentic "your task"  # Auto-execute without confirmation
  AGENTIC_INTERACTIVE=true agentic "your task"   # Ask before each step (default)
  ```

## Safety & Notes
- **cmdgen**: The prompt requests strict single-line output wrapped in `<CMD>...</CMD>` and extracts only the command. Always review generated commands before running them.
- **agentic**: By default, asks for confirmation before executing each step. In non-interactive mode, commands execute automatically—use with caution.
- Both tools prioritize safety and will request conservative commands.
- If you see an Ollama error, start the Ollama daemon and retry.
- If extraction fails, the model output may not match the expected format.
- The agentic tool maintains context between steps, allowing later commands to reference results from earlier ones.

## Files
- `cmdgen.sh` — single command generator
- `agentic.sh` — autonomous multi-step task executor
- `.zshrc` — zsh widget for cmdgen (Control+g)
- `.zshrc-agentic` — zsh widget for agentic (Control+a)

## Examples

### cmdgen examples
```sh
# Simple file operations
cmdgen "count lines in all Python files"
cmdgen "find files larger than 100MB"
cmdgen "show disk usage sorted by size"
```

### agentic examples
```sh
# Complex multi-step tasks
agentic "find all TODO comments in Python files and save to a report"
agentic "backup all markdown files to a zip archive with timestamp"
agentic "find the 5 largest files and show their detailed information"

# System analysis
agentic "check system resources and identify top memory consumers"
agentic "analyze recent logs for errors and summarize findings"
```

## License
