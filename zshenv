setopt noglobalrcs

# PATH handling (both for login, interactive and "other" shells):

# Use wrappers to append/prepend PATH elements only if they are
# missing. This helps to keep VirtualEnv's path at the front.
# (in case of using tmux after `workon`, where each window spawns a new shell)
append_path_if_not_in_already() {
  for i; do
    # echo "Check: $i" >> /tmp/O
    (( ${path[(i)$i]} <= ${#path} )) && continue
    # echo "Add: $i" >> /tmp/O
    path+=($i)
  done
}
prepend_path_if_not_in_already() {
  for i; do
    # echo "Check: $i" >> /tmp/O
    (( ${path[(i)$i]} <= ${#path} )) && continue
    # echo "Prepend: $i" >> /tmp/O
    path=($i $path)
  done
}

# Add superuser binaries to path
append_path_if_not_in_already /sbin /usr/sbin

# Add GNU coreutils to path on MacOS
if [[ -n $commands[brew] ]]; then
  prepend_path_if_not_in_already $(brew --prefix coreutils)/libexec/gnubin
fi

prepend_path_if_not_in_already /usr/local/bin /usr/local/sbin
prepend_path_if_not_in_already ~/.dotfiles/usr/bin ~/bin
# For pipsi:
prepend_path_if_not_in_already ~/.local/bin

# Add various "bin" directories to $path
# TODO: might add both /usr/local/apache2_2.2.16/bin /usr/local/apache2_2.2.24/bin to path!
#       Reverse-sort as a workaround?
#       Or only use symlinks (apache2 points there)
# NOTE: /usr/local/apache2/bin etc get setup @bp via /etc/profile.d/ already.
# for i in /usr/local/*(N/:A) /opt/*(N/:A) /var/lib/gems/*(N/:A) ; do
for i in /var/lib/gems/*(N/:A) ; do
  test -d $i/bin || continue
  append_path_if_not_in_already $i/bin
done

# Add any custom directories, which might exist
for i in /opt/eclipse ; do
  test -d $i || continue
  append_path_if_not_in_already $i
done

# Add specific paths for root; used on diskstation
if [[ $USER == root ]]; then
  for i in /opt/sbin /usr/syno/bin ; do
    test -d $i || continue
    path+=($i)
  done
fi
unset i

# Make path/PATH entries unique. Use '-g' for sourcing it from a function.
typeset -gU path


[ -x /usr/local/bin/vim ] && export EDITOR=/usr/local/bin/vim || export EDITOR=vim
export GPGKEY='3FE63E00'

# Setup pyenv (with completion for zsh).
# It gets done also in ~/.profile, but that does not cover completion and
# ~/.profile is not sourced for real virtual consoles (VTs).
if [ -d ~/.pyenv ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  # prepend_path_if_not_in_already $PYENV_ROOT/bin
  PATH="$PYENV_ROOT/bin:$PATH"
  # prepend_path_if_not_in_already $PYENV_ROOT/shims

  # Setup pyenv function and completion.
  # NOTE: moved from ~/.zshrc to fix YouCompleteMe/Python in gvim started from Firefox.
  # XXX: probably not that lazy with this forking..
  if ! type pyenv | grep -q function; then # only once!
    # if [ -n "$commands[pyenv]" ] ; then
      eval "$($PYENV_ROOT/bin/pyenv init -)"
    # fi
  fi
fi


# Source local env file if any
[ -f ~/.zshenv.local ] && source ~/.zshenv.local
