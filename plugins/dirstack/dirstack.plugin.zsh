#!/bin/zsh
#
# dirstack handling from grml's zshrc
# (http://git.grml.org/?p=grml-etc-core.git;a=blob_plain;f=etc/zsh/zshrc;hb=HEAD)

is42(){
    [[ $ZSH_VERSION == 4.<2->* || $ZSH_VERSION == <5->* ]] && return 0
    return 1
}

DIRSTACKSIZE=${DIRSTACKSIZE:-50}
DIRSTACKFILE=${DIRSTACKFILE:-${HOME}/.zdirs}

if [[ -f ${DIRSTACKFILE} ]] && [[ ${#dirstack[*]} -eq 0 ]] ; then
    dirstack=( ${(f)"$(< $DIRSTACKFILE)"} )
    # "cd -" won't work after login by just setting $OLDPWD, so
    if [[ ${${dirstack[1]}[1,5]} != '/mnt/' ]]; then # skip any /mnt entries, which might hang (e.g. sshfs/cifs without network)
        if [[ -d $dirstack[1] ]]; then
            # if $PWD is the most recent dirstack entry, but resolved, change back and forth
            # This happens when opening a new tab in gnome-terminal, which appears to resolve the symlink.
            if [[ $PWD != $dirstack[1] ]] && [[ $(readlink -f $PWD) == $(readlink -f $dirstack[1]) ]]; then
                # save dirstack[1], which changes after the first cd!
                local -h d1=$dirstack[1]
                cd -qL $dirstack[2] && cd -qL $d1
            else
                cd -qL $dirstack[1] && cd -qL $OLDPWD
            fi
        fi
    fi
fi

autoload -U add-zsh-hook
add-zsh-hook chpwd _zsh_dirstack_chpwd_hook
_zsh_dirstack_chpwd_hook() {
    local -ax my_stack
    my_stack=( ${PWD} ${dirstack} )
    if is42 ; then
        builtin print -l ${(u)my_stack} >! ${DIRSTACKFILE}
    else
        uprint my_stack >! ${DIRSTACKFILE}
    fi
}
