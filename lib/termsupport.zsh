#usage: title short_tab_title looooooooooooooooooooooggggggg_windows_title
#http://www.faqs.org/docs/Linux-mini/Xterm-Title.html#ss3.1
#Fully support screen, iterm, and probably most modern xterm and rxvt
#Limited support for Apple Terminal (Terminal can't set window or tab separately)
function title {
  [ "$DISABLE_AUTO_TITLE" != "true" ] || return
  1=${(pj: :)${(f)1}}
  2=${(pj: :)${(f)2}}
  # echo "title:1:$1" ; echo "title:2:$2"
  if [[ $TERM == screen* ]]; then 
    local PREFIX SUFFIX RELPWD
    # Get OpenVZ container ID (/proc/bc is only on the host):
    if [[ -r /proc/user_beancounters ]]; then
      if [[ ! -d /proc/bc ]]; then
        # container
        PREFIX="[$(hostname)#$(sed -n 3p /proc/user_beancounters | cut -f1 -d: | tr -d '[:space:]')] "
        SUFFIX=" ($PWD)"
      elif [[ $(pwd -P) == /var/lib/vz/private/[0-9]* ]]; then
        # HN, in container dir
        RELPWD=${$(pwd -P)#/var/lib/vz/private/}
        SUFFIX=" (HN:${RELPWD%%/*}~${RELPWD##[[:digit:]]##/#})"
      fi
    fi
    SUFFIX=${SUFFIX:- (${PWD/#$HOME/\~})}
    print -Pn $'\ek$PREFIX$2$SUFFIX\e\\' #set screen hardstatus, usually truncated at 20 chars
  elif [[ $TERM == xterm* ]] || [[ $TERM == rxvt* ]] || [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    print -Pn $'\e]0;$2 (%~)\a' #set window name
    print -Pn $'\e]1;$1\a' #set icon (=tab) name (will override window name on broken terminal)
  fi
}

ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<..<%~%<<" #15 char left truncated PWD
ZSH_THEME_TERM_TITLE_IDLE="%n@%m"

#Appears when you have the prompt
function omz_termsupport_precmd {
  title $ZSH_THEME_TERM_TAB_TITLE_IDLE $ZSH_THEME_TERM_TITLE_IDLE
}

#Appears at the beginning of (and during) of command execution
function omz_termsupport_preexec {
  emulate -L zsh
  setopt extended_glob
  local -a typed; typed=(${(z)1}) # split what the user has typed into words using shell parsing
  # Resolve jobspecs, e.g. when "fg" or "%-" is used:
  local jobspec
  local -a newtyped
  if [[ $typed[1] == fg ]] ; then
    # Set typed to jobtext for first argument. If there are more, add "(+x jobs)".
    # Use jobspec from $typed[2] if not empty and it does not start with "[;&|]" (starting next command)
    if [[ -n "$typed[2]" ]] && [[ $typed[2] != [\;\&\|]* ]]; then
      jobspec=${typed[2]}
    else
      jobspec='%+'
    fi
    newtyped=(${(z)${jobtexts[$jobspec]}})
    # XXX: ???
    if (( ${+typed[3]} )) ; then
      newtyped+=(" (+ $(( ${#typed}-2 )) jobs)")
    fi
  elif [[ $typed[1] == %* ]] && (( $+jobtexts[$typed[1]] )); then
    jobspec=$typed[1]
    newtyped=(${(z)${jobtexts[$jobspec]}})
  fi
  (( $#newtyped )) && typed=($newtyped)
  local CMD=${typed[(wr)^(*=*|sudo|ssh|-*)]} #cmd name only, or if this is sudo or ssh, the next cmd
  title "$CMD" "${typed:gs/%/%%/}" # let the terminal app itself handle cropping
}

autoload -U add-zsh-hook
add-zsh-hook precmd  omz_termsupport_precmd
add-zsh-hook preexec omz_termsupport_preexec
