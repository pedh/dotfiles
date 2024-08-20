# auto detect homebrew prefix
if [[ x"$(/usr/bin/uname -m)" == x"arm64" ]]
then
  HOMEBREW_PREFIX="/opt/homebrew"
else
  HOMEBREW_PREFIX="/usr/local"
fi

source ${HOMEBREW_PREFIX}/opt/zinit/zinit.zsh

# set LS_COLORS for gnu ls
if [[ -f .LS_COLORS ]]; then
    source .LS_COLORS
fi

# set extra paths
typeset -U path
path=(/usr/local/sbin
      ${HOMEBREW_PREFIX}/bin
      ${HOMEBREW_PREFIX}/sbin
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
      OMZP::kubectl \
      OMZP::terraform

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

### personal settings
## zsh options
# http://zsh.sourceforge.net/Doc/Release/Options.html

# Changing Directories
# http://zsh.sourceforge.net/Doc/Release/Options.html#Changing-Directories
setopt auto_cd                 # if a command isn't valid, but is a directory, cd to that dir
setopt auto_pushd              # make cd push the old directory onto the directory stack
setopt pushd_ignore_dups       # don’t push multiple copies of the same directory onto the directory stack
setopt pushd_minus             # exchanges the meanings of ‘+’ and ‘-’ when specifying a directory in the stack

# Completions
# http://zsh.sourceforge.net/Doc/Release/Options.html#Completion-2
setopt always_to_end           # move cursor to the end of a completed word
setopt auto_list               # automatically list choices on ambiguous completion
setopt auto_menu               # show completion menu on a successive tab press
setopt auto_param_slash        # if completed parameter is a directory, add a trailing slash
setopt complete_in_word        # complete from both ends of a word
unsetopt menu_complete         # don't autoselect the first completion entry

# Expansion and Globbing
# http://zsh.sourceforge.net/Doc/Release/Options.html#Expansion-and-Globbing
setopt extended_glob           # use more awesome globbing features
setopt glob_dots               # include dotfiles when globbing

# History
# http://zsh.sourceforge.net/Doc/Release/Options.html#History
setopt append_history          # append to history file
setopt extended_history        # write the history file in the ':start:elapsed;command' format
unsetopt hist_beep             # don't beep when attempting to access a missing history entry
setopt hist_expire_dups_first  # expire a duplicate event first when trimming history
setopt hist_find_no_dups       # don't display a previously found event
setopt hist_ignore_all_dups    # delete an old recorded event if a new event is a duplicate
setopt hist_ignore_dups        # don't record an event that was just recorded again
setopt hist_ignore_space       # don't record an event starting with a space
setopt hist_no_store           # don't store history commands
setopt hist_reduce_blanks      # remove superfluous blanks from each command line being added to the history list
setopt hist_save_no_dups       # don't write a duplicate event to the history file
setopt hist_verify             # don't execute immediately upon history expansion
setopt inc_append_history      # write to the history file immediately, not when the shell exits
unsetopt share_history         # don't share history between all sessions

# Initialization
# http://zsh.sourceforge.net/Doc/Release/Options.html#Initialisation

# Input/Output
# http://zsh.sourceforge.net/Doc/Release/Options.html#Input_002fOutput
unsetopt clobber               # must use >| to truncate existing files
unsetopt correct               # don't try to correct the spelling of commands
unsetopt correct_all           # don't try to correct the spelling of all arguments in a line
unsetopt flow_control          # disable start/stop characters in shell editor
setopt interactive_comments    # enable comments in interactive shell
unsetopt mail_warning          # don't print a warning message if a mail file has been accessed
setopt path_dirs               # perform path search even on command names with slashes
setopt rc_quotes               # allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
unsetopt rm_star_silent        # ask for confirmation for `rm *' or `rm path/*'

# Job Control
# http://zsh.sourceforge.net/Doc/Release/Options.html#Job-Control
setopt auto_resume            # attempt to resume existing job before creating a new process
unsetopt bg_nice              # don't run all background jobs at a lower priority
unsetopt check_jobs           # don't report on jobs when shell exit
unsetopt hup                  # don't kill jobs on shell exit
setopt long_list_jobs         # list jobs in the long format by default
setopt notify                 # report status of background jobs immediately

# Prompting
# http://zsh.sourceforge.net/Doc/Release/Options.html#Prompting
setopt prompt_subst           # expand parameters in prompt variables

# Scripts and Functions
# http://zsh.sourceforge.net/Doc/Release/Options.html#Scripts-and-Functions

# Shell Emulation
# http://zsh.sourceforge.net/Doc/Release/Options.html#Shell-Emulation

# Shell State
# http://zsh.sourceforge.net/Doc/Release/Options.html#Shell-State

# Zle
# http://zsh.sourceforge.net/Doc/Release/Options.html#Zle
unsetopt beep                 # be quiet!
setopt combining_chars        # combine zero-length punctuation characters (accents) with the base character
setopt emacs                  # use emacs keybindings in the shell

# Aliases
alias e='emacsclient -nw -s term'
alias eserver='emacs -nw --daemon=term'
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

# Exports
export EDITOR='emacsclient -nw -s term'
export ALTERNATE_EDITOR='nvim'
export DISPLAY=":0.0"
export GPG_TTY=$TTY
export BAT_THEME=zenburn
fpath=("/usr/local/share/zsh/site-functions" $fpath)
export FPATH

# Other
backward-kill-dir () {
    local WORDCHARS='*?_-.[]~=&;!#$%^(){}<>/'
    zle backward-kill-word
}
zle -N backward-kill-dir
bindkey '^W' backward-kill-dir
