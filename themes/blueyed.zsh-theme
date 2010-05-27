# Based on http://kriener.org/articles/2009/06/04/zsh-prompt-magic

autoload -U add-zsh-hook
autoload -Uz vcs_info

setopt prompt_subst

add-zsh-hook precmd prompt_blueyed_precmd
prompt_blueyed_precmd () {
    if ! vcs_info 'prompt' &> /dev/null; then
        psvar[2]="${PWD/#$HOME/~}"
    else
        psvar[1]="$vcs_info_msg_0_"
        psvar[2]='${${vcs_info_msg_1_%%.}/$HOME/~}'
    fi

    # http_proxy defines color of "@" between user and host
    if [ -n "$http_proxy" ] ; then
        prompt_at="%{$fg_bold[green]%}@"
    else
        prompt_at="%{$fg_bold[red]%}@"
    fi

    # $debian_chroot:
    if [[ -n "$debian_chroot" ]]; then
        prompt_extra=" %{$fg[red]%}(dch:$debian_chroot)"
    fi
}


PR_RESET="%{${reset_color}%}";


# set formats
# %b - branchname
# %u - unstagedstr (see below)
# %c - stangedstr (see below)
# %a - action (e.g. rebase-i)
# %R - repository path
# %S - path in the repository
FMT_BRANCH="%{$fg[green]%}%b%u%c" # e.g. master¹²
FMT_ACTION="%{$fg[cyan]%}(%a%)"   # e.g. (rebase-i)
FMT_PATH="%R%{$fg[yellow]%}/%S"   # e.g. ~/repo/subdir

# check-for-changes can be really slow.
# you should disable it, if you work with large repositories
zstyle ':vcs_info:*:prompt:*' check-for-changes true
zstyle ':vcs_info:*:prompt:*' unstagedstr '¹'  # display ¹ if there are unstaged changes
zstyle ':vcs_info:*:prompt:*' stagedstr '²'    # display ² if there are staged changes
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH}${FMT_ACTION}//" "${FMT_PATH}"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}//"              "${FMT_PATH}"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""                             "%~"


function prompt_blueyed_setup {
    # via http://www.zsh.org/mla/users/2005/msg00863.html
    local -h    normtext="%{$fg_no_bold[green]%}"
    local -h      hitext="%{$fg_bold[green]%}"
    local -h   alerttext="%{$fg_no_bold[red]%}"
    local -h   lighttext="%{$fg_no_bold[white]%}"
    local -h     invtext="%{$fg_bold[cyan]%}"

    local -h     user="%(#.$alerttext.$normtext)%(!.%U.)%n%(!.%u.)"
    local -h     host="${hitext}%m"
    local -h   histnr="${normtext}!${invtext}%!"
    local -h     time="${normtext}%T"

    local -h bracket_open="${lighttext}["
    local -h bracket_close="${lighttext}]"
    local -h brace_open="%(#.$alerttext.$normtext){"
    local -h brace_close="%(#.$alerttext.$normtext)}"

    local ret_status="%(?:: ${bracket_open}${alerttext}es:%?${bracket_close})"

    # TODO: use $jobstates to get stopped/running numbers. Or "jobs" output (=> custom_prompt.sh)
    local jobstatus="%(1j. ${bracket_open}${lighttext}jobs:${hitext}%j${bracket_close}.)"

    local vcs='%(1V:$psvar[1] :)'
    local cwd="${hitext}%B%50<..<\${psvar[2]}%<<%b"

    local -h    prefix="%{$fg_bold[red]%}❤ "

    PROMPT="${prefix}${user}\$prompt_at${host}\$prompt_extra${ret_status}${jobstatus} $brace_open $cwd $brace_close
${vcs}%# ${PR_RESET}"
    RPROMPT="$histnr $time${PR_RESET}"
}

prompt_blueyed_setup

#  vim: set ft=zsh ts=4 sw=4 et:
