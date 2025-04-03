alias h=history
alias l="ls -F"
alias ll="ls -lhaF"
alias gits="git status"
alias croot='cd `git rev-parse --show-toplevel`'
alias crepo='cd $REPO_ROOT'
alias rp='realpath'
alias ra='ranger'
alias bashrc_source='source ~/.bashrc'
alias c-='c -'
alias ..='cdup'

export LESSOPEN="|/usr/local/bin/lesspipe.sh %s"
export LESSCOLORIZER="bat"

export RANGER_LOAD_DEFAULT_RC=FALSE

[ -f ~/.fzf.bash ] && source ~/.fzf.bash || echo missing \~/.fzf.bash
[ -f ~/tools/fzf-git.sh/fzf-git.sh ] && source ~/tools/fzf-git.sh/fzf-git.sh || echo missing \~/tools/fzf-git.sh/fzf-git.sh
[ -f ~/tools/devtool_config/kyle_fzf.bash ] && source ~/tools/devtool_config/kyle_fzf.bash || echo missing \~/tools/devtool_config/kyle_fzf.bash

# for git checkout <commit>
function gcoc() {
    if [ $# -eq 0 ] ; then
        # no arguments
        local dest=`_fzf_git_hashes --no-multi`
        [[ -n "$dest" ]] && git checkout $dest
    else
        git checkout "$@"
    fi
}

# for git checkout <branch>
function gcob() {
    if [ $# -eq 0 ] ; then
        # no arguments
        local dest=`_fzf_git_branches --no-multi`
        [[ -n "$dest" ]] && git checkout $dest
    else
        git checkout "$@"
    fi
}

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# when PS1 is too long, prompt starts in next line
handle_long_ps1() {
    local input=$(echo $1 | sed -e "s,$HOME,~,")
    local plain_text=$(echo -e "$input" | sed -E 's/\x1B\[[0-9;]*[mK]//g')
    local length=${#plain_text}
    local terminal_width=$(tput cols)
    local max_length=$(( terminal_width * 2 / 3 ))
    if [[ $length -gt $max_length ]]; then
        echo -e "$input\n$ "
    else
        echo -e "$input $ "
    fi
}

if [ ! -e '/.dockerenv' ]; then
    # export PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}$(handle_long_ps1 "\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[33m\]$(parse_git_branch)\[\033[00m\]")'
    export PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}$(handle_long_ps1 "\[\E[44m\E[30m\]\u@\h\[\E[42m\E[34m\]\[\356\202\]\260\[\E[30m\]\w\[\E[43m\E[32m\]\[\356\202\]\260\[\E[43m\E[30m\]$(parse_git_branch)\[\E[0m\E[33m\]\[\356\202\]\260\[\E[0m\]")'
else
    export PS1="\$(handle_long_ps1 \"\[\e[44m\]\u@\h\[\e[0m\] \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\]\")"
fi

# cd up the dir tree
function cdup() {
    if [ $# -eq 0 ] ; then
        cd ..
        return
    fi

    # support '.. .. ..', '.. 3' and '.. workspace # cd up to workspace'
    if [[ $1 =~ ^[0-9]+$ ]]; then
        # .. 3 => cd ../../..
        local counter;
        for counter in $(seq 1 $1); do local dest="../$dest"; done && c "$dest"
    elif [[ $1 == '..' ]]; then
        # .. .. .. => cd ../../..
        c ..$(printf "/%s" "$@")
    else
        # .. workspace => cd [...]/workspace
        local CWD=`pwd | sed -e "s,$HOME,~,"`
        local filter_path=`echo $CWD | sed -e 's,/,\n,g' | \
            fzf --ansi --header $CWD --reverse --height="20%" -1 --exact -q "$*" \
                --bind "focus:transform-header([[ {} == '~' ]] && echo '~' || echo '$CWD' | sed -e 's,/{}/.*,/{},')"`
        if [[ -z "$filter_path" ]]; then
            return
        fi

        if [[ $filter_path == '~' ]]; then
            cd
            return
        fi

        local dest=`echo $CWD | sed -e "s,/$filter_path/.*,/$filter_path," | sed -e "s,~,$HOME,"`
        echo $dest
        cd $dest

    fi
}

# supercharged cd
function c() {
    if [ $# -eq 0 ] ; then
        # no arguments
        # source ranger
        local CD_PATH=$(fzf_interactive_cd)
        [[ -n $CD_PATH ]] && c $CD_PATH
    elif [ $1 == '-' ] ; then
        builtin cd -
    elif [ -d $1 ] ; then
        builtin cd "$1"
    elif [ -f $1 ] ; then
        echo "$1"
        builtin cd "$(dirname $1)"
    else
        local CD_PATH=$(ls -d */ | fzf -f "$1")
        if [[ -n $CD_PATH && $(echo "$CD_PATH" | wc -l) -eq 1 ]]; then
            echo "$CD_PATH" && cd $CD_PATH
        else
            local CD_PATH=$(fzf_interactive_cd "$1")
            [[ -n $CD_PATH ]] && c $CD_PATH
        fi
    fi
}

# lmk() {
#     local PATTERN="make(\[[0-9]+\])?: \*\*\*"
#     rgf --rg $1 "$PATTERN"
# }

# REPO_ROOT=~
# REPO() {
#     REPO_ROOT=$(git rev-parse --show-toplevel)
#     echo "$REPO_ROOT"
# }

bookmark() {
    # REPO .  # reset REPO_ROOT
    local registry_path="$HOME/.config/kyle/bookmark"

    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BLUE='\033[0;34m'
    local COMMENT='\033[0;32m'
    local NC='\033[0m' # No Color

    if (($# == 0)); then
        # no arg, print bookmark to fzf
        local dest=`bookmark --list | tail -n +2 | \
                    fzf --ansi --height="50%" --reverse --prompt='bookmark> ' --bind 'change:first' --preview 'fzf_previewer {}' --preview-window 'up:2' \
                    --bind 'ctrl-d:become:echo -{}' --header 'Ctrl+D: delete' --tiebreak 'chunk,begin' | \
                    awk '{print $1}' | sed -e 's/\[\|\]//g'`
        [[ -n "$dest" ]] && bookmark $dest || bookmark --list
        return
    fi # no arg
    if [[ $1 == '-l' || $1 == '--list' ]]; then
        # print bookmark
        echo -e ">> in ${YELLOW}$registry_path${NC}"
        local n=1
        while IFS= read -r line; do
            local regex='([^ #]*)( *\#.*$)*'
            [[ $line =~ $regex ]]
            local curr_dir_suffix=''
            if [ "$(pwd)" = "${BASH_REMATCH[1]}" ]; then
                curr_dir_suffix=" ${RED}## current directory ##${NC}"
            #     echo -e "${BLUE}[$n]${NC}${BLUE} ${BASH_REMATCH[1]}${COMMENT}${BASH_REMATCH[2]}${NC}"
            # else
            fi
            echo -e "${BLUE}[$n]${NC} ${BASH_REMATCH[1]}${COMMENT}${BASH_REMATCH[2]}${NC}$curr_dir_suffix"
            n=$((n+1))
        done < $registry_path
        return
    fi
    local regex='^-?[0-9]+$'
    if [[ "$@" =~ $regex ]]; then
        if (($1 > 0)); then
            # cd to the corresponding directory
            echo -e "cd ${YELLOW}$(sed -n -e "$1p" $registry_path | sed -e "s/\s*\#.*$//" -e 's/\\/\\\\/g') ${@:2}${NC}"
            cd $(eval echo $(sed -n -e "$1p" $registry_path))
        elif (($1 < 0)); then
            # remove the entry
            n=$((-$1))
            echo -e "removing [$n] ${RED}$(sed -n -e ${n}p $registry_path)${NC}"
            sed -i -e "${n}d" $registry_path
        fi
    else
        # add path to bookmark
        if (($# == 2)); then
            echo $(realpath $1) \# $2 >> $registry_path
        else
            realpath $1 >> $registry_path
        fi
        sort $registry_path | uniq > "${registry_path}_temp"
        mv "${registry_path}_temp" $registry_path
        # sed -i -e "s+$(REPO .)+\\\$\(REPO\)+" $registry_path # replace base directory with variable, useful in git worktree workflow
        bookmark --list

    fi
}

note() {
    local registry_path="$HOME/.config/kyle/note"

    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BLUE='\033[0;34m'
    local COMMENT='\033[0;32m'
    local NC='\033[0m' # No Color

    if (($# == 0)); then
        # no arg, print note to fzf
        local cmd=`note --list | tail -n +2 | \
                    fzf --ansi --height="50%" --reverse --prompt='note> ' --bind 'change:first' --preview 'fzf_previewer {}' --preview-window 'up:2' \
                    --bind 'ctrl-d:become:echo -{}' --header 'Ctrl+D: delete' --tiebreak 'chunk,begin' | \
                    awk '{print $1}' | sed -e 's/\[\|\]//g'`
        if [[ -n "$cmd" ]]; then
            echo "note $cmd"
            history -s "note $cmd"
            note $cmd
        else
            note --list
        fi
        return
    fi
    if [[ $1 == '-l' || $1 == '--list' ]]; then
        # no arg, print note
        echo -e ">> in ${YELLOW}$registry_path${NC}"
        local n=1
        while IFS= read -r line; do
            line=$(echo $line | sed -e 's/\\/\\\\/g')
            local regex='([^#]*)( *\#.*$)*'
            [[ $line =~ $regex ]]
            echo -e "${BLUE}[$n]${NC} ${BASH_REMATCH[1]}${COMMENT}${BASH_REMATCH[2]}${NC}"
            n=$((n+1))
        done < $registry_path
        return
    fi

    local regex='^-?[0-9]+$'
    if [[ "$@" =~ $regex ]]; then
        if (($1 > 0)); then
            # execute the corresponding cmd
            [ $$ -ne $BASHPID ] && local bg_suffix=' &'
            echo -e "\n${YELLOW}$(sed -n -e "$1p" $registry_path | sed -e "s/\s*\#.*$//" -e 's/\\/\\\\/g') ${@:2}${NC}$bg_suffix\n"
            eval "$(sed -n -e "$1p" $registry_path | sed -e "s/\s*\#.*$//") ${@:2}"
            history -s "$(sed -n -e "$1p" $registry_path | sed -e "s/\s*\#.*$//") ${@:2}"
        elif (($1 < 0)); then
            # remove the entry
            local n=$((-$1))
            echo -e "removing [$n] ${RED}$(sed -n -e ${n}p $registry_path)${NC}"
            sed -i -e "${n}d" $registry_path
        fi
    else
        # add cmd to note
        echo $@ >> $registry_path
        sort $registry_path | uniq > "${registry_path}_temp"
        mv "${registry_path}_temp" $registry_path
        note --list
    fi
}

alias cd1='bookmark 1'
alias cd2='bookmark 2'
alias cd3='bookmark 3'
alias cd4='bookmark 4'
alias cd5='bookmark 5'
alias cd6='bookmark 6'
alias cd7='bookmark 7'
alias cd8='bookmark 8'
alias cd9='bookmark 9'
alias cd10='bookmark 10'
alias bk='bookmark'
