#!/usr/bin/env bash

cd ~/tools/
git clone https://github.com/junegunn/fzf.git
git clone https://github.com/junegunn/fzf-git.sh.git

mkdir ~/.bin
cd ~/.bin
ln -s ~/tools/devtool_config/rgf ./
ln -s ~/tools/devtool_config/fzf_previewer ./

[[ ":$PATH:" != *":$HOME/.bin:"* ]] && echo 'export PATH="$HOME/.bin:$PATH"' >> ~/.bashrc
echo 'source /home/kyle/tools/devtool_config/kyle_bashrc.sh' >> ~/.bashrc

echo ""
echo "Done cloning FZF, FZF-git."
echo "Created ~/.bin and add rgf and fzf_previewer"
echo ""
echo "TODO: "
echo "install fzf by running ~/tools/fzf/install with Y,Y,N"
echo "install rg, fd, bat"
echo ""
