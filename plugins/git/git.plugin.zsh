# Aliases
#alias g='git' # used for 'gvim --remote'
alias ga='git add'
alias gae='git add --edit'
alias gb='git branch'
alias gba='git branch -a'
alias gbl='git blame'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gcl='git clone --recursive'
alias gco='git checkout'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gd='git diff --submodule'
alias gdc='git diff --cached'
gdv() { git diff -w "$@" | view - }
compdef _git gdv=git-diff
alias gl='git l'
alias glg='git log --stat --max-count=5'
alias glgg='git log --graph --max-count=5'
alias gls='git ls-files'
alias glsu='git ls-files -o --exclude-standard'
alias gp='git push'
alias gpl='git pull'
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
  if [[ $summary == "" ]] ; then
    echo "Submodule $1 not changed."; return 3
  fi
  if [[ $summary == fatal:* ]] ; then
    echo $summary ; return 4
  fi
  summary=( ${(f)summary} )

  # TODO: check that commits are pushed?!
  # relevant?! echo $summary | grep -o "Warn: $1 doesn't contain commit" && return 3

  git commit -m "Update submodule $1 ${${(ps: :)summary[1]}[3]}"$'\n\n'"${(F)summary}" "$1"
}
# "git submodule add":
gsma() {
  git diff --cached --exit-code > /dev/null || { echo "Index is not clean."; return 1 ; }
  git submodule add "$1" "$2" && \
  summary=$(git submodule summary "$2") && \
  summary=( ${(f)summary} ) && \
  git commit -m "Add submodule $2 @${${${(ps: :)summary[1]}[3]}/*.../}"$'\n\n'"${(F)summary}" "$2" .gitmodules && \
  git submodule update --init --recursive "$2"
}
gsmrm() {
  # Remove a git submodule
  [ x$1 = x ] && { echo "Remove which submodule?"; return 1;}
  [ -d "$1" ] || { echo "Submodule $1 not found."; return 2;}
  [ -f .gitmodules ] || { echo ".gitmodules not found."; return 3;}
  # remove submodule entry from .gitmodules
  tempfile=$(tempfile)
  awk "/^\[submodule \"${1//\//\\/}\"\]/{g=1;next} /^\[/ {g=0} !g" .gitmodules >> $tempfile
  mv $tempfile .gitmodules
  git rm --cached $1
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
compdef ggpull=git
alias ggpush='git push origin $(current_branch)'
compdef ggpush=git
alias ggpnp='git pull origin $(current_branch) && git push origin $(current_branch)'
compdef ggpnp=git
# Setup wrapper for git's editor. It will use just core.editor for other
# files (e.g. patch editing in `git add -p`).
export GIT_EDITOR=vim-for-git
