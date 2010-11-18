## fixme, i duplicated this in xterms - oops
function title {
  if [[ $TERM == screen* ]]; then
    # Get OpenVZ container ID (/proc/bc is only on the host):
    if [[ -f /proc/user_beancounters && ! -d /proc/bc ]]; then
      CTID=" [$(hostname)#$(sed -n 3p /proc/user_beancounters | cut -f1 -d: | tr -d '[:space:]')]"
    fi
    # Use these two for GNU Screen:
    print -nR $'\033k'"$*$CTID"$'\033'\\\
    # xterm title: gets updated via screen hardstatus
    # print -nR $'\033]0;__USED__:'$2$'\a'
  elif [[ $TERM == "xterm" || $TERM == "rxvt" ]]; then
    # Use this one instead for XTerms:
    print -nR $'\033]0;'"$*"$'\a'
  fi
}

function precmd {
  title zsh "$PWD"
}

function preexec {
  emulate -L zsh
  local -a cmd; cmd=(${(z)1})
	# when the command starts with "fg", use the current's job text
	if [[ $cmd[1] == fg ]] ; then
		# set cmd to jobtext for first argument. If there are more, add "(+x jobs)"
		local -a newcmd
		newcmd=(${(z)${jobtexts[${cmd[2]:-%+}]}})
		if (( ${+cmd[3]} )) ; then
			newcmd+=(" (+ $(( ${#cmd}-2 )) jobs)")
		fi
		cmd=($newcmd)
	fi
  title $cmd[1]:t "$cmd[2,-1]"
}

function remote_console() {
  /usr/bin/env ssh $1 "( cd $2 && ruby script/console production )"
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

function tab() {
  osascript 2>/dev/null <<EOF
    tell application "System Events"
      tell process "Terminal" to keystroke "t" using command down
    end
    tell application "Terminal"
      activate
      do script with command "cd \"$PWD\"; $*" in window 1
    end tell
EOF
}

function take() {
  mkdir -p $1
  cd $1
}

function tm() {
  cd $1
  mate $1
}

# To use: add a .lighthouse file into your directory with the URL to the
# individual project. For example:
# https://rails.lighthouseapp.com/projects/8994
# Example usage: http://screencast.com/t/ZDgwNDUwNT
open_lighthouse_ticket () {
  if [ ! -f .lighthouse-url ]; then
    echo "There is no .lighthouse file in the current directory..."
    return 0;
  else
    lighthouse_url=$(cat .lighthouse-url);
    echo "Opening ticket #$1";
    `open $lighthouse_url/tickets/$1`;
  fi
}

alias lho='open_lighthouse_ticket'
