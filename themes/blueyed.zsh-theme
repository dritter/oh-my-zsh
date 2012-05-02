# blueyed's theme for zsh
#
# Features:
#  - color hostnames according to its hashed value (see color_for_host)
#
# Origin:
#  - Based on http://kriener.org/articles/2009/06/04/zsh-prompt-magic
#  - Some Git ideas from http://eseth.org/2010/git-in-zsh.html (+vi-git-stash, +vi-git-st, ..)
#
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
    # Start profiling, via http://stackoverflow.com/questions/4351244/can-i-profile-my-zshrc-zshenv
      # PS4='+$(date "+%s:%N") %N:%i> '
      # exec 3>&2 2>/tmp/startlog.$$
      # setopt xtrace

    # FYI: list of colors: cyan, white, yellow, magenta, black, blue, red, default, grey, green
    local -h exitstatus=$? # we need this, because %? gets not expanded in here yet. e.g. via ${(%)%?}.
    local -h    normtext="%{$fg_no_bold[green]%}"
    local -h      hitext="%{$fg_bold[magenta]%}"
    local -h        gray="%{$fg_bold[black]%}"
    local -h        blue="%{$fg_no_bold[blue]%}"
    local -h     cwdtext="%{$fg_bold[white]%}"
    local -h   nonrwtext="%{$fg_no_bold[red]%}"
    local -h    roottext="%{$fg_bold[green]%}"
    local -h     invtext="%{$fg_bold[cyan]%}"
    local -h   alerttext="%{$fg_no_bold[red]%}"
    local -h   lighttext="%{$fg_no_bold[white]%}"
    local -h   darkdelim="$gray"
    local -h bracket_open="${darkdelim}["
    local -h bracket_close="${darkdelim}]"

    local -h prompt_cwd prompt_vcs cwd
    local -ah prompt_extra rprompt_extra

    if ! vcs_info 'prompt' &> /dev/null; then
        # No vcs_info available, only set cwd
        prompt_vcs=""
        cwd=$PWD
    else
        [[ -n $vcs_info_msg_0_ ]] && prompt_vcs="${PR_RESET}$vcs_info_msg_0_ "
        cwd="${vcs_info_msg_1_%.}"
        rprompt_extra+=("${vcs_info_msg_2_}")

        # Check if $cwd (from vcs_info) is in $PWD - which may not be the case with symbolic links
        # (e.g. some SVN symlink in a CVS repo)
        if [[ ${cwd#$PWD} = $cwd ]]; then
            cwd=$PWD
        fi
    fi

    # Highlight symbolic links in $cwd
    local ln_color=${${(ps/:/)LS_COLORS}[(r)ln=*]#ln=}
    # Fallback to default, if "target" is used
    [ "$ln_color" = "target" ] && ln_color="01;36"
    [[ -z $ln_color ]] && ln_color=${fg_bold[cyan]} || ln_color="%{"$'\e'"[${ln_color}m%}"
    local colored="/" cur color i
    for i in ${(ps:/:)${cwd}}; do
        if [[ -h "$cur/$i" ]]; then
            color=$ln_color
            colored+="${color}$i${cwdtext}/"
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
        cwd="${nonrwtext}${cleancwd}"
    fi

    # TODO: if cwd is too long for COLUMNS-restofprompt, cut longest parts of cwd
    #prompt_cwd="${hitext}%B%50<..<${cwd}%<<%b"
    prompt_cwd="$cwdtext${cwd}"

    # http_proxy defines color of "@" between user and host
    if [[ -n $http_proxy ]] ; then
        prompt_at="${hitext}@"
    else
        prompt_at="${normtext}@"
    fi

    local -h     user="%(#.$roottext.$normtext)%n"
    # Color host name according to its hashed value. Use bold color if connected through SSH.
    if [ -n "$SSH_CLIENT" ] ; then
        local -h     host="%{${fg_bold[$(color_for_host)]}%}%m"
    else
        local -h     host="%{${fg_no_bold[$(color_for_host)]}%}%m"
    fi

    # Debian chroot
    if [[ -z $debian_chroot ]] && [[ -r /etc/debian_chroot ]]; then
        debian_chroot="$(</etc/debian_chroot)"
    fi
    if [[ -n $debian_chroot ]]; then
        prompt_extra+=("${normtext}(dch:$debian_chroot)")
    fi
    # OpenVZ container ID (/proc/bc is only on the host):
    if [[ -r /proc/user_beancounters && ! -d /proc/bc ]]; then
        prompt_extra+=("${normtext}[CTID:$(sed -n 3p /proc/user_beancounters | cut -f1 -d: | tr -d '[:space:]')]")
    fi
    if [[ -n $VIRTUAL_ENV ]]; then
        prompt_extra+=("$normtext(venv:$(basename $VIRTUAL_ENV))")
    fi

    local -h disp
    if [ $exitstatus -ne 0 ] ; then
        disp="es:$exitstatus"
        if [ $exitstatus -gt 128 -a $exitstatus -lt 163 ] ; then
            disp+=" (SIG$signals[$exitstatus-127])"
        fi
        prompt_extra+=("${bracket_open}${alerttext}${disp}${bracket_close}")
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
        [[ -z $jobstatus ]] || prompt_extra+=("${bracket_open}${lighttext}jobs:${jobstatus}${bracket_close}")
    fi

    # local -h    prefix="%{$normtext%}❤ "

    # whitespace and reset for extra prompts if non-empty:
    [[ -n $prompt_extra ]]  &&  prompt_extra=" ${(j: :)prompt_extra}$PR_RESET"
    [[ -n $rprompt_extra ]] && rprompt_extra="${(j: :)rprompt_extra}$PR_RESET "

    # Assemble prompt:
    local -h  histnr="${normtext}!${gray}%!"
    local -h    time="${normtext}%*"
    local -h rprompt="$rprompt_extra$histnr $time${PR_RESET}"
    local -h prompt="${user}${prompt_at}${host} ${prompt_cwd}${ret_status}$prompt_extra"
    # right trim:
    prompt="${prompt%% #} "

    # Attach $rprompt to $prompt, aligned to $COLUMNS (terminal width)
    local -h TERMWIDTH=$((${COLUMNS}-1))
    local -h rprompt_len=${#${(%)"$(_strip_escape_codes $rprompt)"}}
    local -h prompt_len=${#${(%)"$(_strip_escape_codes $prompt)"}}
    PR_FILLBAR="$gray\${(l:(($TERMWIDTH - ( ($rprompt_len + $prompt_len) % $TERMWIDTH))):: :)}"

    PROMPT="${prompt}${PR_FILLBAR}${rprompt}
$prompt_vcs%{%(#.${fg_bold[red]}.${fg_bold[green]})%}%# ${PR_RESET}"

    # End profiling
        # unsetopt xtrace
        # exec 2>&3 3>&-
}


# register vcs_info hooks
zstyle ':vcs_info:git*+set-message:*' hooks git-stash git-st

# Show count of stashed changes
function +vi-git-stash() {
    local -a stashes

    [[ $1 == 0 ]] || return # do this only once for vcs_info_msg_0_.

    if [[ -s ${hook_com[base]}/.git/refs/stash ]] ; then
        stashes=$(git stash list 2>/dev/null | wc -l)
        hook_com[misc]+=" $bracket_open$hitext${stashes} stashed$bracket_close"
    fi
}

# Show remote ref name and number of commits ahead-of or behind
function +vi-git-st() {
    local ahead behind remote
    local -a gitstatus

    [[ $1 == 0 ]] || return # do this only once vcs_info_msg_0_.

    # Are we on a remote-tracking branch?
    remote=${$(git rev-parse --verify ${hook_com[branch]}@{upstream} \
        --symbolic-full-name 2>/dev/null)/refs\/remotes\/}

    local_branch=${hook_com[branch]}
    # make branch name bold if not "master"
    [[ $local_branch == "master" ]] \
        && branch_color="%{$fg_no_bold[blue]%}" \
        || branch_color="%{$fg_bold[blue]%}"

    if [[ -z ${remote} ]] ; then
        hook_com[branch]="${branch_color}${local_branch}"
        return
    else
        # for git prior to 1.7
        # ahead=$(git rev-list origin/${hook_com[branch]}..HEAD | wc -l)
        ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
        (( $ahead )) && gitstatus+=( "${normtext}+${ahead}" )

        # for git prior to 1.7
        # behind=$(git rev-list HEAD..origin/${hook_com[branch]} | wc -l)
        behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)
        (( $behind )) && gitstatus+=( "${alerttext}-${behind}" )

        remote=${remote%/$local_branch}

        # abbreviate "master@origin" (common/normal)
        if [[ $remote == "origin" ]] ; then
          remote=o
          [[ $local_branch == "master" ]] && local_branch="m"
        else
          remote_color="%{$fg_bold[blue]%}"
        fi

        hook_com[branch]="${branch_color}${local_branch}$remote_color@${remote}"
        [[ -n $gitstatus ]] && hook_com[branch]+="$bracket_open$normtext${(j:/:)gitstatus}$bracket_close"
    fi
}

# Vim mode indicator {{{1
# Taken from the vi-mode plugin, but without `bindkey -v`.
function zle-line-init zle-keymap-select {
  zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

# if mode indicator wasn't setup by theme, define default
if [[ "$MODE_INDICATOR" == "" ]]; then
  MODE_INDICATOR="%{$fg_bold[red]%}<%{$fg_no_bold[red]%}<<%{$reset_color%}"
fi

function vi_mode_prompt_info() {
  echo "${${KEYMAP/vicmd/$MODE_INDICATOR}/(main|viins)/}"
}

# Assemble RPS1 (different from rprompt, which is right-aligned in PS1)
# Do not do this when in a midnight commander subshell.
if ! grep -q '^mc\b' /proc/$PPID/cmdline; then
    RPS1_list=('$(vi_mode_prompt_info)')

    # Distribution
    local -h distrotext="%{$fg_bold[black]%}"
    RPS1_list+=("$distrotext$(get_distro)")

    RPS1_list=("${(@)RPS1_list:#}") # remove empty elements (after ":#")
    RPS1="${(j: :)RPS1_list}$PR_RESET"
fi

color_for_host() {
    colors=(cyan white yellow magenta blue default green)
    host=$(hostname -f 2>/dev/null || hostname)
    echo $(hash_value_from_list $host "$colors")
}

# Hash the given value to an item from the given list.
hash_value_from_list() {
    value=$1
    list=(${(s: :)2})
    index=$(( $(sumcharvals $value) % $#list + 1 ))
    echo $list[$index]
}

# vcs_info styling formats {{{1
# XXX: %b is the whole path for CVS, see ~/src/b2evo/b2evolution/blogs/plugins
FMT_BRANCH=" %{$fg_no_bold[blue]%}↳ %{$fg_no_bold[blue]%}%s:%b%{$fg_bold[blue]%}%u%{$fg_bold[magenta]%}%c" # e.g. master¹²
FMT_ACTION="%{$fg[cyan]%}(%a%)"   # e.g. (rebase-i)
FMT_PATH="%R%{$fg[yellow]%}/%S"   # e.g. ~/repo/subdir

# zstyle ':vcs_info:*:prompt:*' get-revision true # for %8.8i
zstyle ':vcs_info:*:prompt:*' unstagedstr '¹'  # display ¹ if there are unstaged changes
zstyle ':vcs_info:*:prompt:*' stagedstr '²'    # display ² if there are staged changes
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH} ${FMT_ACTION}" "${FMT_PATH}" "%m"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}"               "${FMT_PATH}" "%m"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""                            "%~"          ""
zstyle ':vcs_info:*:prompt:*' max-exports 3

# check-for-changes can be really slow.
# you should disable it, if you work with large repositories
zstyle ':vcs_info:*:prompt:*' check-for-changes true

#  vim: set ft=zsh ts=4 sw=4 et:
