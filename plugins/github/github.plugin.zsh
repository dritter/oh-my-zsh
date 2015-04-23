# Setup hub function for git, if it is available; http://github.com/defunkt/hub
if [[ -n "$commands[(I)hub2]" ]]; then
    _hub_command=hub2
elif [[ -n "$commands[(I)hub]" ]] && [[ -n "$commands[(I)ruby]" ]]; then
    _hub_command=hub
fi

if [[ -n $_hub_command ]]; then
    eval 'function git(){
        if ! (( $+_has_working_hub  )); then
            '$_hub_command' --version &> /dev/null
            _has_working_hub=$(($? == 0))
        fi
        if (( $_has_working_hub )) ; then
            '$_hub_command' "$@"
        else
            command git "$@"
        fi
        local ret=$?
        # Force vcs_info to be run.
        _ZSH_VCS_INFO_FORCE_GETDATA=1
        return $ret
    }'
    unset _hub_command

    # Use the git command for vcs_info, instead of hub!
    zstyle ':vcs_info:git:*:-all-' command $(whence -p git)

    # Use hub's compdef for git.
    if whence _hub >/dev/null; then
        compdef _hub git
    else
        echo "NOTE: _hub not available for compdef!"
    fi
fi

# Functions #################################################################

# https://github.com/dbb 


# empty_gh [NAME_OF_REPO]
#
# Use this when creating a new repo from scratch.
empty_gh() { # [NAME_OF_REPO]
    repo=$1
    ghuser=$(  git config github.user )

    mkdir "$repo"
    cd "$repo"
    git init
    touch README
    git add README
    git commit -m 'Initial commit.'
    git remote add origin git@github.com:${ghuser}/${repo}.git
    git push -u origin master
}

# new_gh [DIRECTORY]
#
# Use this when you have a directory that is not yet set up for git.
# This function will add all non-hidden files to git.
new_gh() { # [DIRECTORY]
    cd "$1"
    ghuser=$( git config github.user )

    git init
    # add all non-dot files
    print '.*'"\n"'*~' >> .gitignore
    git add ^.*
    git commit -m 'Initial commit.'
    git remote add origin git@github.com:${ghuser}/${repo}.git
    git push -u origin master
}

# exist_gh [DIRECTORY]
#
# Use this when you have a git repo that's ready to go and you want to add it
# to your GitHub.
exist_gh() { # [DIRECTORY]
    cd "$1"
    name=$( git config user.name )
    ghuser=$( git config github.user )
    repo=$1

    git remote add origin git@github.com:${ghuser}/${repo}.git
    git push -u origin master
}

# git.io "GitHub URL"
#
# Shorten GitHub url, example:
#   https://github.com/nvogel/dotzsh    >   http://git.io/8nU25w  
# source: https://github.com/nvogel/dotzsh
# documentation: https://github.com/blog/985-git-io-github-url-shortener
#
git.io() {curl -i -s http://git.io -F "url=$1" | grep "Location" | cut -f 2 -d " "}

# End Functions #############################################################

