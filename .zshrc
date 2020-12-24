source /usr/local/share/antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle pip
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Auto suggestions bubdle.
antigen bundle zsh-users/zsh-autosuggestions

# Load the theme.
antigen theme robbyrussell

# Tell Antigen that you're done.
antigen apply

# personal settings
export EDITOR='emacs'

alias e='emacs -nw'

declare -x DISPLAY=":0.0"

export GPG_TTY=$(tty)

if type "go" > /dev/null; then
    export GOPATH=$(go env GOPATH)
    export PATH=$PATH:$GOPATH/bin
fi

if type "gdircolors" > /dev/null; then
    alias dircolors='gdircolors'
fi

if type "dircolors" > /dev/null; then
    eval $( dircolors -b $HOME/.dircolors )
fi

