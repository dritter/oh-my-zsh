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
            cd $dirstack[1] && cd $OLDPWD
        fi
    fi
fi

chpwd() {
    local -ax my_stack
    my_stack=( ${PWD} ${dirstack} )
    if is42 ; then
        builtin print -l ${(u)my_stack} >! ${DIRSTACKFILE}
    else
        uprint my_stack >! ${DIRSTACKFILE}
    fi
}
