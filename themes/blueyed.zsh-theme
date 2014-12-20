# blueyed's theme for zsh
#
# Features:
#  - color hostnames according to its hashed value (see color_for_host)
#
# Origin:
#  - Based on http://kriener.org/articles/2009/06/04/zsh-prompt-magic
#  - Some Git ideas from http://eseth.org/2010/git-in-zsh.html (+vi-git-stash, +vi-git-st, ..)
#
# Some signs: ✚ ⬆ ⬇ ✖ ✱ ➜ ✭ ═ ◼ ♺ ❮ ❯ λ
#
# TODO: setup $prompt_cwd in chpwd hook only (currently adding the hook causes infinite recursion via vcs_info)

autoload -U add-zsh-hook
autoload -Uz vcs_info

# Query/use custom command for `git`.
# See also ../plugins/git/git.plugin.zsh
zstyle -s ":vcs_info:git:*:-all-" "command" _git_cmd || _git_cmd=$(whence -p git)

# Skip prompt setup in virtualenv/bin/activate.
# This causes a glitch with `pyenv shell venv_name` when it gets activated.
VIRTUAL_ENV_DISABLE_PROMPT=1

PR_RESET="%{${reset_color}%}"

# Detect Midnight Commander, which needs special handling regarding its prompt.
[ -z "${MC_SID+x}" ]; is_mc_shell=$?
# Remove any ANSI color codes (via www.commandlinefu.com/commands/view/3584/)
_strip_escape_codes() {
    [[ -n $commands[gsed] ]] && sed=gsed || sed=sed # gsed with coreutils on MacOS
    # XXX: does not work with MacOS default sed either?!
    # echo "${(%)1}" | sed "s/\x1B\[\([0-9]\{1,3\}\(;[0-9]\{1,3\}\)?\)?[m|K]//g"
    # echo "${(%)1}" | $sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})?)?[m|K]//g"
    echo $1 | $sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})?)?[m|K]//g"
}

is_urxvt() {
    [[ $TERM == rxvt* ]] || [[ $COLORTERM == rxvt* ]]
}

# Check if we're running in gnome-terminal.
# This gets used to e.g. auto-switch the profile.
is_gnome_terminal() {
    # Common case, since I am using URxvt now.
    is_urxvt && return 1
    # Old-style, got dropped.. :/
    [[ $COLORTERM == "gnome-terminal" ]] && return 0
    # Check /proc, but only on the local system.
    if [[ -z $SSH_CLIENT ]] && [[ ${$(</proc/$PPID/cmdline):t} == gnome-terminal* ]]; then
        return 0
    fi
    return 1
}

my_get_gitdir() {
    local base=$1
    [[ -z $base ]] && base=$($_git_cmd rev-parse --show-toplevel)
    local gitdir=$base/.git
    if [[ -f $gitdir ]]; then
        # XXX: the output might be across two lines (fixed in the meantime); handled/fixed that somewhere else already, but could not find it.
        gitdir=$($_git_cmd rev-parse --resolve-git-dir $gitdir | head -n1)
    fi
    echo $gitdir
}

# Switch between light and dark variants (solarized). {{{
ZSH_THEME_VARIANT_CONFIG_FILE=~/.config/zsh-theme-variant
theme_variant() {
    if [[ "$1" == "auto" ]]; then
        if [[ -n $commands[get-daytime-period] ]] \
            && [[ "$(get-daytime-period)" == 'Daytime' ]]; then
            variant=light
        else
            variant=dark
        fi
    else
        case "$1" in
            light|dark) variant=$1 ;;
            *) echo "theme_variant: unknown arg: $1"; return 1 ;;
        esac
    fi
    echo $1 > $ZSH_THEME_VARIANT_CONFIG_FILE

    if [[ "$variant" == "light" ]] && is_gnome_terminal; then
        DIRCOLORS_FILE=~/.dotfiles/lib/dircolors-solarized/dircolors.ansi-light
    else
        # DIRCOLORS_FILE=~/.dotfiles/lib/dircolors-solarized/dircolors.ansi-dark
        # Prefer LS_COLORS repo, which is more fine-grained, but does not look good on light bg.
        DIRCOLORS_FILE=~/.dotfiles/lib/LS_COLORS/LS_COLORS
    fi
    zsh-set-dircolors

    # Setup/change gnome-terminal profile.
    if [[ "$ZSH_THEME_VARIANT" != "$variant" ]] && is_gnome_terminal; then
        local wanted_gnome_terminal_profile="Solarized-$variant"
        # local id_light=e6e34acf-124a-43bd-ad32-46fb0765ad76
        # local id_dark=b1dcc9dd-5262-4d8d-a863-c897e6d979b9

        local default_profile_id=${$(dconf read /org/gnome/terminal/legacy/profiles:/default)//\'/}
        # echo "default_profile_id:$default_profile_id"
        local default_profile_name=${$(dconf read /org/gnome/terminal/legacy/profiles:/":"$default_profile_id/visible-name)//\'/}
        # echo "default_profile_name:$default_profile_name"

        # local -h cur_profile=$(gconftool-2 --get /apps/gnome-terminal/global/default_profile)
        if [[ $default_profile_name != $wanted_gnome_terminal_profile ]]; then
            # Get ID of wanted profile.

            wanted_gnome_terminal_profile_id=$(
                dconf dump "/org/gnome/terminal/legacy/profiles:/" \
                | grep -P "^(visible-name='$wanted_gnome_terminal_profile'|\[:)" \
                | grep '^visible-name' -B1 | head -n1 \
                | sed -e 's/^\[://' -e 's/]$//')

            echo "Changing gnome-terminal default profile to: $wanted_gnome_terminal_profile ($wanted_gnome_terminal_profile_id)."
            # gconftool-2 --set --type string /apps/gnome-terminal/global/default_profile $gnome_terminal_profile
            dconf write /org/gnome/terminal/legacy/profiles:/default "'$wanted_gnome_terminal_profile_id'"
        fi
    fi
    export ZSH_THEME_VARIANT=$variant
}
# Init once and export the value.
# This gets used in Vim to auto-set the background, too.
if [[ -z "$ZSH_THEME_VARIANT" ]]; then
    [[ -f $ZSH_THEME_VARIANT_CONFIG_FILE ]] \
        && ZSH_THEME_VARIANT=$(<$ZSH_THEME_VARIANT_CONFIG_FILE) \
        || ZSH_THEME_VARIANT=auto
    theme_variant $ZSH_THEME_VARIANT
fi
# }}}


# Override builtin reset-prompt widget to call the precmd hook manually
# (for fzf's fzf-cd-widget). This is needed in case the pwd changed.
# TODO: move cwd related things from prompt_blueyed_precmd into a chpwd hook?!
zle -N reset-prompt my-reset-prompt
function my-reset-prompt() {
    if (( ${+precmd_functions[(r)prompt_blueyed_precmd]} )); then
        prompt_blueyed_precmd reset-prompt
    fi
    zle .reset-prompt
}

# NOTE: using only prompt_blueyed_precmd as the 2nd function fails to add it, when added as 2nd one!
setup_prompt_blueyed() {
    add-zsh-hook precmd prompt_blueyed_precmd
}
unsetup_prompt_blueyed() {
    add-zsh-hook -d precmd prompt_blueyed_precmd
}
setup_prompt_blueyed

# Optional arg 1: "reset-prompt" if called via reset-prompt zle widget.
prompt_blueyed_precmd () {
    # Get exit status of command first.
    local -h save_exitstatus=$?

    if [[ $1 == "reset-prompt" ]]; then
        if [[ $PWD == $_ZSH_LAST_PWD ]]; then
            # cwd did not change, nothing to do.
            return
        fi
    else
        _ZSH_LAST_EXIT_STATUS=$save_exitstatus
    fi
    _ZSH_LAST_PWD=$PWD

    # Start profiling, via http://stackoverflow.com/questions/4351244/can-i-profile-my-zshrc-zshenv
      # PS4='+$(date "+%s:%N") %N:%i> '
      # exec 3>&2 2>/tmp/startlog.$$
      # setopt xtrace

    # FYI: list of colors: cyan, white, yellow, magenta, black, blue, red, default, grey, green
    # See `colors-table` for a list.
    local -h exitstatus=$_ZSH_LAST_EXIT_STATUS
    local -h    normtext="%{$fg_no_bold[default]%}"
    local -h      hitext="%{$fg_bold[magenta]%}"
    local -h    histtext="$normtext"
    local -h  distrotext="%{$fg_bold[green]%}"
    local -h  jobstext_s="%{$fg_bold[magenta]%}"
    local -h  jobstext_r="%{$fg_bold[magenta]%}"
    local -h exiterrtext="%{$fg_no_bold[red]%}"
    local -h        blue="%{$fg_no_bold[blue]%}"
    local -h     cwdtext="%{$fg_no_bold[default]%}"
    local -h   nonrwtext="%{$fg_no_bold[red]%}"
    local -h    warntext="%{$fg_bold[red]%}"
    local -h    roottext="%{$fg_bold[red]%}"
    local -h    repotext="%{$fg_no_bold[green]%}"
    local -h     invtext="%{$fg_bold[cyan]%}"
    local -h   alerttext="%{$fg_no_bold[red]%}"
    local -h   lighttext="%{$fg_bold[default]%}"
    local -h     rprompt="$normtext"
    local -h   rprompthl="$lighttext"
    local -h  prompttext="%{$fg_no_bold[green]%}"
    if [[ $ZSH_THEME_VARIANT == "light" ]] && is_gnome_terminal; then
        local -h   dimmedtext="%{$fg_no_bold[white]%}"
    else
        local -h   dimmedtext="%{$fg_no_bold[black]%}"
    fi
    local -h   darkdelim="$dimmedtext"
    local -h bracket_open="${darkdelim}["
    local -h bracket_close="${darkdelim}]"

    local -h prompt_cwd prompt_vcs cwd
    local -ah prompt_extra rprompt_extra

    if (( $ZSH_IS_SLOW_DIR )) || ! vcs_info 'prompt' &>/dev/null; then
        # No vcs_info available, only set cwd
        prompt_vcs=""
    else
        prompt_vcs="${PR_RESET}$vcs_info_msg_0_"
        if ! zstyle -t ':vcs_info:*:prompt:*' 'check-for-changes'; then
            prompt_vcs+=' ?'
        fi
        rprompt_extra+=("${vcs_info_msg_1_}")
    fi

    # Shorten named/hashed dirs.
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

        setopt localoptions no_nomatch
        local n=0
        for i in $cwd_split; do
            n=$(($n+1))

            # Expand "~" to make the "-h" test work.
            cur+=${~i}

            # Use a special symbol for "/home".
            if [[ $n == 1 ]]; then
                if [[ $i == 'home' ]]; then
                    i='⌂'
                elif [[ $i[1] != '~' ]]; then
                    i="/$i"
                fi
            fi

            # color repository root
            if [[ "$cur" = $vcs_info_msg_2_ ]]; then
                color=${repotext}
            # color Git repo (not root according to vcs_info then)
            elif [[ -e $cur/.git ]]; then
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
            # Add slash, if not the first segment.
            if [[ -n $colored ]] ; then
                colored+=${color}/${i:gs/%/%%/}
            else
                colored+=${color}${i:gs/%/%%/}
            fi
            cur+='/'
        done
        cwd=${colored}
    fi

    # Display repo and shortened revision as of vcs_info, if available.
    if [[ -n $vcs_info_msg_3_ ]]; then
        # rprompt_extra+=(${repotext}${vcs_info_msg_2_:t}@${rprompt_extra_rev})
        rprompt_extra+=(${repotext}${vcs_info_msg_2_:t}@${vcs_info_msg_3_})
        # rprompt_extra+=(${repotext}@${vcs_info_msg_3_})
    fi

    # TODO: if cwd is too long for COLUMNS-restofprompt, cut longest parts of cwd
    #prompt_cwd="${hitext}%B%50<..<${cwd}%<<%b"
    prompt_cwd="$cwdtext${cwd}"

    # user@host for SSH connections or when inside an OpenVZ container.
    local userathost
    if [[ -n $SSH_CLIENT ]] \
        || [[ -e /proc/user_beancounters && ! -d /proc/bc ]]; then
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
    # pyenv
    if [[ -n $PYENV_VERSION ]]; then
        rprompt_extra+=("${rprompthl}🐍 ${normtext}${PYENV_VERSION}")
    fi
    # virtualenv
    if [[ -n $VIRTUAL_ENV ]]; then
        rprompt_extra+=("${rprompthl}ⓔ ${normtext}${VIRTUAL_ENV##*/}")
    fi
    if [[ -n $ENVSHELL ]]; then
        prompt_extra+=("${rprompthl}ENV:${normtext}${ENVSHELL##*/}")
    fi

    # ENVDIR (used for tmm, ':A:t' means tail of absolute path).
    # Only display it when not in an envshell already.
    if [[ -z $ENVSHELL ]] && [[ -n $ENVDIR ]]; then
        rprompt_extra+=("${rprompt}envdir:${ENVDIR:A:t}")
    fi
    if [[ -n $DJANGO_CONFIGURATION ]]; then
        rprompt_extra+=("${rprompt}djc:$DJANGO_CONFIGURATION")
    fi
    # Obsolete
    if [[ -n $DJANGO_SETTINGS_MODULE ]]; then
        if [[ $DJANGO_SETTINGS_MODULE != 'config.settings' ]] && \
            [[ $DJANGO_SETTINGS_MODULE != 'project.settings.local' ]]; then
            rprompt_extra+=("${rprompt}djs:${DJANGO_SETTINGS_MODULE##*.}")
        fi
    fi
    # Shell level: display it if >= 1 (or 2 if $TMUX is set).
    # if [[ $SHLVL -gt ((1+$+TMUX)) ]]; then
    #     rprompt_extra+=("%fSHLVL:${SHLVL}")
    # fi

    # Assemble RPS1 (different from rprompt, which is right-aligned in PS1).
    if [[ "$is_mc_shell" == "0" ]]; then
        RPS1_list=()

        # Distribution (if on a remote system)
        if [ -n "$SSH_CLIENT" ] ; then
            RPS1_list+=("$distrotext$(get_distro)")
        fi

        # Keymap indicator for dumb terminals.
        if [ -n ${_ZSH_KEYMAP_INDICATOR} ]; then
            RPS1_list+=("${_ZSH_KEYMAP_INDICATOR}")
        fi

        RPS1_list=("${(@)RPS1_list:#}") # remove empty elements (after ":#")
        # NOTE: PR_RESET without space might cause off-by-one error with urxvt after `ls <tab>` etc.
        if (( $#RPS1_list )); then
            RPS1="${(j: :)RPS1_list}$PR_RESET "
        else
            RPS1=
        fi
    else
        prompt_extra+=("$normtext(mc)")
    fi

    # exit status
    local -h disp
    if [[ $exitstatus -ne 0 ]] ; then
        disp="es:$exitstatus"
        if [ $exitstatus -gt 128 -a $exitstatus -lt 163 ] ; then
            disp+=" (SIG$signals[$exitstatus-128])"
        fi
        # TODO: might make this informative only (to the right) and use a different prompt sign color to indicate $? != 0
        prompt_extra+=("${bracket_open}${exiterrtext}${disp}${bracket_close}")
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
        [[ $suspended -gt 0 ]] && jobstatus+="${jobstext_s}${suspended}s"
        [[ $running -gt 0 ]] && jobstatus+="${jobstext_r}${running}r"
        [[ -z $jobstatus ]] || prompt_extra+=("${bracket_open}${normtext}jobs:${jobstatus}${bracket_close}")
    fi

    # local -h    prefix="%{$normtext%}❤ "

    # tmux pane / identifier
    # [[ -n "$TMUX_PANE" ]] && rprompt_extra+=("${TMUX_PANE//\%/%%}")
    if (( $COLUMNS > 80 )); then
        # history number
        rprompt_extra+=("${normtext}!${histtext}%!")
        # time
        rprompt_extra+=("${normtext}%*")
    fi

    # printf ':%s\n' $rprompt_extra
    # whitespace and reset for extra prompts if non-empty:
    [[ -n $prompt_extra ]]  &&  prompt_extra=" ${(j: :)prompt_extra}$PR_RESET"
    [[ -n $rprompt_extra ]] && rprompt_extra="${(j: :)rprompt_extra}$PR_RESET"

    # Assemble prompt:
    local -h prompt="${userathost}${prompt_cwd}${prompt_extra}"
    local -h rprompt="$rprompt_extra${PR_RESET}"
    # right trim:
    prompt="${prompt%% #} "

    # Attach $rprompt to $prompt, aligned to $TERMWIDTH
    local -h TERMWIDTH=$((${COLUMNS}-1))
    local -h rprompt_len=${#${"$(_strip_escape_codes ${(%)rprompt})"}}
    local -h prompt_len=${#${"$(_strip_escape_codes ${(%)prompt})"}}
    PR_FILLBAR="%f${(l:(($TERMWIDTH - ( ($rprompt_len + $prompt_len) % $TERMWIDTH))):: :)}"

    # local -h prompt_sign='%b%(#.%F{green}.%F{red})❯%F{yellow}❯%(#.%F{red}.%F{green})❯%f%b'
    local -h prompt_sign="%b%(?.%F{blue}.%F{red})❯%(#.${roottext}.${prompttext})❯%f"

# NOTE: Konsole has problems with rendering the special sign if it's colored!
#     PROMPT="${prompt}${PR_FILLBAR}${rprompt}
# $prompt_vcs%f❯ "
    PROMPT="${prompt}${PR_FILLBAR}${rprompt}
${prompt_vcs}${prompt_sign}${PR_RESET} "

    # When invoked from gvim ('zsh -i') make it less hurting
    if [[ -n $MYGVIMRC ]]; then
        PROMPT=$(_strip_escape_codes $PROMPT)
    fi

    # End profiling
    # unsetopt xtrace
    # exec 2>&3 3>&-
}


# register vcs_info hooks
zstyle ':vcs_info:git*+set-message:*' hooks git-stash git-st git-untracked git-shallow

# Show count of stashed changes
function +vi-git-stash() {
    [[ $1 == 0 ]] || return  # do this only once for vcs_info_msg_0_.

    local -a stashes
    local gitdir

    # Return if check-for-changes is false:
    if ! zstyle -t ':vcs_info:*:prompt:*' 'check-for-changes'; then
        hook_com[misc]+="$bracket_open$hitext? stashed$bracket_close"
        return
    fi

    # Resolve git dir (necessary for submodules)
    gitdir=$(my_get_gitdir ${hook_com[base]})

    if [[ -s $gitdir/refs/stash ]] ; then
        stashes=$($_git_cmd --git-dir="$gitdir" --work-tree=. stash list 2>/dev/null | wc -l)
        hook_com[misc]+="$bracket_open$hitext${stashes} stashed$bracket_close"
    fi
    return
}

# vcs_info: git: Show marker (✗) if there are untracked files in repository.
# (via %c).
function +vi-git-untracked() {
    [[ $1 == 0 ]] || return  # do this only once vcs_info_msg_0_.

    if [[ $($_git_cmd rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        # $_git_cmd status --porcelain | grep '??' &> /dev/null ; then
        # This will show the marker if there are any untracked files in repo.
        # If instead you want to show the marker only if there are untracked
        # files in $PWD, use:
        [[ -n $($_git_cmd ls-files --others --exclude-standard) ]] ; then
        hook_com[staged]+='✗ '
    fi
}

# vcs_info: git: Show marker if the repo is a shallow clone.
# (via %c).
function +vi-git-shallow() {
    [[ $1 == 0 ]] || return 0 # do this only once vcs_info_msg_0_.

    echo $(my_get_gitdir ${hook_com[base]})/shallow >> /tmp/1
    if [[ -f $(my_get_gitdir)/shallow ]]; then
        hook_com[misc]+="${bracket_open}${hitext}shallow${bracket_close}"
    fi
}

# Show remote ref name and number of commits ahead-of or behind.
# This also colors and adjusts ${hook_com[branch]}.
function +vi-git-st() {
    [[ $1 == 0 ]] || return 0 # do this only once vcs_info_msg_0_.

    local ahead_and_behind_cmd ahead_and_behind
    local ahead behind remote
    local branch_color remote_color local_branch local_branch_disp
    local -a gitstatus

    # Determine short revision for rprompt.
    # rprompt_extra_rev=$($_git_cmd describe --always --abbrev=1 ${hook_com[revision]})

    # return if check-for-changes is false:
    if ! zstyle -t ':vcs_info:*:prompt:*' 'check-for-changes'; then
        return 0
    fi

    # Are we on a remote-tracking branch?
    remote=${$($_git_cmd rev-parse --verify ${hook_com[branch]}@{upstream} \
        --symbolic-full-name 2>/dev/null)/refs\/remotes\/}

    # NOTE: "branch" might come shortened as "$COMMIT[0,7]..." from Zsh.
    #       (gitbranch="${${"$(< $gitdir/HEAD)"}[1,7]}…").
    local_branch=${hook_com[branch]}

    # Init local_branch_disp: shorten branch.
    if [[ $local_branch == bisect/* ]]; then
        local_branch_disp="-"
    elif (( $#local_branch > 13 )) && ! [[ $local_branch == */* ]]; then
        local_branch_disp="${local_branch:0:12}…"
    else
        local_branch_disp=$local_branch
    fi

    # Make branch name bold if not "master".
    [[ $local_branch == "master" ]] \
        && branch_color="%{$fg_no_bold[blue]%}" \
        || branch_color="%{$fg_bold[blue]%}"

    if [[ -z ${remote} ]] ; then
        hook_com[branch]="${branch_color}${local_branch_disp}"
        return 0
    else
        # for git prior to 1.7
        # ahead=$($_git_cmd rev-list origin/${hook_com[branch]}..HEAD | wc -l)

        # Gets the commit difference counts between local and remote.
        ahead_and_behind_cmd='git rev-list --count --left-right HEAD...@{upstream}'
        # Get ahead and behind counts.
        ahead_and_behind="$(${(z)ahead_and_behind_cmd} 2> /dev/null)"

        ahead="$ahead_and_behind[(w)1]"
        (( $ahead )) && gitstatus+=( "${normtext}+${ahead}" )

        behind="$ahead_and_behind[(w)2]"
        (( $behind )) && gitstatus+=( "${alerttext}-${behind}" )

        remote=${remote%/$local_branch}

        # Abbreviate "master@origin" to "m@o" (common/normal).
        if [[ $remote == "origin" ]] ; then
          remote=o
          [[ $local_branch == "master" ]] && local_branch_disp="m"
        else
          remote_color="%{$fg_bold[blue]%}"
        fi

        hook_com[branch]="${branch_color}${local_branch_disp}$remote_color@${remote}"
        [[ -n $gitstatus ]] && hook_com[branch]+="$bracket_open$normtext${(j:/:)gitstatus}$bracket_close"
    fi
    return 0
}

_my_cursor_shape=auto
_auto-my-set-cursor-shape() {
    if [[ $_my_cursor_shape != "auto" ]]; then
        return
    fi
    my-set-cursor-shape "$@"
    _my_cursor_shape=auto
}
# Can be called manually, and will not be autoset then anymore.
my-set-cursor-shape() {
    [[ $is_mc_shell == 1 ]] && return
    # Not supported with gnome-terminal and "linux".
    is_urxvt || return

    local code
    case "$1" in
        block_blink)     code='\e[1 q' ;;
        block)           code='\e[2 q' ;;
        underline_blink) code='\e[3 q' ;;
        underline)       code='\e[4 q' ;;
        bar_blink)       code='\e[5 q' ;;
        bar)             code='\e[6 q' ;;
        auto) echo "Using 'auto' again." ;;
        # NOTE: bar/ibeam not supported by urxvt.
        *) echo "my-set-cursor-shape: unknown arg: $1"; return 1 ;;
    esac
    if [[ -n $code ]]; then
        printf $code
    fi
    _my_cursor_shape=$1
    return 0
}

# Vim mode indicator {{{1
zle-keymap-select zle-line-init () {
    if is_urxvt; then
        if [ $KEYMAP = vicmd ]; then
            _auto-my-set-cursor-shape block_blink
        else
            _auto-my-set-cursor-shape bar_blink
        fi
    elif [[ $TERM == xterm* ]]; then
        if [ $KEYMAP = vicmd ]; then
            # First set a color name (recognized by gnome-terminal), then the number from the palette (recognized by urxvt).
            # NOTE: not for "linux" or tmux on linux.
            printf "\033]12;#0087ff\007"
            printf "\033]12;4\007"
        else
            printf "\033]12;#5f8700\007"
            printf "\033]12;2\007"
        fi
    else
        # Dumb terminal, e.g. linux or screen/tmux in linux console.
        # If mode indicator wasn't setup by theme, define default.
        if [[ "$MODE_INDICATOR" == "" ]]; then
            MODE_INDICATOR="%{$fg_bold[red]%}<%{$fg_no_bold[red]%}<<%{$reset_color%}"
        fi

        export _ZSH_KEYMAP_INDICATOR="${${KEYMAP/vicmd/$MODE_INDICATOR}/(main|viins)/}"
        my-reset-prompt
    fi
}
zle -N zle-keymap-select
zle -N zle-line-init
# Init.
_auto-my-set-cursor-shape underline_blink

# Manage my_confirm_client_kill X client property (used by awesome). {{{
function get_x_focused_win_id() {
    set localoptions pipefail
    xprop -root 2>/dev/null | sed -n '/^_NET_ACTIVE_WINDOW/ s/.* // p'
}

if is_urxvt && [[ -n $DISPLAY ]]; then
    function set_my_confirm_client_kill() {
      # xprop -id $(get_x_focused_win_id) -f my_confirm_client_kill 8c
      xprop -id $WINDOWID -f my_confirm_client_kill 8c \
          -set my_confirm_client_kill $1
    }
    function prompt_blueyed_confirmkill_preexec() {
      set_my_confirm_client_kill 1
    }
    function prompt_blueyed_confirmkill_precmd() {
      set_my_confirm_client_kill 0
    }
    add-zsh-hook preexec prompt_blueyed_confirmkill_preexec
    add-zsh-hook precmd  prompt_blueyed_confirmkill_precmd
fi
# }}}

# Set block cursor before executing a program.
add-zsh-hook preexec prompt_blueyed_cursorstyle_preexec
function prompt_blueyed_cursorstyle_preexec() {
  _auto-my-set-cursor-shape block_blink
}
# }}}

color_for_host() {
    # FYI: list of colors: cyan, white, yellow, magenta, black, blue, red, default, grey, green
    colors=(cyan yellow magenta blue green)

    # NOTE: do not use `hostname -f`, which is slow with wacky network
    # %M resolves to the full hostname
    echo $(hash_value_from_list ${(%):-%M} "$colors")
}

# Hash the given value to an item from the given list.
# Note: if strange errors happen here, it is because of some DEBUG echo in ~/.zshenv/zshrc probably.
hash_value_from_list() {
    if ! (( ${+functions[(r)sumcharvals]} )); then
      source =sumcharvals
    fi

    value=$1
    list=(${(s: :)2})
    index=$(( $(sumcharvals $value) % $#list + 1 ))
    echo $list[$index]
}

# vcs_info styling formats {{{1
# XXX: %b is the whole path for CVS, see ~/src/b2evo/b2evolution/blogs/plugins
# NOTE: %b gets colored via hook_com.
FMT_BRANCH="%{$fg_no_bold[blue]%}↳ %s:%b%{$fg_bold[blue]%}%{$fg_bold[magenta]%}%u%c" # e.g. master¹²
# FMT_BRANCH=" %{$fg_no_bold[blue]%}%s:%b%{$fg_bold[blue]%}%{$fg_bold[magenta]%}%u%c" # e.g. master¹²
FMT_ACTION="%{$fg_no_bold[cyan]%}(%a%)"   # e.g. (rebase-i)

# zstyle ':vcs_info:*+*:*' debug true
zstyle ':vcs_info:*:prompt:*' get-revision true # for %8.8i
zstyle ':vcs_info:*:prompt:*' unstagedstr '¹'  # display ¹ if there are unstaged changes
zstyle ':vcs_info:*:prompt:*' stagedstr '²'    # display ² if there are staged changes
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH} ${FMT_ACTION}" "%m" "%R" "%8.8i"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}"               "%m" "%R" "%8.8i"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""                            ""   ""   ""
zstyle ':vcs_info:*:prompt:*' max-exports 4
# patch-format for Git, used during rebase.
zstyle ':vcs_info:git*:prompt:*' patch-format "%{$fg_no_bold[cyan]%}Applied: %p [%n/%a]"


# Interface to zsh's promptinit.
prompt_blueyed_setup() {
    prompt_blueyed_precmd
}

#  vim: set ft=zsh ts=4 sw=4 et:
