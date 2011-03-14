# Aliases
#alias g='git' # used for 'gvim --remote'
alias ga='git add'
alias gae='git add --edit'
alias gco='git checkout'
alias gst='git status'
alias gl='git l'
alias glg='git log --stat --max-count=5'
alias gup='git fetch && git rebase'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gdc='git diff --cached'
alias gdv='git diff -w "$@" | vim -R -'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gb='git branch'
alias gba='git branch -a'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gsm='git submodule'
alias gbl='git blame'
alias gr='git remote'
# "git submodule commit":
gsmc() { [ x$1 = x ] && { echo "Commit update to which submodule?"; return 1;} || git submodule|grep -q "$1" || { echo "Submodule $1 not found."; return 2; } && git ci -m "Update submodule $1." "$1" }
# "git submodule add":
gsma() { git submodule add "$1" "$2" && git commit -m "Add submodule $2." }

# Git and svn mix
alias git-svn-dcommit-push='git svn dcommit && git push github master:svntrunk'

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
alias ggpush='git push origin $(current_branch)'
alias ggpnp='git pull origin $(current_branch) && git push origin $(current_branch)'
