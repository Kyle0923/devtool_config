#!/usr/bin/env bash

RG_URL=
FD_URL=
BAT_URL=

cd ~/tools/
git clone https://github.com/junegunn/fzf.git
git clone https://github.com/junegunn/fzf-git.sh.git

mkdir -p ~/.bin
cd ~/.bin
ln -s ~/tools/devtool_config/rgf ./
ln -s ~/tools/devtool_config/fzf_previewer ./

[[ ":$PATH:" != *":$HOME/.bin:"* ]] && echo 'export PATH="$HOME/.bin:$PATH"' >> ~/.bashrc
echo 'source /home/kyle/tools/devtool_config/kyle_bashrc.sh' >> ~/.bashrc

download_tool() {
    local TEMP="~/tools/temp"
    mkdir -p $TEMP
    cd $TEMP

    local url=$1
    local tool=$2

    if [ -z "$url" ] || [ -z "$tool" ]; then
        echo "URL for $tool not provided. Skipping..."
        return 1
    fi

    echo "Downloading from $url..."

    wget -q "$url" -O temp.tar.gz
    tar -xzf temp.tar.gz

    dir_name=$(basename $(ls -d */))
    cd $dir_name || return 1
    ln -s $(realpath $tool) ~/.bin/
    echo "Done installing $tool"

    cd ~/tools
    rm -fr $TEMP
}

echo ""
download_tool "$RG_URL" "rg"
download_tool "$FD_URL" "fd"
download_tool "$BAT_URL" "bat"

git config --global alias.co checkout
git config --global alias.br branch

echo ""
echo "Done cloning FZF, FZF-git."
echo "Created ~/.bin and add rgf and fzf_previewer"
echo ""
echo "TODO: "
echo "install fzf by running ~/tools/fzf/install with Y,Y,N"
echo "check installation for rg, fd, bat"
echo ""
