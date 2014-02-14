# Aliases
#alias g='git' # used for 'gvim --remote'
alias ga='git add'
alias gap='git add --patch'
alias gae='git add --edit'
alias gb='git branch'
alias gba='git branch -a'
alias gbl='git blame'
alias gc='git commit -v'
gcm() { git commit -m "$*" }
alias gcm='noglob gcm'
alias gca='git commit -v -a'
alias gcl='git clone --recursive'
alias gco='git checkout'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gd='git diff --submodule'
alias gdc='git diff --cached'
# `git diff` against upstream (usually origin/master)
gdo() {
  _git_against_upstream diff "$@"
}
compdef _git gdo=git-diff
# `git log` against upstream (usually origin/master)
glo() {
  [ x$1 = x ] && opt='--stat' || opt="$@"
  _git_against_upstream log "$opt"
}
compdef _git glo=git-log
_git_against_upstream() {
  [ x$1 = x ] && { echo "Missing command."; return 1; }
  u=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))
  [ x$u = x ] && { echo "No upstream setup for tracking."; return 2; }
  cmd=(git $@ $u..HEAD)
  echo $cmd
  $cmd
}
gdv() { git diff -w "$@" | view - }
compdef _git gdv=git-diff
alias gdt='git difftool'
alias gdtc='git difftool --cached'
alias gf='git fetch'
alias gl='git l'
alias glp='gl -p'
alias glg='git log --stat --max-count=5'
alias glgg='git log --graph --max-count=5'
alias gls='git ls-files'
alias glsu='git ls-files -o --exclude-standard'
alias gp='git push'
alias gpl='git pull --ff-only'
alias gpll='git pull'
alias gr='git remote'
alias grh='git reset HEAD'
alias gsh='git show'
alias gsm='git submodule'
alias gsms='git submodule summary'
alias gsmst='git submodule status'
alias gss='git status -s'
alias gst='git status'
# git-up and git-reup from ~/.dotfiles/usr/bin
compdef _git git-up=git-fetch
compdef _git git-reup=git-fetch
# "git submodule commit":
gsmc() {
  [ x$1 = x ] && { echo "Commit update to which submodule?"; return 1;}
  [ -d "$1" ] || { echo "Submodule $1 not found."; return 2;}
  summary=$(git submodule summary "$1" 2>&1)
  if [[ $? != 0 ]]; then
    echo "Error with 'git submodule summary $1':\n$summary"; return 3
  fi
  if [[ $summary == "" ]] ; then
    echo "Submodule $1 not changed."; return 4
  fi
  if [[ $summary == fatal:* ]] ; then
    echo $summary ; return 5
  fi
  summary=( ${(f)summary} )

  # TODO: check that commits are pushed?!
  # relevant?! echo $summary | grep -o "Warn: $1 doesn't contain commit" && return 3

  git commit -m "Update submodule $1 ${${(ps: :)summary[1]}[3]}"$'\n\n'"${(F)summary}" "$1"
}
# "git submodule add":
gsma() {
  [ x$1 = x ] && { echo "Add which submodule?"; return 1;}
  [ x$2 = x ] && { echo "Where to add submodule?"; return 2;}
  git diff --cached --exit-code > /dev/null || { echo "Index is not clean."; return 1 ; }
  # test for clean .gitmodules
  local -h gitroot=$(readlink -f ./$(git rev-parse --show-cdup))
  if [[ -f $gitroot/.gitmodules ]]; then
    git diff --exit-code $gitroot/.gitmodules > /dev/null || { echo ".gitmodules is not clean."; return 2 ; }
  fi
  git submodule add "$1" "$2" && \
  summary=$(git submodule summary "$2") && \
  summary=( ${(f)summary} ) && \
  git commit -m "Add submodule $2 @${${${(ps: :)summary[1]}[3]}/*.../}"$'\n\n'"${(F)summary}" "$2" .gitmodules && \
  git submodule update --init --recursive "$2"
}
# `gsma` for ~df/vim/bundles:
# Use basename from $1 without typical prefix (vim-) and suffix (.git) for bundle name.
gsmav() {
  [ x$1 = x ] && { echo "Add which submodule?"; return 1;}
  ~df
  gsma $1 vim/bundle/${${${1##*/}%.git}#vim-}
}
gsmrm() {
  # Remove a git submodule
  [ x$1 = x ] && { echo "Remove which submodule?"; return 1;}
  [ -d "$1" ] || { echo "Submodule $1 not found."; return 2;}
  [ -f .gitmodules ] || { echo ".gitmodules not found."; return 3;}
  git diff --cached --exit-code > /dev/null || { echo "Index is not clean."; return 1 ; }
  # test for clean .gitmodules
  git diff --exit-code .gitmodules > /dev/null || { echo ".gitmodules is not clean."; return 2 ; }
  if [[ -f Makefile ]]; then
    git diff --exit-code Makefile > /dev/null || { echo "Makefile is not clean."; return 2 ; }
  fi

  # remove submodule entry from .gitmodules and .git/config (after init/sync)
  git config -f .git/config --remove-section submodule.$1
  git config -f .gitmodules --remove-section submodule.$1
  # tempfile=$(tempfile)
  # awk "/^\[submodule \"${1//\//\\/}\"\]/{g=1;next} /^\[/ {g=0} !g" .gitmodules >> $tempfile
  # mv $tempfile .gitmodules
  git rm --cached $1
  git add .gitmodules
  
  if [[ -f Makefile ]]; then
    # Add the module to the `migrate` task in the Makefile and increase its name:
    grep -q "rm_bundles=.*$1" Makefile || sed -i "s:	rm_bundles=\"[^\"]*:\0 $1:" Makefile
    i=$(( $(grep '^.stamps/submodules_rm' Makefile | cut -f3 -d. | cut -f1 -d:) + 1 ))
    sed -i "s~\(.stamps/submodules_rm\).[0-9]\+~\1.$i~" Makefile
    git add Makefile
  fi
  echo "NOTE: changes staged, not committed."
  echo "You might want to 'rm $1' now or run the migrate task."
}

# Git and svn mix
alias git-svn-dcommit-push='git svn dcommit && git push github master:svntrunk'
compdef git-svn-dcommit-push=git
alias gsvnup='git svn fetch && git stash && git svn rebase && git stash pop'

alias gsr='git svn rebase'
alias gsd='git svn dcommit'
#
# Will return the current branch name
# Usage example: git pull origin $(current_branch)
#
function current_branch() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo ${ref#refs/heads/}
}

# these aliases take advantage of the previous function
alias ggpull='git pull origin $(current_branch)'
compdef _git ggpull=git-pull

ggpush() {
  local -h remote branch
  local -ha args git_opts

  # get args (skipping options)
  for i; do
    [[ $i == -* ]] && git_opts+=($i) || args+=($i)
    [[ $i == -h ]] && { echo "Usage: ggpush [--options...] [remote (Default: tracking branch / github.user)] [branch (Default: current)]"; return; }
  done

  branch=${args[2]-$(current_branch)}
  remote=${args[1]}
  if [[ -z $remote ]]; then
    # XXX: may resolve to "origin/develop" for new local branches..
    remote=${$(command git rev-parse --verify $branch@{upstream} \
        --symbolic-full-name 2>/dev/null)/refs\/remotes\/}
    remote=${remote%/$branch}

    if [[ -z $remote ]]; then
      remote=$(command git config github.user)
      if ! [[ -z $remote ]]; then
        # Verify remote from github.user:
        if ! command git ls-remote --exit-code $remote &> /dev/null; then
          echo "NOTE: remote for github.user does not exist ($remote)."
          remote=
        fi
      fi
      if [[ -z $remote ]]; then
        echo "ERR: cannot determine remote."
        return 1
      fi
      echo "WARN: using remote from github.user: $remote"
      echo "      Using '-u' to set upstream."
      if (( ${git_opts[(i)-u]} > ${#git_opts} )); then
        git_opts+=(-u)
      fi
    fi
  fi

  echo "Pushing to $remote:$branch.."
  [[ -z $branch ]] && { echo "No current branch (given or according to 'current_branch').\nAre you maybe in a rebase, or not in a Git repo?"; return 1; }

  # TODO: git push ${1-@{u}} $branch
  local -a cmd
  cmd=(git push $git_opts $remote $branch)
  echo $cmd
  $=cmd
}
compdef _git ggpush=git-push

alias ggpnp='git pull origin $(current_branch) && git push origin $(current_branch)'
compdef ggpnp=git
#
# Setup wrapper for git's editor. It will use just core.editor for other
# files (e.g. patch editing in `git add -p`).
export GIT_EDITOR=vim-for-git
