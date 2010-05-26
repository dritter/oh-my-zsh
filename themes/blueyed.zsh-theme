# Based on http://kriener.org/articles/2009/06/04/zsh-prompt-magic

autoload -U add-zsh-hook
autoload -Uz vcs_info

setopt prompt_subst

add-zsh-hook precmd prompt_blueyed_precmd
prompt_blueyed_precmd () {
    vcs_info 'prompt'
    psvar[1]="$vcs_info_msg_0_"

    # http_proxy defines color of "@" between user and host
    if [ -n "$http_proxy" ] ; then
        prompt_at="%{$bg[black]$fg_bold[green]%}@"
    else                               
        prompt_at="%{$bg[black]$fg_bold[red]%}@"
    fi

    # $debian_chroot:
    if [[ -n "$debian_chroot" ]]; then
        prompt_extra=" %{$bg[black]$fg[red]%}(dch:$debian_chroot)"
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
FMT_BRANCH="%{$bg[black]$fg[green]%}%b%u%c" # e.g. master¹²
FMT_ACTION="%{$bg[black]$fg[cyan]%}(%a%)"   # e.g. (rebase-i)
FMT_PATH="%R%{$bg[black]$fg[yellow]%}/%S"   # e.g. ~/repo/subdir

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
    local -h    normtext="%{$bg[black]$fg_bold[green]%}"
    local -h      hitext="%{$bg[black]$fg_bold[white]%}"
    local -h   alerttext="%{$bg[black]$fg_bold[red]%}"
    local -h    signtext="%{$bg[black]$fg_bold[grey]%}"
    local -h     invtext="%{$bg[black]$fg_bold[cyan]%}"

    local -h     user="%(#.$alerttext.$normtext)%(!.%U.)%n%(!.%u$bkg.)"
    local -h     host="${hitext}%m"
    local -h   histnr="${normtext}!${invtext}%!"
    local -h     time="${normtext}%T"

    local -h bracket_open="${signtext}["
    local -h bracket_close="${signtext}]"
    local -h brace_open="${signtext}{"
    local -h brace_close="${signtext}}"
 
    local ret_status="%(?:: ${bracket_open}${alerttext}es:%?${bracket_close})"

    # TODO: use $jobstates to get stopped/running numbers. Or "jobs" output (=> custom_prompt.sh)
    local jobstatus="%(1j. ${bracket_open}jobs:${hitext}%j${bracket_close}.)"

    local vcs='%(1V:$psvar[1] :)'
    local vcs_cwd='${${vcs_info_msg_1_%%.}/$HOME/~}'
    local cwd="${hitext}%B%50<..<${vcs_cwd}%<<%b"

    local -h    prefix="%{$bg[black]$fg_bold[red]%}❤ "

    PROMPT="${prefix}${user}\$prompt_at${host}\$prompt_extra${ret_status}${jobstatus} $brace_open $cwd $brace_close
${vcs}%# ${PR_RESET}"
    RPROMPT="$histnr $time${PR_RESET}"
}                                                                                        

prompt_blueyed_setup

#  vim: set ft=zsh ts=4 sw=4 et:
