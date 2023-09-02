#!/usr/bin/env bash

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed
# Some more GNU utils
brew install diffutils
brew install inetutils
brew install gnutls
brew install gawk
brew install gnu-tar
brew install gzip
brew install make
brew install wdiff
brew install gnu-indent
brew install gnu-which
brew install man-db
# Install a modern version of Bash.
brew install bash
brew install bash-completion2

# Install zsh and zinit
brew install zsh
brew install zinit

# Install essential applications
brew install --cask iterm2
brew install --cask google-chrome
brew install --cask visual-studio-code

# Editors
brew tap railwaycat/emacsmacport
brew install --cask emacs-mac
brew install neovim

# Awesome MacOS applications
brew install --cask scroll-reverser
brew install --cask hiddenbar
brew install --cask free-download-manager
brew install --cask slack

# Security
brew install --cask keepassxc
brew install pass

# Install network tools
brew install wget
brew install --cask charles
brew install --cask wireshark
brew install --cask postman
brew install httpie
brew install aria2
brew install tcpdump
brew install termshark
brew install iperf3
brew install proxychains-ng
brew install mtr
brew install ipinfo-cli

# Install more recent versions of some macOS tools.
brew install vim
brew install grep
brew install openssh
brew install screen
brew install php
brew install gmp
# Homebrew
brew tap homebrew/command-not-found

# Document tools
brew install graphviz
brew install plantuml
brew install --cask calibre
brew install --cask mactex
brew install --cask inkscape
brew install --cask logseq
brew install pandoc

# Awesome command line tools
brew install autojump
brew install bat
brew install fd
brew install fzf
brew install asciinema
brew install htop
brew install gotop
brew install btop
brew install pstree
brew install tldr
brew install magic-wormhole
brew install mycli
brew install mas
brew install pgcli
brew install the_silver_searcher
brew install ripgrep
brew install lsusb
brew install thefuck
brew install shellcheck
brew install jq
brew install yq
brew install cloc
brew install mu
brew install isync

# Install other useful binaries.
brew install ack
brew install exiv2
brew install git
brew install git-lfs
brew install git-extras
brew install gitup
brew install gh
brew install global
brew install gs
brew install imagemagick
brew install lua
brew install lynx
brew install p7zip
brew install pigz
brew install pv
brew install rename
brew install rlwrap
brew install ssh-copy-id
brew install tree
brew install vbindiff
brew install zopfli
brew install tmux
brew install --cask cmake
brew install llvm
brew install bear
brew install mysticlgbt/made/mac-linux-kdk
brew install editorconfig
brew install languagetool
brew install smartmontools

# Python packages
brew install python
brew install ipython
brew install anaconda
brew install ansible
brew install numpy
brew install python-lsp-server
brew install pyenv
brew install poetry
brew install pipenv

# Golang packages
brew install go
brew install protobuf
brew install gops

# Rust packages
brew install rustup

# Haskell packages
brew install ghcup

# Common lisp packages
brew install sbcl

# Node.js packages
brew install npm

# Web packages
brew install stylelint

# Kubernetes cli packages
brew install kubernetes-cli
brew install krew
brew install kubectx
brew install helm
brew install kubebuilder

# Install GnuPG to enable PGP-signing commits.
brew install gnupg
brew install --cask gpg-suite

# Install some CTF tools; see https://github.com/ctfs/write-ups.
brew install aircrack-ng
brew install bfg
brew install binutils
brew install binwalk
brew install cifer
brew install dex2jar
brew install dns2tcp
brew install fcrackzip
brew install foremost
brew install hashpump
brew install hydra
brew install john
brew install knock
brew install netpbm
brew install nmap
brew install pngcheck
brew install socat
brew install sqlmap
brew install tcpflow
brew install tcpreplay
brew install tcptrace
brew install ucspi-tcp # `tcpserver` etc.
brew install xz
brew install radare2
brew install --cask cutter
brew install flamegraph
brew install pngpaste

# Install font tools.
brew tap bramstein/webfonttools
brew install sfnt2woff
brew install sfnt2woff-zopfli
brew install woff2

# Multimedia
brew install --cask kodi
brew install --cask krita
brew install --cask wacom-tablet
brew install --cask listen1

# Remove outdated versions from the cellar.
brew cleanup
