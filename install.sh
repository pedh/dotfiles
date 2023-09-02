#!/usr/bin/env bash

set -e
set -x

DOTFILES_PATH=$(git rev-parse --show-toplevel)

function install_git_config() {
	ln -sf ${DOTFILES_PATH}/.git-config ${HOME}/.gitconfig
}

function install_dir_colors() {
	gdircolors -b ${DOTFILES_PATH}/.dircolors >${HOME}/.LS_COLORS
}

function install_zshrc() {
	local source_line='source ~/.dotfiles/.zshrc'
	grep -qxF "${source_line}" ${HOME}/.zshrc ||
		echo "${source_line}" >>${HOME}/.zshrc
}

function install_emacs_conf() {
	git -C ${HOME}/.config/emacs pull ||
		git clone --depth 1 https://github.com/doomemacs/doomemacs \
			${HOME}/.config/emacs
	${HOME}/.config/emacs/bin/doom install --no-config
	if [[ -e ${HOME}/.config/doom && ! -L ${HOME}/.config/doom ]]; then
		read -p "The doom config already exists, delete it?(y/N)" -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			rm -rf ${HOME}/.config/doom
		else
			exit 0
		fi
	fi
	ln -sf ${DOTFILES_PATH}/.config/doom ${HOME}/.config/
	${HOME}/.config/emacs/bin/doom sync
}

function install_vimrc() {
	ln -sf ${DOTFILES_PATH}/.vim ${HOME}/
	ln -sf ${DOTFILES_PATH}/.vimrc ${HOME}/
}

function install_nvim_config() {
	ln -sf ${DOTFILES_PATH}/.config/nvim ${HOME}/.config/
}

function install_tmux_conf() {
	git -C ${HOME}/.tmux pull ||
		git clone https://github.com/gpakosz/.tmux.git ${HOME}/.tmux
	ln -sf ${HOME}/.tmux/.tmux.conf ${HOME}/
	cp ${HOME}/.tmux/.tmux.conf.local ${HOME}/
}

function install_gpg_conf() {
	ln -sf ${DOTFILES_PATH}/.gnupg/gpg.conf ${HOME}/.gnupg/
	ln -sf ${DOTFILES_PATH}/.gnupg/gpg-agent.conf ${HOME}/.gnupg/
}

function install_mbsyncrc() {
	ln -sf ${DOTFILES_PATH}/.mbsyncrc ${HOME}/
}

function install_other() {
	ln -sf ${DOTFILES_PATH}/.tcshrc ${HOME}/
}

function install_all() {
	install_git_config
	install_dir_colors
	install_zshrc
	install_emacs_conf
	install_vimrc
	install_nvim_config
	install_tmux_conf
	install_gpg_conf
	install_mbsyncrc
	install_other
}

install_all
