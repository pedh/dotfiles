source ~/.zinit/bin/zinit.zsh

setopt promptsubst
setopt histignorespace

# set LS_COLORS for gnu ls
if [[ -f .LS_COLORS ]]; then
    source .LS_COLORS
fi

export PATH="/usr/local/sbin:$PATH"

zinit wait lucid for \
      OMZL::git.zsh \
      OMZL::directories.zsh \
      OMZL::key-bindings.zsh \
      OMZL::completion.zsh \
      OMZL::theme-and-appearance.zsh \
      OMZP::git \
      OMZP::pip \
      OMZP::pyenv \
      OMZP::command-not-found \
      OMZP::autojump \
      OMZP::httpie \
      OMZP::fzf \
      OMZP::gnu-utils \
      OMZP::kubectl

PS1="READY >" # provide a simple prompt till the theme loads

zinit wait'!' lucid for \
      OMZT::robbyrussell

zinit wait lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma/fast-syntax-highlighting \
 blockf \
 atinit"
     zstyle ':completion:*' menu select
     zstyle ':completion:*' extra-verbose yes
     zstyle ':completion:*:descriptions' format '$fg[yellow]%B--- %d%b'
     zstyle ':completion:*:messages' format '%d'
     zstyle ':completion:*:warnings' format '$fg[red]No matches for:$reset_color %d'
     zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
     zstyle ':completion:*' group-name ''
" \
 atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

# personal settings
alias e='emacsclient -nw'
alias glf="git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  sed -n 's/^blob //p' |
  sort --numeric-sort --key=2 |
  cut -c 1-12,41- |
  $(command -v gnumfmt || echo numfmt) --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest"
alias kx="kubectx"
alias kns="kubens"
export EDITOR='emacsclient -nw'
export ALTERNATE_EDITOR='vim'
export DISPLAY=":0.0"
export GPG_TTY=$(tty)
export BAT_THEME=zenburn

fpath=("/usr/local/share/zsh/site-functions" $fpath)
export FPATH

backward-kill-dir () {
    local WORDCHARS='*?_-.[]~=&;!#$%^(){}<>/'
    zle backward-kill-word
}
zle -N backward-kill-dir
bindkey '^W' backward-kill-dir
