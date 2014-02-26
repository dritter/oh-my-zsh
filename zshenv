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

prepend_path_if_not_in_already ~/.dotfiles/usr/bin ~/bin /usr/local/bin /usr/local/sbin

# Add various "bin" directories to $path
# (e.g. /usr/local/apache2/bin is used @bp)
# TODO: might add both /usr/local/apache2_2.2.16/bin /usr/local/apache2_2.2.24/bin to path!
#       Reverse-sort as a workaround?
#       Or only use symlinks (apache2 points there)
for i in /usr/local/*(N/:A) /opt/*(N/:A) /var/lib/gems/*(N/:A) ; do
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

# make path/PATH entries unique
typeset -U path


[ -x /usr/local/bin/vim ] && export EDITOR=/usr/local/bin/vim || export EDITOR=vim
export GPGKEY='3FE63E00'

# Disable XON/XOFF flow control; this is required to make C-s work in Vim.
# NOTE: silence possible error when using mosh:
#       "stty: standard input: Inappropriate ioctl for device"
stty -ixon 2>/dev/null

# Source local env file if any
[ -f ~/.zshenv.local ] && source ~/.zshenv.local
