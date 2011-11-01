# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh

# Set to the name theme to load.
# Look in ~/.oh-my-zsh/themes/
export ZSH_THEME="blueyed"

# Set to this to use case-sensitive completion
# export CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
export DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# export DISABLE_LS_COLORS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby ighthouse)
plugins=(git github dirstack svn apt byobu)

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

setopt PUSHD_SILENT # make popd quiet

setopt CORRECT # do not use CORRECT_ALL

export RI="--format ansi"


# directory based VCS before repo based ones (e.g. CVS in $HOME, the latter using Git)
zstyle ':vcs_info:*' enable cvs svn bzr hg git
zstyle ':vcs_info:bzr:*' use-simple true


# Incremental search
bindkey -M vicmd "/" history-incremental-search-backward
bindkey -M vicmd "?" history-incremental-search-forward

# Remap C-R/C-S to use patterns
if (( ${+widgets[history-incremental-pattern-search-backward]} )); then
	# since 4.3.7, not in Debian Lenny
	bindkey "^R" history-incremental-pattern-search-backward
	bindkey "^S" history-incremental-pattern-search-forward
fi

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
# Do not break invoke-rc.d completion
unalias -s d 2>/dev/null

watch=(notme)

# autojump
test "$commands[autojump]" && source ~/.dotfiles/autojump/autojump.zsh

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
test "$commands[vzctl]" && bash_source /etc/bash_completion.d/vzctl.sh


# run-help for builtins
# Explicitly set HELPDIR, see http://bugs.debian.org/530366
HELPDIR=/usr/share/zsh/help
unalias run-help &>/dev/null
autoload run-help

autoload -U edit-command-line
zle -N edit-command-line
bindkey '\ee' edit-command-line

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval $(lesspipe)

# options for less: move jump target to line 5 and handle ANSI color sequences (default, but required with $LESS set?!), for "git diff"
export LESS="-j5 -R"

# directory shortcuts
hash -d l=/var/log


# just type '...' to get '../..'
# Originally by grml, improved by Mikachu
rationalise-dot() {
local MATCH
if [[ $LBUFFER =~ '(^|/| |	|'$'\n''|\||;|&)\.\.$' ]]; then
  LBUFFER+=/
  zle self-insert
  zle self-insert
else
  zle self-insert
fi
}
zle -N rationalise-dot
bindkey . rationalise-dot
# without this, typing a . aborts incremental history search
# "isearch" does not exist in zsh 4.3.6 (Debian Lenny)
bindkey -M isearch . self-insert 2>/dev/null

if [[ "${COLORTERM}" == "gnome-terminal" && "$TERM" == "xterm" ]]; then
    export TERM="xterm-256color"
fi
# Fix up TERM if there's no info for the currently set one (might cause programs to fail)
if ! tput longname &> /dev/null; then
	if [[ $TERM == screen*bce ]]; then TERM=screen-bce
	elif [[ $TERM == screen* ]]; then TERM=screen
	else TERM=xterm fi
	export TERM
fi

# Add binaries from gems to path
path+=(/var/lib/gems/1.8/bin/)

# Add superuser binaries to path
path+=(/sbin /usr/sbin)

# make path/PATH entries unique
typeset -U path

setopt GLOB_COMPLETE # helps with "setopt *alias<tab>" at least

# Setup vimpager as pager:
export PAGER=~/.dotfiles/lib/vimpager/vimpager
alias less=$PAGER
alias zless=$PAGER

# use full blown vim always
if [ "$commands[(I)vim]" ]; then
  alias vi=vim
fi

# Restart network interface
ifrestart() {
  (( $# > 0 )) || { echo "Missing interface."; return 1; }
  if [[ $UID == 0 ]]; then
    ifdown $1
    ifup $1
  else
    sudo ifdown $1
    sudo ifup $1
  fi
}

multicat() {
  for file in $@; do
    echo "=== $file ==="
    cat $file
  done
}


# Start a session as root, using a separate environment (~/.rootsession)
rootsession() {
  rh=$HOME/.rootsession
  if [[ ! -d $rh ]]; then
    # Create home directory for root session
    mkdir -p $rh
    # Copy dotfiles repo from user home
    # TODO: maybe just symlink it?! (no separation, but easier to keep in sync)
    cp -a $HOME/.dotfiles $rh
    cd $rh/.dotfiles
    # Install symlinks for dotfiles
    sudo -s HOME=$rh make install_checkout
  fi
  sudo -s HOME=$rh
}


# Source local rc file if any
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

true # return code 0
