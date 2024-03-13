# Setup fzf
# ---------
if [[ ! "$PATH" == */home/user/tools/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/user/tools/fzf/bin"
fi

# Auto-completion
# ---------------
source "/home/user/tools/fzf/shell/completion.bash"

# Key bindings
# ------------
source "/home/user/tools/fzf/shell/key-bindings.bash"

export FZF_COMPLETION_TRIGGER='\'

# Options to fzf command
export FZF_COMPLETION_OPTS='--border --info=inline'

_fzf_setup_completion path c code
_fzf_setup_completion dir tree

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    note|bookmark|bk)  fzf --preview 'fzf_previewer {}' --preview-window 'up' --bind 'ctrl-/:change-preview-window(hidden|)' "$@" ;;
    *)            fzf --preview 'fzf_previewer {}'         "$@" ;;
  esac
}

# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
  --preview 'fzf_previewer {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# CTRL-/ to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# Print tree structure in the preview window
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

export FZF_DEFAULT_COMMAND='fd --type f'
# export FZF_DEFAULT_OPTS='--preview "fzf_previewer {}" --bind "ctrl-/:change-preview-window(up|hidden|)"'
export FZF_DEFAULT_OPTS='--bind="alt-left:preview-page-up,alt-right:preview-page-down,alt-up:preview-up,alt-down:preview-down"'

_fzf_complete_note() {
  _fzf_complete --multi --reverse --prompt="note> " -- "$@" < <(NO_COLOR_OUTPUT=true note | tail -n +2)
}
_fzf_complete_note_post() {
  awk '{print $1}' | sed -e 's/\[\|\]//'g
}
[ -n "$BASH" ] && complete -F _fzf_complete_note -o default -o bashdefault note

_fzf_complete_bookmark() {
  _fzf_complete --multi --reverse --prompt="bookmark> " -- "$@" < <(NO_COLOR_OUTPUT=true bookmark | tail -n +2)
}
_fzf_complete_bookmark_post() {
  awk '{print $1}' | sed -e 's/\[\|\]//'g
}
[ -n "$BASH" ] && complete -F _fzf_complete_bookmark -o default -o bashdefault bookmark
