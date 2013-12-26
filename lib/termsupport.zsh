#usage: title short_tab_title looooooooooooooooooooooggggggg_windows_title
#http://www.faqs.org/docs/Linux-mini/Xterm-Title.html#ss3.1
#Fully support screen, iterm, and probably most modern xterm and rxvt
#Limited support for Apple Terminal (Terminal can't set window or tab separately)
# NOTE: '${(%):-%~}' => short PWD, with named dirs
function title {
  [ "$DISABLE_AUTO_TITLE" != "true" ] || return
  [[ -z $2 ]] && 2=$1
  1=${(pj: :)${(f)1}}
  2=${(pj: :)${(f)2}}
  # 1="1:$1"; 2="2:$2"
  1=${1:gs/%/%%/}
  2=${2:gs/%/%%/}
  # echo "title:1:$1" ; echo "title:2:$2"

  # Append user@host if on ssh
  if [[ -n $SSH_CLIENT  ]]; then
    # export it (useful in Vim's titlestring)
    export TERM_USERATHOST_SUFFIX=" (${(%):-%n@%m})"
    2+=$TERM_USERATHOST_SUFFIX
  fi

  # Container prefix/suffix: {{{
  local PREFIX WINSUFFIX RELPWD
  # Get OpenVZ container ID (/proc/bc is only on the host):
  if [[ -r /proc/user_beancounters ]]; then
    if [[ ! -d /proc/bc ]]; then
      # container
      PREFIX="[$(hostname)#$(sed -n 3p /proc/user_beancounters | cut -f1 -d: | tr -d '[:space:]')] "
      WINSUFFIX=" (${(%):-%~})"
    elif [[ $(pwd -P) == /var/lib/vz/private/[0-9]* ]]; then
      # HN, in container dir
      RELPWD=${$(pwd -P)#/var/lib/vz/private/}
      WINSUFFIX=" (HN:${RELPWD%%/*}~${RELPWD##[[:digit:]]##/#})"
    fi
  fi
  WINSUFFIX=${WINSUFFIX:- [${${(%):-%~}:gs/%/%%/}]}
  1=$PREFIX$1
  2=$PREFIX$2$WINSUFFIX
  # }}}

  if [[ $TERM == screen* ]]; then
    local rename_window=0
    if (($+TMUX)); then
      # tmux window name (escape sequence also for screen hardstatus, but irrelevant here)
      # Available as #W in tmux, defaults to current command
      # We use the window_name (CMD with CWD)

      # get option value (fallback for tmux 1.6)
      local tmux_auto_rename=$(tmux show-window-options -t $TMUX_PANE -v automatic-rename 2>/dev/null) || $(tmux show-window-options -t $TMUX_PANE | grep '^automatic-rename' | cut -f2 -d\ )
      if [[ $tmux_auto_rename != "off" ]]; then
        # auto-rename on (default)
        rename_window=1
      else
        # auto-rename off (is the case after first own rename)
        local tmux_cur_title="$(tmux display-message -t $TMUX_PANE -p '#W')"
        # Look for U+FEFF at the end
        if [[ $tmux_cur_title[-1] == "﻿" ]]; then
          # still our autoset value (marker or same value), change it:
          rename_window=1
        fi
      fi
    else
      # no tmux, or not exported ("vzctl enter")
      # TODO: detect/handle manual rename here
      #       might use set-environment, but would require $TMUX/tmux
      #       could use a mark (invisible char, "﻿"), but needs tmux to read the current title
      rename_window=1
    fi
    if [[ $rename_window == 1 ]]; then
      # Rename window and add mark (invisible space, U+FEFF)
      print -Pn $'\ek$1﻿\e\\'
      export _tmux_title_is_auto_set=1  # export for sub-shells / Vim
    else
      export _tmux_title_is_auto_set=0
    fi

    # Term title (available as #T in tmux)
    print -Pn $'\e]2;$2\a'
    print -Pn $'\e]1;$1\a'

  elif [[ $TERM == xterm* ]] || [[ $TERM == rxvt* ]] || [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    # ESC]0;stringBEL -- Set icon name and window title to string
    # ESC]1;stringBEL -- Set icon name to string
    # ESC]2;stringBEL -- Set window title to string
    print -Pn $'\e]2;$2\a' # set window name
    print -Pn $'\e]1;$1\a' # set icon (=tab) name (will override window name on broken terminal)
  fi
}

ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<…<%~%<<_" #15 char left truncated PWD
ZSH_THEME_TERM_TITLE_IDLE="%~_"

# Appears when you have the prompt
function omz_termsupport_precmd {
  title ${(%)ZSH_THEME_TERM_TAB_TITLE_IDLE} ${(%)ZSH_THEME_TERM_TITLE_IDLE}
}

# Appears at the beginning (and during) of command execution
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

  # Get the cmd out of what was typed:
  # local CMD=${typed[(wr)^(*=*|sudo|ssh|-*)]} #cmd name only, or if this is sudo or ssh, the next cmd
  # Get the index of the first item not matching the list
  local cmd_index=${typed[(wi)^(*=*|sudo|ssh|-*|;|\[*)]} # cmd name only, or if this is sudo or ssh, the next cmd
  # printf '%s\n' $typed; read
  local CMD="$typed[$cmd_index]"

  # For special cases like "make", append the arg
  local -a cmds_with_arg
  cmds_with_arg=(make man ve)
  if (( $#CMD <= 4 )); then
    CMD+=" $typed[$cmd_index+1]"
  elif (( ${cmds_with_arg[(i)$CMD]} <= ${#cmds_with_arg} )); then
    CMD+=" $typed[$cmd_index+1]"
  fi
  # local window_name="$CMD [${(%):-%~}]"
  local window_name="$CMD"
  local window_title="${typed}"

  title $window_name $window_title # let the terminal app itself handle cropping
}

autoload -U add-zsh-hook
add-zsh-hook precmd  omz_termsupport_precmd
add-zsh-hook preexec omz_termsupport_preexec
