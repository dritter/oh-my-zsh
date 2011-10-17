# Based on http://kriener.org/articles/2009/06/04/zsh-prompt-magic
# TODO: setup $prompt_cwd in chpwd hook only (currently adding the hook causes infinite recursion via vcs_info)

autoload -U add-zsh-hook
autoload -Uz vcs_info

setopt prompt_subst

PR_RESET="%{${reset_color}%}";

# Remove any ANSI color codes (via www.commandlinefu.com/commands/view/3584/)
_strip_escape_codes() {
    echo "${(%)1}" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})?)?[m|K]//g"
}

add-zsh-hook precmd prompt_blueyed_precmd
prompt_blueyed_precmd () {
    local -h exitstatus=$? # we need this, because %? gets not expanded in here yet. e.g. via ${(%)%?}.
    local -h      hitext="%{$fg_bold[green]%}"
    local -h     invtext="%{$fg_bold[cyan]%}"
    local -h    normtext="%{$fg_no_bold[green]%}"
    local -h prompt_cwd prompt_vcs
    local -h cwd

    if ! vcs_info 'prompt' &> /dev/null; then
        # No vcs_info available, only set cwd
        prompt_vcs=""
        cwd=$PWD
    else
        prompt_vcs="${PR_RESET}$vcs_info_msg_0_"
        cwd="${vcs_info_msg_1_%.}"

        # Check if $cwd (from vcs_info) is in $PWD - which may not be the case with symbolic links
        # (e.g. some SVN symlink in a CVS repo)
        if [[ ${cwd#$PWD} = $cwd ]]; then
            cwd=$PWD
        fi
    fi

    # Highlight symbolic links in $cwd
    # typeset -A color_map
    # color_map=("${(s:=:)${LS_COLORS//:/=}}" '')
    local ln_color=${${(ps/:/)LS_COLORS}[(r)ln=*]#ln=}
    # fallback to default, if "target" is used
    [ "$ln_color" = "target" ] && ln_color="01;36"
    [[ -z $ln_color ]] && ln_color=${fg_bold[cyan]} || ln_color="%{"$'\e'"[${ln_color}m%}"
    local colored="/" cur color i
    for i in ${(ps:/:)${cwd}}; do
            if [[ -h "$cur/$i" ]]; then
                    color=$ln_color
                    colored+="${color}→$i${hitext}/"
            else
                    colored+="$i/"
            fi
            cur+="/$i"
    done
    # Remove trailing slash, if not in root
    if [[ ${#colored} > 1 ]]; then colored=${colored%%/}; fi
    cwd="${colored/#$HOME/~}"

    # TODO: test for not existing, too (in case dir gets deleted from somewhere else)
    if [[ ! -w $PWD ]]; then
            local cleancwd="$(_strip_escape_codes "$cwd")"
            cwd="${fg_bold[red]}${cleancwd}"
    fi

    # TODO: if cwd is too long for COLUMNS-restofprompt, cut longest parts of cwd
    #prompt_cwd="${hitext}%B%50<..<${cwd}%<<%b"
    prompt_cwd="${hitext}${cwd}"

    # http_proxy defines color of "@" between user and host
    # TODO: use $prompt_extra instead?!
    if [[ -n $http_proxy ]] ; then
        prompt_at="${hitext}@"
    else
        prompt_at="${normtext}@"
    fi

    # via http://www.zsh.org/mla/users/2005/msg00863.html
    local -h    normtext="%{$fg_no_bold[green]%}"
    local -h      hitext="%{$fg_bold[green]%}"
    local -h   alerttext="%{$fg_bold[red]%}"
    local -h   lighttext="%{$fg_no_bold[white]%}"
    local -h     invtext="%{$fg_bold[cyan]%}"

    local -h     user="%(#.$alerttext.$normtext)%n"
    if [ -n "$SSH_TTY" ] || [ "$(who am i | cut -f2  -d\( | cut -f1 -d:)" != "" ]; then
        local -h     host="${hitext}%m"
    else
        local -h     host="${normtext}%m"
    fi
    local -h   histnr="${normtext}!${invtext}%!"
    local -h     time="${normtext}%*"

    local -h bracket_open="${lighttext}["
    local -h bracket_close="${lighttext}]"
    local -h brace_open_cwd="%(#.$alerttext.$normtext){"
    local -h brace_close_cwd="%(#.$alerttext.$normtext)}${normtext}"

    local -h prompt_extra
    # $debian_chroot:
    if [[ -n "$debian_chroot" ]]; then
        prompt_extra+="${alerttext}(dch:$debian_chroot) "
    fi
    # OpenVZ container ID (/proc/bc is only on the host):
    if [[ -r /proc/user_beancounters && ! -d /proc/bc ]]; then
        prompt_extra+="${normtext}[CTID:$(sed -n 3p /proc/user_beancounters | cut -f1 -d: | tr -d '[:space:]')] "
    fi

    # information about release, taken and adopted from byobu:
    if ! (( $+DISTRO )) ; then
      if [ -r "/etc/issue" ]; then
        # lsb_release is *really* slow;  try to use /etc/issue first
        issue=$(grep -m1 "^[A-Za-z]" /etc/issue)
        case "$issue" in
          Ubuntu*) DISTRO=${${${issue%%\(*}%%\\*}%% } ;;
          Debian*) DISTRO="Debian $(</etc/debian_version)" ;;
          *) if [ -r /etc/SuSE-release ] ; then
              # TODO: use ${//}
              DISTRO="SuSE $(fgrep VERSION /etc/SuSE-release | cut -f2 -d= | tr -d ' ').$(fgrep PATCHLEVEL /etc/SuSE-release | cut -f2 -d= | tr -d ' ')"
            elif [ -r /etc/redhat-release ] ; then
              DISTRO=$(</etc/redhat-release)
              DISTRO=${DISTRO/Red Hat Enterprise Linux Server/RHEL}
              DISTRO=${DISTRO/ Linux/} # for CentOS
              DISTRO=${DISTRO/release /}
              DISTRO=${DISTRO/ \(*/}
            elif ! which lsb_release >/dev/null 2>&1; then
              DISTRO=$(echo "$issue" | sed "s/ [^0-9]* / /" | awk '{print $1 " " $2}')
            fi
          ;;
        esac
      fi

      if ! (( $+DISTRO )) && which lsb_release >/dev/null 2>&1; then
        # If lsb_release is available, use it
        r=$(lsb_release -s -d)
        case "$r" in
          Ubuntu*.*.*)
            # Use the -d if an Ubuntu LTS
            DISTRO="$r"
          ;;
          *)
            # But for other distros the description
            # is too long, so build from -i and -r
            DISTRO="${(f)$(lsb_release -s -i -r)}"
            DISTRO=${DISTRO/RedHatEnterpriseServer/RHEL}
          ;;
        esac
      fi
      (( $+DISTRO )) || DISTRO="unknown"
      DISTRO+=" ($(uname -m))"
    fi
    if [[ -n $DISTRO ]]; then
      prompt_extra+="[${normtext}$DISTRO] "
    fi
    prompt_extra+="${PR_RESET}"

    #local ret_status="%(?:: ${bracket_open}${alerttext}es:%?${bracket_close})"
    local -h ret_status disp
    if [ $exitstatus -ne 0 ] ; then
        disp="es:$exitstatus"
        if [ $exitstatus -gt 128 -a $exitstatus -lt 163 ] ; then
            disp+=" (SIG$signals[$exitstatus-127])"
        fi
        ret_status="${bracket_open}${alerttext}${disp}${bracket_close}"
    fi

    # Running and suspended jobs, parsed via $jobstates
    local -h jobstatus=""
    if [ ${#jobstates} -ne 0 ] ; then
        local -h suspended=0 running=0 j
        for j in $jobstates; do
            if [[ $j[1,9] == "suspended" ]] ; then (( suspended++ )) ; continue; fi
            if [[ $j[1,7] == "running" ]] ; then (( running++ )) ; continue; fi
            # "done" is ignored
        done
        [[ $suspended -gt 0 ]] && jobstatus+="${hitext}${suspended}${lighttext}s"
        [[ $running -gt 0 ]] && jobstatus+="${hitext}${running}${lighttext}r"
        [[ -z $jobstatus ]] || jobstatus="${bracket_open}${lighttext}jobs:${jobstatus}${bracket_close}"
    fi

    local -h    prefix="%{$normtext%}❤ "

    # Assemble prompt:
    local -h rprompt=" $histnr $time${PR_RESET}"
    local -h prompt="${user}${prompt_at}${host} ${brace_open_cwd} ${prompt_cwd} ${brace_close_cwd} ${prompt_extra}${ret_status}${jobstatus}"
    # right trim:
    prompt=${prompt%% #}

    # Attach $rprompt to $prompt, aligned to $COLUMNS (terminal width)
    local -h TERMWIDTH=$((${COLUMNS}-1))
    local -h rprompt_len=${#${(%)"$(_strip_escape_codes $rprompt)"}}
    local -h prompt_len=${#${(%)"$(_strip_escape_codes $prompt)"}}
    PR_FILLBAR="\${(l.(($TERMWIDTH - ( ($rprompt_len + $prompt_len) % $TERMWIDTH))).)}"

    PROMPT="${prompt}${PR_FILLBAR}${rprompt}
${prompt_vcs}%# ${PR_RESET}"
}


# set formats
# XXX: %b is the whole path for CVS, see ~/src/b2evo/b2evolution/blogs/plugins
FMT_BRANCH="%{$fg_no_bold[white]%}(%s)%{$fg[green]%}%b%u%c" # e.g. master¹²
FMT_ACTION="%{$fg[cyan]%}(%a%)"   # e.g. (rebase-i)
FMT_PATH="%R%{$fg[yellow]%}/%S"   # e.g. ~/repo/subdir

# check-for-changes can be really slow.
# you should disable it, if you work with large repositories
zstyle ':vcs_info:*:prompt:*' check-for-changes true
zstyle ':vcs_info:*:prompt:*' unstagedstr '¹'  # display ¹ if there are unstaged changes
zstyle ':vcs_info:*:prompt:*' stagedstr '²'    # display ² if there are staged changes
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH}${FMT_ACTION} " "${FMT_PATH}"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH} "              "${FMT_PATH}"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""                             "%~"


#  vim: set ft=zsh ts=4 sw=4 et:
