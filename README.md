# cmdgen — zsh command generator

Small helper that turns a natural-language prompt into a single, safe, one-line shell command using an Ollama model. The script prints a spinner to stderr while generating; stdout contains only the extracted command.

## Prerequisites
- Ollama installed and its daemon running (`ollama list` must succeed).
- zsh if you want the interactive widget.
- Make the script executable: `chmod +x cmdgen.sh`

## Install
1. Make executable:
   ```sh
   chmod +x cmdgen.sh
   ```
2. (Optional) Install to your PATH:
   ```sh
   mkdir -p ~/bin
   ln -sf "$(pwd)/cmdgen.sh" ~/bin/cmdgen
   ```
3. If using the zsh widget, update the script path in `.zshrc` (if necessary) and reload zsh:
   ```sh
   source ~/.zshrc
   ```

## Usage

- From the shell:
  ```sh
  cmdgen "list files modified in the last 7 days"
  ```
  stdout will contain a single one-line shell command; a spinner is printed to stderr while the model responds.

- Interactive zsh widget:
  - Type a natural-language prompt directly at your zsh command line.
  - Press Control + g to generate and replace the current buffer with the one-line command.

  (The provided `.zshrc` binds the widget to Control + g; edit the path if you installed the script elsewhere.)

## Configuration
- Override model per invocation:
  ```sh
  CMDGEN_MODEL="gemma3:latest" cmdgen "find large files"
  ```
- Default model is defined in `cmdgen.sh` / `cmdgen.sh-e` (`DEFAULT_MODEL`).

## Safety & Notes
- The prompt requests strict single-line output wrapped in `<CMD>...</CMD>` and extracts only the command. Always review generated commands before running them.
- If you see an Ollama error, start the Ollama daemon and retry.
- If extraction fails, the model output may not match the expected format.

## Files
- cmdgen.sh — main script
- .zshrc — example widget for interactive use

## License
