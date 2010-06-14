# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh

# Set to the name theme to load.
# Look in ~/.oh-my-zsh/themes/
export ZSH_THEME="blueyed"

# Set to this to use case-sensitive completion
# export CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# export DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# export DISABLE_LS_COLORS="true"

source $ZSH/oh-my-zsh.sh

# Customize to your needs...

REPORTTIME=10 # print elapsed time when more than 10 seconds

setopt MAIL_WARNING
setopt HIST_IGNORE_SPACE # Ignore commands with leading space

setopt MARK_DIRS # Append a trailing `/' to all directory names resulting from filename generation (globbing).

setopt NUMERIC_GLOB_SORT
setopt EXTENDED_GLOB

# hows about arrays be awesome?  (that is, frew${cool}frew has frew surrounding all the variables, not just first and last
setopt RC_EXPAND_PARAM

export RI="--format ansi"


# directory based VCS before repo based ones (e.g. CVS in $HOME, the latter using Git)
zstyle ':vcs_info:*' enable cvs svn bzr git
zstyle ':vcs_info:bzr:*' use-simple true


# Incremental search
bindkey -M vicmd "/" history-incremental-search-backward
bindkey -M vicmd "?" history-incremental-search-forward

# Search based on what you typed in already
bindkey -M vicmd "//" history-beginning-search-backward
bindkey -M vicmd "??" history-beginning-search-forward

# <Esc>-h runs help on current BUFFER
bindkey "\eh" run-help

# Replace current buffer with executed result (vicmd mode)
bindkey -M vicmd '!' edit-command-output
edit-command-output() {
	BUFFER=$(eval $BUFFER)
	CURSOR=0
}
zle -N edit-command-output

# Make files executable via associated apps
autoload -U zsh-mime-setup
zsh-mime-setup

watch=(notme)

# autojump
if which autojump > /dev/null ; then
	source ~/.dotfiles/autojump/autojump.zsh
fi

# Load bash completion system
# via http://zshwiki.org/home/convert/bash
autoload -U bashcompinit
bash_source() {
  alias shopt=':'
  alias _expand=_bash_expand
  alias _complete=_bash_comp
  emulate -L sh
  setopt kshglob noshglob braceexpand

  source "$@"
}
# Load completion from bash, which isn't available in zsh yet.
which vzctl > /dev/null && bash_source /etc/bash_completion.d/vzctl.sh


# run-help for builtins
# Explicitly set HELPDIR, see http://bugs.debian.org/530366
HELPDIR=/usr/share/zsh/help
unalias run-help
autoload run-help
