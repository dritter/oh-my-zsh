setopt noglobalrcs


# PATH handling (both for login, interactive and "other" shells):

# Add superuser binaries to path
path+=(/sbin /usr/sbin)

# Add GNU coreutils to path on MacOS
if [[ -n $commands[brew] ]]; then
  path=($(brew --prefix coreutils)/libexec/gnubin $path)
fi

path=(~/.dotfiles/usr/bin ~/bin /usr/local/bin /usr/local/sbin $path)

# Add various "bin" directories to $path
# (e.g. /usr/local/apache2/bin is used @bp)
for i in /usr/local/*(N/:A) /opt/*(N/:A) /var/lib/gems/*(N/:A) ; do
  test -d $i/bin || continue
  path+=($i/bin)
done

# Add any custom directories, which might exist
for i in /opt/eclipse ; do
  test -d $i || continue
  path+=($i)
done


# make path/PATH entries unique
typeset -U path


export EDITOR=vim
export GPGKEY='3FE63E00'

