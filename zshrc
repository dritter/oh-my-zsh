# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh

# Start profiling
# PS4='+$(date "+%s:%N") %N:%i> '
# exec 3>&2 2>/tmp/startlog.$$
# setopt xtrace prompt_subst

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
plugins=(git github dirstack svn apt)

fpath=(~/.dotfiles/lib/zsh-completions $fpath)

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

# TODO: http://zshwiki.org/home/zle/bindkeys%22%22
# see also lib/wordnav.zsh
bindkey -M vicmd "\eOH" beginning-of-line
bindkey -M vicmd "\eOF" end-of-line
# bindkey "\e[1;3D" backward-word
# bindkey "\e[1;3C" forward-word

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
source ~/.dotfiles/autojump/bin/autojump.zsh
export AUTOJUMP_KEEP_SYMLINKS=1

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
if [ -n "$commands[vzctl]" ] ; then
  if ! which complete &>/dev/null; then
    autoload -Uz bashcompinit
    if which bashcompinit &>/dev/null; then
      bashcompinit
    fi
  fi
  bash_source /etc/bash_completion.d/vzctl.sh
fi


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
# Also: (smart-)ignore case and do not fold long lines.
export LESS="-j5 -R -i -S"

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
if zmodload zsh/regex 2>/dev/null; then # might not be available (e.g. on DS212+)
  zle -N rationalise-dot
  bindkey . rationalise-dot
  # without this, typing a . aborts incremental history search
  # "isearch" does not exist in zsh 4.3.6 (Debian Lenny)
  bindkey -M isearch . self-insert 2>/dev/null
fi

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
# export PAGER=~/.dotfiles/lib/vimpager/vimpager
# alias less=$PAGER
# alias zless=$PAGER

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


# Start a session as another user (via sudo, default is root),
# using a separate environment based on ~/.dotfiles (in ~/.sudosession).
# NOTE: while "sudo -s HOME=.. …" appears to work best, it failed
#       on a SUSE 10.4 system with "$SHELL: can't open input file: command".
sudosession() {
  emulate -L zsh
  local user=root
  while [[ $1 == -* ]] ; do
    case $1 in
      (-u) shift ; user=$1 ;;
      (--) shift ; break ;;
      (-h)
	printf 'usage: sudosession [-h|-u USER] <cmd>\n'
                printf '  -h      shows this help text.\n'
                printf '  -u      set specific user (default: root).\n'
                return 0
                ;;
            (*) printf "unkown option: '%s'\n" "$1" ; return 1 ;;
    esac
    shift
  done

  [[ $USER == $user ]] && { echo "Already $user."; return 1; }

  sudohome=$HOME/.sudosession/$user
  tempfile=$(mktemp -t sudosession.XXXXXX)
  chmod u+x $tempfile
  if [[ ! -d $sudohome ]]; then
    mkdir -p $sudohome
    # Copy dotfiles repo from user home
    cp -a $HOME/.dotfiles $sudohome
    sudo chown $user $sudohome
    cd $sudohome/.dotfiles
    # Install symlinks for dotfiles
    sudo env HOME=$sudohome make install_checkout
    cd $OLDPWD
  fi
  # Create temporary file to be executed
  echo -nE "/usr/bin/env HOME=$sudohome" > $tempfile
  # Keep special environment vars (like sudo's envkeep)
  for i in SSH_AUTH_SOCK http_proxy https_proxy ftp_proxy no_proxy; do
    echo -nE " $i=${(P)i}" >> $tempfile
  done
  echo -nE " $SHELL" >> $tempfile
  if (( $#@ )); then
    # execute the command/arguments:
    # TODO: when using `-i` extra care should be taken to check for $PWD being the same!
    echo -E " -i -c '"${(q)*}"'" >> $tempfile
  fi
  echo "\ncommand rm \$0" >> $tempfile
  sudo chown $user $tempfile
  sudo -u $user $tempfile
}
alias rs=sudosession  # mnemonic: "root session"
compdef "_arguments '-u[user name]:user name:_users' '*::arguments: _normal'" sudosession

# connect to qemu system by default
export VIRSH_DEFAULT_CONNECT_URI=qemu:///system

# Special treatment for verdi4u machines
if [[ $(hostname -f 2>/dev/null) = *.verdi4u.de ]]; then
  # Get recent python into $PATH for autojump
  # (the first python from /opt != 2.4/2.5)
  if [[ $(python -V 2>&1) = Python\ 2.[45]* ]]; then
    for i in /opt/python /opt/py*(/) ; do
      i=${i%/}
      test -f $i/bin/python || continue
      if [[ $($i/bin/python -V 2>&1 ) != Python\ 2.[45]* ]]; then
        path=($i/bin $path)
        break
      fi
    done
  fi
fi

# wrap ~/.dotfiles/usr/bin/hub with GITHUB_TOKEN for authentication
hub() {
  if ! (( $+_ghtoken_ )); then
    if [[ -f ~/.dotfiles/.passwd ]] ; then
      _ghtoken_="$(dotfiles-decrypt 'U2FsdGVkX1+t8r0ZPLHFzBSbPrBVLz/VPb7U2+WtJS1PKdVzzsVlmfPcIZdOlJ88HTXx2hVPL8IvkmIThZjCHA==')"
    else
      _ghtoken_=
    fi
  fi
  GITHUB_TOKEN=$_ghtoken_ command hub "$@"
}

# autoload $ZSH/functions/*(:t)

# Display "^C" when aborting zle
TRAPINT() { print -nP %F{red}%B\^C%f%b; return 1 }

# exit zsh like vim
alias :q=exit
alias ZZ=exit

# goodness from grml-etc-core {{{1
# http://git.grml.org/?p=grml-etc-core.git;a=summary

# creates an alias and precedes the command with
# sudo if $EUID is not zero.
salias() {
    emulate -L zsh
    local only=0 ; local multi=0
    while [[ $1 == -* ]] ; do
        case $1 in
            (-o) only=1 ;;
            (-a) multi=1 ;;
            (--) shift ; break ;;
            (-h)
                printf 'usage: salias [-h|-o|-a] <alias-expression>\n'
                printf '  -h      shows this help text.\n'
                printf '  -a      replace '\'' ; '\'' sequences with '\'' ; sudo '\''.\n'
                printf '          be careful using this option.\n'
                printf '  -o      only sets an alias if a preceding sudo would be needed.\n'
                return 0
                ;;
            (*) printf "unkown option: '%s'\n" "$1" ; return 1 ;;
        esac
        shift
    done

    if (( ${#argv} > 1 )) ; then
        printf 'Too many arguments %s\n' "${#argv}"
        return 1
    fi

    key="${1%%\=*}" ;  val="${1#*\=}"
    if (( EUID == 0 )) && (( only == 0 )); then
        alias -- "${key}=${val}"
    elif (( EUID > 0 )) ; then
        (( multi > 0 )) && val="${val// ; / ; sudo }"
        alias -- "${key}=sudo ${val}"
    fi

    return 0
}


# tlog/llog: tail/less /v/l/{syslog,messages} and use sudo if necessary
callwithsudoifnecessary_first() {
  cmd=$1; shift
  for file do
    if [[ -f $file ]]; then
      if [[ -r $file ]]; then
	$=cmd $file
      else
	sudo $=cmd $file
      fi
      return
    fi
  done
}
# Call command ($1) with all arguments, and use sudo if any file argument is not readable
# This is useful for: `tf ~l/squid3/*.log`
callwithsudoifnecessary_all() {
  cmd=$1; shift
  for file do
    if [[ -f $file ]] && ! [[ -r $file ]]; then
      sudo $=cmd "$@"
      return $?
    fi
  done
  # all readable:
  $=cmd "$@"
}
tlog() {
  callwithsudoifnecessary_first "tail -F" /var/log/syslog /var/log/messages
}
llog() {
  callwithsudoifnecessary_first less /var/log/syslog /var/log/messages
}
tf() {
  callwithsudoifnecessary_all "tail -F" "$@"
}


# Generic aliases
# Display 20 biggest files/dirs
dusch() {
  # setopt extendedglob bareglobqual
  du -sch ${~^@:-"*"}(D) | sort -rh | head -n21
}
alias dusch='noglob dusch'
alias phwd='print -rP %m:%/'

alias dL='dpkg -L'


# Source local rc file if any {{{1
[ -f ~/.zshrc.local ] && source ~/.zshrc.local


# OpenVZ container: change to previous directory (via dirstack plugin) {{{1
if [[ -r /proc/user_beancounters ]] && [[ ! -d /proc/bc ]] && (( $plugins[(I)dirstack] )) && (( $#dirstack )); then
  popd
fi

# Stop profiling
# unsetopt xtrace
# exec 2>&3 3>&-

true # return code 0
