## fixme, i duplicated this in xterms - oops
function title {
  local SUFFIX RELPWD
  if [[ $TERM == screen* ]]; then
    # Get OpenVZ container ID (/proc/bc is only on the host):
    if [[ -r /proc/user_beancounters ]]; then
      if [[ ! -d /proc/bc ]]; then
        # container
        SUFFIX=" [$(hostname)#$(sed -n 3p /proc/user_beancounters | cut -f1 -d: | tr -d '[:space:]'):$PWD]"
      elif [[ $(pwd -P) == /var/lib/vz/private/[0-9]* ]]; then
        # HN, in container dir
        RELPWD=${$(pwd -P)#/var/lib/vz/private/}
        SUFFIX=" [HN:${RELPWD%%/*}~${RELPWD##[[:digit:]]##/#}]"
      fi
    fi
    # Use these two for GNU Screen:
    print -nR $'\033k'"${(f)*}$CTID${SUFFIX- [$PWD]}"$'\033'\\\
    # xterm title: gets updated via screen hardstatus
    # print -nR $'\033]0;'${(f)2}$'\a'
  elif [[ $TERM == xterm* || $TERM == "rxvt" ]]; then
    # Use this one instead for XTerms:
    print -nR $'\033]0;'"${(f)*} [$PWD]"$'\a'
  fi
}

function precmd {
  title zsh # "$PWD"
}

function preexec {
  emulate -L zsh
  local -a cmd; cmd=(${(z)1})
	# when the command starts with "fg", use the current's job text
	local jobspec
	local -a newcmd
	if [[ $cmd[1] == fg ]] ; then
		# set cmd to jobtext for first argument. If there are more, add "(+x jobs)"
		jobspec=${cmd[2]:-%+} ;
		newcmd=(${(z)${jobtexts[$jobspec]}})
		if (( ${+cmd[3]} )) ; then
			newcmd+=(" (+ $(( ${#cmd}-2 )) jobs)")
		fi
	elif [[ $cmd[1] == %* ]] && (( $+jobtexts[$cmd[1]] )); then
		jobspec=$cmd[1]
		newcmd=(${(z)${jobtexts[$jobspec]}})
	fi
	(( $#newcmd )) && cmd=($newcmd)
  title $cmd[1]:t "$cmd[2,-1]"
}

function zsh_stats() {
  history | awk '{print $2}' | sort | uniq -c | sort -rn | head
}

function uninstall_oh_my_zsh() {
  /bin/sh $ZSH/tools/uninstall.sh
}

function upgrade_oh_my_zsh() {
  /bin/sh $ZSH/tools/upgrade.sh
}

function take() {
  mkdir -p $1
  cd $1
}

function extract() {
    unset REMOVE_ARCHIVE
    
    if test "$1" = "-r"; then
        REMOVE=1
        shift
    fi
  if [[ -f $1 ]]; then
    case $1 in
      *.tar.bz2) tar xvjf $1;;
      *.tar.gz) tar xvzf $1;;
      *.tar.xz) tar xvJf $1;;
      *.tar.lzma) tar --lzma -xvf $1;;
      *.bz2) bunzip $1;;
      *.rar) unrar $1;;
      *.gz) gunzip $1;;
      *.tar) tar xvf $1;;
      *.tbz2) tar xvjf $1;;
      *.tgz) tar xvzf $1;;
      *.zip) unzip $1;;
      *.Z) uncompress $1;;
      *.7z) 7z x $1;;
      *) echo "'$1' cannot be extracted via >extract<";;
    esac

    if [[ $REMOVE_ARCHIVE -eq 1 ]]; then
        echo removing "$1";
        /bin/rm "$1";
    fi

  else
    echo "'$1' is not a valid file"
  fi
}

