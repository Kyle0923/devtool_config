alias h=history
alias l="ls -F"
alias ll="ls -lhaF"
alias gits="git status"
alias croot='cd `git rev-parse --show-toplevel`'
alias crepo='cd $REPO_ROOT'

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

if [ ! -e ".dockerenv" ]; then
  export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
else
  export PS1="\[\e[44m\]\u@\h\[\e[0m\] \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
fi


REPO_ROOT=~
REPO() {
  REPO_ROOT=$(git rev-parse --show-toplevel)
  echo "$REPO_ROOT"
}

bookmark() {
  REPO .  # reset REPO_ROOT
  path="$HOME/bookmark/$HOSTNAME"
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  COMMENT='\033[0;32m'
  NC='\033[0m' # No Color
  if (($# == 0)); then
    # no arg, print bookmark
    echo -e ">> in ${YELLOW}$path${NC}"
    n=1
    while IFS= read -r line; do
      regex='([^ #]*)( *\#.*$)*'
      [[ $line =~ $regex ]]
      if [ "$(pwd)" = "${BASH_REMATCH[1]}" ]; then
        echo -e "${BLUE}[$n]${NC}${BLUE}*${BASH_REMATCH[1]}${COMMENT}${BASH_REMATCH[2]}${NC}"
      else
        echo -e "${BLUE}[$n]${NC} ${BASH_REMATCH[1]}${COMMENT}${BASH_REMATCH[2]}${NC}"
      fi
      n=$((n+1))
    done < $path
    return
  fi
  regex='^-?[0-9]+$'
  if ! [[ "$1" =~ $regex ]]; then
    # add path to bookmark
    if (($# == 2)); then
      echo $(realpath $1) \# $2 >> $path
    else
      realpath $1 >> $path
    fi
    sort $path | uniq > ~/bookmark/temp
    mv ~/bookmark/temp $path
    sed -i -e "s+$(REPO .)+\\\$\(REPO\)+" $path
    bookmark
  else
    if (($1 > 0)); then
      # cd to the corresponding directory
      cd $(eval echo $(sed -n -e "$1p" $path))
    elif (($1 < 0)); then
      # remove the entry
      n=$((-$1))
      echo -e "removing [$n] ${RED}$(sed -n -e ${n}p $path)${NC}"
      sed -i -e "${n}d" $path
    fi
  fi
}

note() {
  path="$HOME/note/$HOSTNAME"
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  COMMENT='\033[0;32m'
  NC='\033[0m' # No Color
  if (($# == 0)); then
    # no arg, print note
    echo -e ">> in ${YELLOW}$path${NC}"
    n=1
    while IFS= read -r line; do
      line=$(echo $line | sed -e 's/\\/\\\\/g')
      regex='([^#]*)( *\#.*$)*'
      [[ $line =~ $regex ]]
      echo -e "${BLUE}[$n]${NC} ${BASH_REMATCH[1]}${COMMENT}${BASH_REMATCH[2]}${NC}"
      n=$((n+1))
    done < $path
    return
  fi
  regex='^-?[0-9]+$'
  if ! [[ "$1" =~ $regex ]]; then
    # add cmd to note
    if (($# == 2)); then
      echo $1 \# $2 >> $path
    else
      echo $1 >> $path
    fi
    sort $path | uniq > ~/note/temp
    mv ~/note/temp $path
    note
  else
    if (($1 > 0)); then
      # execute the corresponding cmd
      echo -e "\n${RED}$(sed -n -e "$1p" $path | sed -e "s/\s*\#.*$//" -e 's/\\/\\\\/g') ${@:2}${NC}\n"
      eval "$(sed -n -e "$1p" $path | sed -e "s/\s*\#.*$//") ${@:2}"
    elif (($1 < 0)); then
      # remove the entry
      n=$((-$1))
      echo -e "removing [$n] ${RED}$(sed -n -e ${n}p $path)${NC}"
      sed -i -e "${n}d" $path
    fi
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
