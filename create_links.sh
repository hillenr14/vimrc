#!/bin/sh
vim=~/.vimrc
zshrc=~/.zshrc
nvim=~/.config/nvim/init.vim
p10k=~/.oh-my-zsh/custom/themes/powerlevel10k/internal/p10k.zsh
if [ -e $vim -a ! -L $vim ]; then
    echo "Replacing $vim with link to vimrc"
    rm $vim
    ln -s ~/vimrc/vimrc $vim
elif [ ! -e $vim ]; then
    echo "Creating $vim link to vimrc"
    ln -s ~/vimrc/vimrc $vim
fi
if [ -e $nvim -a ! -L $nvim ]; then
    echo "Replacing $nvim with link to vimrc"
    rm $nvim
    ln -s ~/vimrc/vimrc $nvim
elif [ ! -e $nvim ]; then
    if [ ! -d ~/.config ] ; then
        mkdir ~/.config
        mkdir ~/.config/nvim
    fi
    if [ ! -d ~/.config/nvim ] ; then
        mkdir ~/.config/nvim
    fi
    echo "Creating $nvim link to vimrc"
    ln -s ~/vimrc/vimrc $nvim
fi
if [ -e $p10k -a ! -L $p10k ]; then
    echo "Replacing $p10k with link to p10k.zsh"
    rm $p10k
    ln -s ~/vimrc/p10k.zsh $p10k
elif [ ! -e $p10k ]; then
    echo "$p10k does not exist"
fi
if [ -e $zshrc -a ! -L $zshrc ]; then
    echo "Replacing $zshrc with link to zshrc"
    rm $zshrc
    ln -s ~/vimrc/zshrc $zshrc
elif [ ! -e $zshrc ]; then
    echo "Creating $zshrc link to zshrc"
    ln -s ~/vimrc/zshrc $zshrc
fi
