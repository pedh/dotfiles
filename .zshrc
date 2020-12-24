source /usr/local/share/antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle pip
antigen bundle command-not-found
antigen bundle autojump
antigen bundle httpie
antigen bundle fzf
antigen bundle gnu-utils

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Auto suggestions bundle.
antigen bundle zsh-users/zsh-autosuggestions

# Load the theme.
antigen theme robbyrussell

# Tell Antigen that you're done.
antigen apply

# personal settings
alias e='emacsclient -nw'
export EDITOR='emacsclient -nw'
export ALTERNATE_EDITOR='vim'
export DISPLAY=":0.0"
export GPG_TTY=$(tty)
export BAT_THEME=zenburn

fpath=("/usr/local/share/zsh/site-functions" $fpath)
export FPATH

if type gdircolors &>/dev/null; then
    dircolors=gdircolors
fi
eval $( dircolors -b $HOME/.dircolors )
