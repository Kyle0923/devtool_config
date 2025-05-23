# fzf customization

export FZF_COMPLETION_TRIGGER='\'

# Options to fzf command
export FZF_COMPLETION_OPTS='--border --info=inline'

_fzf_setup_completion path code
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
        note|bookmark|bk)  fzf --preview 'fzf_previewer {}' --preview-window 'up' --bind 'ctrl-/:toggle-preview' "$@" ;;
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
export FZF_DEFAULT_OPTS='--bind="alt-left:beginning-of-line,alt-right:end-of-line,alt-up:preview-up,alt-down:preview-down"
                         --bind="ctrl-d:clear-query"'

########################################################################
_fzf_complete_note() {
    _fzf_complete --ansi --bind 'change:first' --reverse --prompt="note> " -- "$@" < <(note --list | tail -n +2)
}
_fzf_complete_note_post() {
    awk '{print $1}' | sed -e 's/\[\|\]//g'
}
[ -n "$BASH" ] && complete -F _fzf_complete_note -o default -o bashdefault note

########################################################################
_fzf_complete_bookmark() {
    _fzf_complete --ansi --bind 'change:first' --reverse --prompt="bookmark> " -- "$@" < <(bookmark --list | tail -n +2)
}
_fzf_complete_bookmark_post() {
    awk '{print $1}' | sed -e 's/\[\|\]//g'
}
[ -n "$BASH" ] && complete -F _fzf_complete_bookmark -o default -o bashdefault bookmark bk

########################################################################
# auto complete for cd
_fzf_complete_c() {
    local TRIM_LS_SYMBOL="sed -E -e 's/[*=>@|]\$//'"
    local POP_LAST_DIR="sed -E -e 's+\/.*\/$+\/+'"
    # if is dir, enter, otherwise accept current file
    local ENTER_DIR="[[ -d \$(echo \$FZF_PROMPT{}) ]] &&
            echo \"change-prompt(\$(echo \$FZF_PROMPT{}))+reload(ls -a -F \$FZF_PROMPT{} | tail -n +3)+clear-query\" ||
            echo \"become(echo \$FZF_PROMPT{} | $TRIM_LS_SYMBOL)\""
    _fzf_complete \
    --no-multi --reverse --preview-window='right,50%,border-left' \
    --ansi --sort \
    --height="80%" \
    --color hl:underline,hl+:underline \
    --border-label-pos=2 \
    --border-label "`pwd`" \
    --prompt="`pwd | sed -E -e 's+^\/\$++'`/" \
    --header 'Alt-Enter: accept path; CTRL-W: go up; Alt-A: show all files; Alt-D: show all dir; Alt-Q: restore to default' \
    --preview "echo \$FZF_PROMPT{} | $TRIM_LS_SYMBOL | xargs fzf_previewer" \
    \
    --bind "start:reload(ls --color=always -a -F . | tail -n +3)" \
    --bind 'change:first' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' \
    --bind "enter:transform:$ENTER_DIR" \
    --bind "tab:transform:$ENTER_DIR" \
    --bind "ctrl-d:clear-query" \
    --bind "left:transform:[[ -z {q} && \$(echo \$FZF_PROMPT{}) != '/' ]] &&
            echo \"change-prompt(\$(dirname \$FZF_PROMPT | sed -E -e 's+^\/\$++')/)+reload(ls -a -F \$(dirname \$FZF_PROMPT) | tail -n +3)+clear-query\" ||
            echo backward-char" \
    --bind "right:transform:[[ -z {q} && -d \$(echo \$FZF_PROMPT{}) ]] &&
            echo \"change-prompt(\$(echo \$FZF_PROMPT{}))+reload(ls -a -F \$FZF_PROMPT{} | tail -n +3)+clear-query\" ||
            echo forward-char" \
    --bind "ctrl-w:transform:[[ \$(echo \$FZF_PROMPT{}) != '/' ]] &&
            echo \"change-prompt(\$(dirname \$FZF_PROMPT | sed -E -e 's+^\/\$++')/)+reload(ls -a -F \$(dirname \$FZF_PROMPT) | tail -n +3)+clear-query\"" \
    --bind "alt-a:reload(cd \$FZF_PROMPT && fd -HI | sed -e 's,/$,,' | xargs ls --color=always -F -d)" \
    --bind "alt-d:reload(cd \$FZF_PROMPT && fd -HI --type d | sed -e 's,/$,,' | xargs ls --color=always -F -d)" \
    --bind "alt-q:reload(ls --color=always -F -a \$FZF_PROMPT | tail -n +3)" \
    --bind "alt-enter:transform:echo \"become(echo \$FZF_PROMPT)\"" \
    --bind "alt-left:beginning-of-line,alt-right:end-of-line" \
    --bind "alt-up:preview-up,alt-down:preview-down" \
    -- "$@" < <(echo)
}
[ -n "$BASH" ] && complete -F _fzf_complete_c -o default -o bashdefault c

fzf_interactive_cd() {
    local TRIM_LS_SYMBOL="sed -E -e 's/[*=>@|]\$//'"
    local POP_LAST_DIR="sed -E -e 's+\/.*\/$+\/+'"
    # if is dir, enter, otherwise accept current file
    local ENTER_DIR="[[ -d \$(echo \$FZF_PROMPT{}) ]] &&
            echo \"change-prompt(\$(echo \$FZF_PROMPT{}))+reload(ls -a -F \$FZF_PROMPT{} | tail -n +3)+clear-query\" ||
            echo \"become(echo \$FZF_PROMPT{} | $TRIM_LS_SYMBOL)\""
    local INITIAL_QUERY="${*:-}"
    : | fzf \
    --no-multi --reverse --preview-window='right,50%,border-left' \
    --query "$INITIAL_QUERY" \
    --select-1 \
    --ansi --sort \
    --height="80%" \
    --color hl:underline,hl+:underline \
    --border-label-pos=2 \
    --border-label "`pwd`" \
    --prompt="`pwd | sed -E -e 's+^\/\$++'`/" \
    --header 'Alt-Enter: accept path; CTRL-W: go up; Alt-A: show all files; Alt-D: show all dir; Alt-Q: restore to default' \
    --preview "echo \$FZF_PROMPT{} | $TRIM_LS_SYMBOL | xargs fzf_previewer" \
    --bind "start:reload(ls --color=always -a -F . | tail -n +3)" \
    --bind 'change:first' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' \
    --bind "enter:transform:$ENTER_DIR" \
    --bind "tab:transform:$ENTER_DIR" \
    --bind "ctrl-d:clear-query" \
    --bind "left:transform:[[ -z {q} && \$(echo \$FZF_PROMPT{}) != '/' ]] &&
            echo \"change-prompt(\$(dirname \$FZF_PROMPT | sed -E -e 's+^\/\$++')/)+reload(ls -a -F \$(dirname \$FZF_PROMPT) | tail -n +3)+clear-query\" ||
            echo backward-char" \
    --bind "right:transform:[[ -z {q} && -d \$(echo \$FZF_PROMPT{}) ]] &&
            echo \"change-prompt(\$(echo \$FZF_PROMPT{}))+reload(ls -a -F \$FZF_PROMPT{} | tail -n +3)+clear-query\" ||
            echo forward-char" \
    --bind "ctrl-w:transform:[[ \$(echo \$FZF_PROMPT{}) != '/' ]] &&
            echo \"change-prompt(\$(dirname \$FZF_PROMPT | sed -E -e 's+^\/\$++')/)+reload(ls -a -F \$(dirname \$FZF_PROMPT) | tail -n +3)+clear-query\"" \
    --bind "alt-a:reload(cd \$FZF_PROMPT && fd -HI | sed -e 's,/$,,' | xargs ls --color=always -F -d)" \
    --bind "alt-d:reload(cd \$FZF_PROMPT && fd -HI --type d | sed -e 's,/$,,' | xargs ls --color=always -F -d)" \
    --bind "alt-q:reload(ls --color=always -F -a \$FZF_PROMPT | tail -n +3)" \
    --bind "alt-enter:transform:echo \"become(echo \$FZF_PROMPT)\"" \
    --bind "alt-left:beginning-of-line,alt-right:end-of-line" \
    --bind "alt-up:preview-up,alt-down:preview-down" \


}

########################################################################
# auto completion for git checkout, adapted from https://github.com/junegunn/fzf-git.sh
########################################################################

# auto complete for git checkout <commit>
_fzf_complete_gcoc() {
    git_log_opt="--date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --color=always"
    current_branch=`parse_git_branch | sed -E -e 's/\(//' -e 's/\)//' -e 's/^\s*//'`
    _fzf_complete --no-multi --reverse --preview-window='right,50%,border-left' --prompt="current branch> " \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' \
    --ansi --no-sort \
    --bind 'change:first' \
    --header 'Alt-A: toggle all commits / current branch commits' \
    --border-label-pos=2 \
    --border-label "💡 Commits on $current_branch" \
    --color hl:underline,hl+:underline \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | head -n 1 | xargs git show --color=always' \
    --bind "alt-a:transform: [[ \$FZF_PROMPT == 'current branch> ' ]] &&
                        echo \"change-border-label(💡 Commits on all branches)+change-prompt(all commits> )+reload:(git log --all $git_log_opt) \" ||
                        echo \"change-border-label(💡 Commits on $current_branch)+change-prompt(current branch> )+reload:(git log $git_log_opt) \" " \
    --bind "start:reload(git log $git_log_opt)" \
    -- "$@" < <(echo)
}

_fzf_complete_gcoc_post() {
        awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'
}
[ -n "$BASH" ] && complete -F _fzf_complete_gcoc -o default -o bashdefault gcoc

########################################################################
# auto complete for git checkout <branch>
_fzf_complete_gcob() {
    git_branch_opt="--sort=-committerdate --sort=-HEAD --format=\$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=always | column -ts\$'\t'"
    _fzf_complete --no-multi --reverse --preview-window='right,50%,border-left' --prompt="local branches> " \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' \
    --ansi --no-sort \
    --bind 'change:first' \
    --header 'Alt-A: switch between local and all branches' \
    --border-label-pos=2 \
    --border-label "🌈 Branches" \
    --color hl:underline,hl+:underline \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) --' \
    --bind "alt-a:transform: [[ \$FZF_PROMPT == 'local branches> ' ]] &&
                        echo \"change-prompt(all branches> )+reload:(git branch --all $git_branch_opt) \" ||
                        echo \"change-prompt(local branches> )+reload:(git branch $git_branch_opt) \" " \
    --bind "start:reload(git branch $git_branch_opt)" \
    -- "$@" < <(echo)
}

_fzf_complete_gcob_post() {
    sed 's/^..//' | cut -d' ' -f1
}
[ -n "$BASH" ] && complete -F _fzf_complete_gcob -o default -o bashdefault gcob
