alias h=history
alias l="ls -F"
alias ll="ls -lhaF"
alias gits="git status"
alias croot='cd `git rev-parse --show-toplevel`'
alias crepo='cd $REPO_ROOT'
alias ra='ranger'
alias bashrc_source='source ~/.bashrc'
alias ..='cd ..'

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

if [ ! -e '/.dockerenv' ]; then
    export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
else
    export PS1="\[\e[44m\]\u@\h\[\e[0m\] \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
fi

function c() {
    if [ $# -eq 0 ] ; then
        # no arguments
        source ranger
    elif [ $1 == '-' ] ; then
        builtin cd -
    elif [ -d $1 ] ; then
        # argument is a directory
        builtin cd "$1"
    else
        # argument is not a directory
        builtin cd "$(dirname $1)"
    fi
}

export RANGER_LOAD_DEFAULT_RC=FALSE


REPO_ROOT=~
REPO() {
    REPO_ROOT=$(git rev-parse --show-toplevel)
    echo "$REPO_ROOT"
}

bookmark() {
    # REPO .  # reset REPO_ROOT
    registry_path="$HOME/.config/kyle/bookmark"
    if [ "$NO_COLOR_OUTPUT" != true ]; then
        local YELLOW='\033[1;33m'
        local RED='\033[0;31m'
        local BLUE='\033[0;34m'
        local COMMENT='\033[0;32m'
        local NC='\033[0m' # No Color
    fi
    if (($# == 0)); then
        # no arg, print bookmark
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
        bookmark

    fi
}

note() {
    local registry_path="$HOME/.config/kyle/note"
    if [ "$NO_COLOR_OUTPUT" != true ]; then
        local YELLOW='\033[1;33m'
        local RED='\033[0;31m'
        local BLUE='\033[0;34m'
        local COMMENT='\033[0;32m'
        local NC='\033[0m' # No Color
    fi
    if (($# == 0)); then
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
        note
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
