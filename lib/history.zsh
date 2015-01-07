## Command history configuration
if [ -z "$HISTFILE" ]; then
    HISTFILE=$HOME/.zsh_history
fi

HISTSIZE=10000
SAVEHIST=10000

setopt extended_history
setopt hist_expire_dups_first
setopt no_hist_ignore_dups
setopt hist_ignore_space
setopt no_hist_verify
setopt inc_append_history
setopt no_share_history # Do not share history automatically, but import it manually using "fc -RI" when needed
