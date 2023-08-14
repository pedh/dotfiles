source /opt/homebrew/opt/zinit/zinit.zsh

setopt promptsubst
setopt histignorespace

# set LS_COLORS for gnu ls
if [[ -f .LS_COLORS ]]; then
    source .LS_COLORS
fi

# set extra paths
typeset -U path
path=(/usr/local/sbin
      /opt/homebrew/bin
      /opt/homebrew/sbin
      ${HOME}/.config/emacs/bin
      ${HOME}/go/bin
      ${HOME}/.krew/bin
      ${HOME}/.ghcup/bin
      ${HOME}/.cargo/bin
      $path)
export PATH

zinit wait lucid for \
      OMZL::git.zsh \
      OMZL::directories.zsh \
      OMZL::key-bindings.zsh \
      OMZL::completion.zsh \
      OMZL::theme-and-appearance.zsh \
      OMZP::git \
      OMZP::pip \
      OMZP::command-not-found \
      OMZP::autojump \
      OMZP::fzf \
      OMZP::gnu-utils \
      OMZP::kubectl

PS1="READY >" # provide a simple prompt till the theme loads

zinit ice depth"1"
zinit light romkatv/powerlevel10k

zinit wait lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
 atinit"
     zstyle ':completion:*' extra-verbose yes
     zstyle ':completion:*' completer _extensions _complete _approximate
     zstyle ':completion:*:descriptions' format '%F{yellow}%B--- %d%b%f'
     zstyle ':completion:*:messages' format '%d'
     zstyle ':completion:*:warnings' format '%F{red}No matches for:%f %d'
     zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
     zstyle ':completion:*' group-name ''
     zstyle ':completion:*' list-colors \${(s.:.)LS_COLORS}
" \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    wfxr/forgit

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
if type "thefuck" > /dev/null; then
    eval $(thefuck --alias f)
fi
export EDITOR='emacsclient -nw'
export ALTERNATE_EDITOR='vim'
export DISPLAY=":0.0"
export GPG_TTY=$TTY
export BAT_THEME=zenburn

fpath=("/usr/local/share/zsh/site-functions" $fpath)
export FPATH

backward-kill-dir () {
    local WORDCHARS='*?_-.[]~=&;!#$%^(){}<>/'
    zle backward-kill-word
}
zle -N backward-kill-dir
bindkey '^W' backward-kill-dir
