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
    [[ -n $commands[gsed] ]] && sed=gsed || sed=sed # gsed with coreutils on MacOS
    # XXX: does not work with MacOS default sed either?!
    # echo "${(%)1}" | sed "s/\x1B\[\([0-9]\{1,3\}\(;[0-9]\{1,3\}\)?\)?[m|K]//g"
    # echo "${(%)1}" | $sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})?)?[m|K]//g"
    echo $1 | $sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})?)?[m|K]//g"
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
    local -h        grey="%{$fg_bold[grey]%}"
    local -h        blue="%{$fg_no_bold[blue]%}"
    local -h     cwdtext="%{$fg_bold[white]%}"
    local -h   nonrwtext="%{$fg_no_bold[red]%}"
    local -h    warntext="%{$fg_bold[red]%}"
    local -h    roottext="%{$fg_bold[red]%}"
    local -h    repotext="%{$fg_bold[green]%}"
    local -h     invtext="%{$fg_bold[cyan]%}"
    local -h   alerttext="%{$fg_no_bold[red]%}"
    local -h   lighttext="%{$fg_no_bold[white]%}"
    local -h   darkdelim="$grey"
    local -h bracket_open="${darkdelim}["
    local -h bracket_close="${darkdelim}]"

    local -h prompt_cwd prompt_vcs cwd
    local -ah prompt_extra rprompt_extra

    if (( $ZSH_DISABLE_VCS_INFO )) || ! vcs_info 'prompt' &> /dev/null; then
        # No vcs_info available, only set cwd
        prompt_vcs=""
    else
        prompt_vcs="${PR_RESET}$vcs_info_msg_0_"
        if ! zstyle -t ':vcs_info:*:prompt:*' 'check-for-changes'; then
            prompt_vcs+=' ?'
        fi
        rprompt_extra+=("${vcs_info_msg_1_}")
    fi

    cwd=${(%):-%~} # 'print -P "%~"'

    # Highlight different types in segments of $cwd
    local ln_color=${${(ps/:/)LS_COLORS}[(r)ln=*]#ln=}
    # Fallback to default, if "target" is used
    [ "$ln_color" = "target" ] && ln_color="01;36"
    [[ -z $ln_color ]] && ln_color="%{${fg_bold[cyan]}%}" || ln_color="%{"$'\e'"[${ln_color}m%}"
    local colored cur color i cwd_split
    if [[ $cwd != '/' ]]; then
        # split $cwd at '/'
        cwd_split=(${(ps:/:)${cwd}})
        if [[ $cwd[1] == '/' ]]; then
            # starting at root
            cur='/'
        fi
        for i in $cwd_split; do
            # expand "~" to make the "-h" test work
            cur+=${~i}
            # color repository root
            if [[ ":$cur" = $vcs_info_msg_2_ ]]; then
                color=${repotext}
                # color Git repo (not root according to vcs_info then)
            elif [[ -d $cur/.git ]]; then
                color=${repotext}
            # color symlink segment
            elif [[ -h $cur ]]; then
                color=${ln_color}
            # color non-existing segment
            elif [[ ! -e $cur ]]; then
                color=${warntext}
            # color non-writable segment
            elif [[ ! -w $cur ]]; then
                color=${nonrwtext}
            else
                color=${cwdtext}
            fi
            # add slash, if not the first segment, or cwd starts with "/"
            if [[ -n $colored ]] || [[ $cwd[1] == '/' ]]; then
                colored+=${color}/${i}
            else
                colored+=${color}${i}
            fi
            cur+='/'
        done
        cwd=${colored}
    fi

    # Mark non-writable cwd (done for segments above)
    # if [[ ! -w $PWD ]]; then
    #     cwd="${nonrwtext}${cwd}"
    # fi

    # TODO: if cwd is too long for COLUMNS-restofprompt, cut longest parts of cwd
    #prompt_cwd="${hitext}%B%50<..<${cwd}%<<%b"
    prompt_cwd="$cwdtext${cwd}"

    local userathost
    if [[ -n $SSH_CLIENT ]]; then
        local -h     user="%(#.$roottext.$normtext)%n"

        # http_proxy defines color of "@" between user and host
        if [[ -n $http_proxy ]] ; then
            prompt_at="${hitext}@"
        else
            prompt_at="${normtext}@"
        fi

        local -h     host="%{${fg_no_bold[$(color_for_host)]}%}%m"

        userathost="${user}${prompt_at}${host} "
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

    # Assemble RPS1 (different from rprompt, which is right-aligned in PS1)
    # Do not do this when in a midnight commander subshell.
    [ -z "${MC_SID+x}" ]; is_mc_shell=$?
    # if [ -f /proc/$PPID/cmdline ]; then
    #   if grep -q '^mc\b' /proc/$PPID/cmdline; then
    #     is_mc_shell=1
    #   fi
    # else
    #   if [[ $(ps -o comm= $PPID) == "mc" ]]; then
    #     is_mc_shell=1
    #   fi
    # fi
    if [[ "$is_mc_shell" == "0" ]]; then
        RPS1_list=('$(vi_mode_prompt_info)')

        # Distribution (if on a remote system)
        if [ -n "$SSH_CLIENT" ] ; then
            RPS1_list+=("%{$fg_bold[black]%}$(get_distro)")
        fi

        RPS1_list=("${(@)RPS1_list:#}") # remove empty elements (after ":#")
        RPS1="${(j: :)RPS1_list}$PR_RESET"
    else
        prompt_extra+=("$normtext(mc)")
    fi

    # exit status
    local -h disp
    if [ $exitstatus -ne 0 ] ; then
        disp="es:$exitstatus"
        if [ $exitstatus -gt 128 -a $exitstatus -lt 163 ] ; then
            disp+=" (SIG$signals[$exitstatus-128])"
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

    # tmux pane / identifier
    # [[ -n "$TMUX_PANE" ]] && rprompt_extra+=("${TMUX_PANE//\%/%%}")
    # history number
    rprompt_extra+=("${normtext}!${grey}%!")
    # time
    rprompt_extra+=("${normtext}%*")

    # Assemble prompt:
    local -h rprompt="$rprompt_extra${PR_RESET}"
    local -h prompt="${userathost}${prompt_cwd}$prompt_extra"
    # right trim:
    prompt="${prompt%% #} "

    # Attach $rprompt to $prompt, aligned to $TERMWIDTH
    local -h TERMWIDTH=$((${COLUMNS}-1))
    local -h rprompt_len=${#${(%)"$(_strip_escape_codes $rprompt)"}}
    local -h prompt_len=${#${(%)"$(_strip_escape_codes $prompt)"}}
    PR_FILLBAR="$grey${(l:(($TERMWIDTH - ( ($rprompt_len + $prompt_len) % $TERMWIDTH))):: :)}"

    PROMPT="${prompt}${PR_FILLBAR}${rprompt}
$prompt_vcs%(#.$roottext.$normtext)❯${PR_RESET} "

    # When invoked from gvim ('zsh -i') make it less hurting
    if [[ -n $MYGVIMRC ]]; then
        PROMPT=$(_strip_escape_codes $PROMPT)
    fi

    # End profiling
        # unsetopt xtrace
        # exec 2>&3 3>&-
}


# register vcs_info hooks
zstyle ':vcs_info:git*+set-message:*' hooks git-stash git-st

# Show count of stashed changes
function +vi-git-stash() {
    local -a stashes
    local gitdir

    [[ $1 == 0 ]] || return # do this only once for vcs_info_msg_0_.
    # return if check-for-changes is false:
    if ! zstyle -t ':vcs_info:*:prompt:*' 'check-for-changes'; then
        hook_com[misc]+="$bracket_open$hitext? stashed$bracket_close"
        return
    fi

    # Resolve git dir (necessary for submodules)
    gitdir=${hook_com[base]}/.git
    if [[ -f $gitdir ]]; then
        gitdir=$(command git rev-parse --resolve-git-dir $gitdir)
    fi

    if [[ -s $gitdir/refs/stash ]] ; then
        stashes=$(command git --git-dir="$gitdir" --work-tree=. stash list 2>/dev/null | wc -l)
        hook_com[misc]+="$bracket_open$hitext${stashes} stashed$bracket_close"
    fi
}

# Show remote ref name and number of commits ahead-of or behind
function +vi-git-st() {
    local ahead behind remote
    local -a gitstatus

    [[ $1 == 0 ]] || return # do this only once vcs_info_msg_0_.
    # return if check-for-changes is false:
    if ! zstyle -t ':vcs_info:*:prompt:*' 'check-for-changes'; then
        return
    fi

    # Are we on a remote-tracking branch?
    remote=${$(command git rev-parse --verify ${hook_com[branch]}@{upstream} \
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
        # ahead=$(command git rev-list origin/${hook_com[branch]}..HEAD | wc -l)
        ahead=$(command git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
        (( $ahead )) && gitstatus+=( "${normtext}+${ahead}" )

        # for git prior to 1.7
        # behind=$(command git rev-list HEAD..origin/${hook_com[branch]} | wc -l)
        behind=$(command git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)
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

color_for_host() {
    colors=(cyan white yellow magenta blue default green)
    # NOTE: do not use `hostname -f`, which is slow with wacky network
    echo $(hash_value_from_list $HOST "$colors")
}

# Hash the given value to an item from the given list.
# Note: if strange errors happen here, it is because of some DEBUG echo in ~/.zshenv/zshrc probably.
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

# zstyle ':vcs_info:*:prompt:*' get-revision true # for %8.8i
zstyle ':vcs_info:*:prompt:*' unstagedstr '¹'  # display ¹ if there are unstaged changes
zstyle ':vcs_info:*:prompt:*' stagedstr '²'    # display ² if there are staged changes
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH} ${FMT_ACTION}" "%m" ":%R" # prepend ':' to make it not get used in %~ shortening
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}"               "%m" ":%R" # --"--
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""                            ""   ""
zstyle ':vcs_info:*:prompt:*' max-exports 3


#  vim: set ft=zsh ts=4 sw=4 et:
