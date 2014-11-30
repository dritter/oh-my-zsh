# vim:ft=zsh ts=2 sw=2 sts=2
#
function svn_prompt_info() {
  if in_svn; then
    if [ "x$SVN_SHOW_BRANCH" = "xtrue" ]; then
      unset SVN_SHOW_BRANCH
      _DISPLAY=$(svn_get_branch_name)
    else
      _DISPLAY=$(svn_get_repo_name)
    fi
    echo "$ZSH_PROMPT_BASE_COLOR$ZSH_THEME_SVN_PROMPT_PREFIX\
$ZSH_THEME_REPO_NAME_COLOR$_DISPLAY$ZSH_PROMPT_BASE_COLOR$ZSH_THEME_SVN_PROMPT_SUFFIX$ZSH_PROMPT_BASE_COLOR$(svn_dirty)$(svn_dirty_pwd)$ZSH_PROMPT_BASE_COLOR"
    unset _DISPLAY
  fi
}


function in_svn() {
  if $(svn info >/dev/null 2>&1); then
    return 0
  fi
  return 1
}

function svn_get_repo_name() {
  if in_svn; then
    svn info | sed -n 's/Repository\ Root:\ .*\///p' | read SVN_ROOT
    svn info | sed -n "s/URL:\ .*$SVN_ROOT\///p"
  fi
}

function svn_get_branch_name() {
  _DISPLAY=$(
    svn info 2> /dev/null | \
      awk -F/ \
      '/^URL:/ { \
        for (i=0; i<=NF; i++) { \
          if ($i == "branches" || $i == "tags" ) { \
            print $(i+1); \
            break;\
          }; \
          if ($i == "trunk") { print $i; break; } \
        } \
      }'
  )
  
  if [ "x$_DISPLAY" = "x" ]; then
    svn_get_repo_name
  else
    echo $_DISPLAY
  fi
  unset _DISPLAY
}

function svn_get_rev_nr() {
  if in_svn; then
    svn info 2> /dev/null | sed -n 's/Revision:\ //p'
  fi
}

function svn_dirty_choose() {
  if in_svn; then
    root=`svn info 2> /dev/null | sed -n 's/^Working Copy Root Path: //p'`
    if $(svn status $root 2> /dev/null | grep -Eq '^\s*[ACDIM!?L]'); then
      # Grep exits with 0 when "One or more lines were selected", return "dirty".
      echo $1
    else
      # Otherwise, no lines were found, or an error occurred. Return clean.
      echo $2
    fi
  fi
}

function svn_dirty() {
  svn_dirty_choose $ZSH_THEME_SVN_PROMPT_DIRTY $ZSH_THEME_SVN_PROMPT_CLEAN
}

function svn_dirty_choose_pwd () {
  if in_svn; then
    root=$PWD
    if $(svn status $root 2> /dev/null | grep -Eq '^\s*[ACDIM!?L]'); then
      # Grep exits with 0 when "One or more lines were selected", return "dirty".
      echo $1
    else
      # Otherwise, no lines were found, or an error occurred. Return clean.
      echo $2
    fi
  fi
}

function svn_dirty_pwd () {
  svn_dirty_choose_pwd $ZSH_THEME_SVN_PROMPT_DIRTY_PWD $ZSH_THEME_SVN_PROMPT_CLEAN_PWD
}

# Function to update an SVN repository in a safe manner: first display
# diffstat (if installed), log and diff (folded), then ask about continuing
# with `svn up`.
# Optional args: $to $from (default: HEAD BASE)
function svnsafeup() {
  if [[ "$(in_svn)" != "1" ]]; then
    echo "Not in a SVN repository." 1>&2 ; return 1
  fi
  local from=${2:-BASE} to=${1:-HEAD}
  local range="$from:$to"
  local repo_id="$(svn_get_repo_name)@$(svn_get_rev_nr)"
  local diffcmd="svn diff -r $range"

  local diff="$($=diffcmd)"
  if [[ $diff == '' ]] ; then
    echo "No changes for $repo_id in range $range."
    return
  fi

  {
    echo "Diff for: $repo_id, range: $range"
    echo
    if [ $commands[diffstat] ] ; then
      diffstat=$(echo $diff | diffstat)
      echo -n "diffstat: "
      echo $diffstat | tail -n1
      echo $diffstat | sed 's/^/  /'
      echo
    fi
    echo "svn log -r $range:"
    svn log -r $range | sed 's/^/  /'
    echo
    echo "$diffcmd:"
    echo $diff | sed 's/^/  /' | sed '/^  Index: / !s/^/  /'
  } | view -c 'set foldnestmax=2 foldlevel=0 shiftwidth=2 foldmethod=indent'  -
  read "answer?continue to 'svn up'? (ctrl-c to abort, y to continue) " || return 1
  [[ $answer == "y" ]] || return 1
  currev="$(svn info | grep '^Revision:' | cut -f2 -d\ )"
  echo "Updating from revision $currev to $to.."
  svn up -r $to
}


# Aliases for svn
svnd() { svn diff "$@" | $PAGER }
svnl() { svn log "$@"  | $PAGER }


