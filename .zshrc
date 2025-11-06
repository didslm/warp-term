#!/bin/zsh

#rest of your .zshrc

cmdgen-widget() {
  # Run the silent script with the current line buffer
  # *** REPLACE with the absolute path to your script ***
  local new_cmd
  new_cmd=$(~/bin/cmdgen "$BUFFER")

  # Replace the buffer with the new command
  BUFFER=$new_cmd

  # Move the cursor to the end of the line
  zle end-of-line

  # Refresh the prompt
  zle reset-prompt
}

# Register the function as a ZLE widget
zle -N cmdgen-widget

# Bind Control-G to the new widget
bindkey '^G' cmdgen-widget

