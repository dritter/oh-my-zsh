setopt noglobalrcs


# PATH handling (both for login, interactive and "other" shells):

# Add binaries from gems to path
path+=(/var/lib/gems/1.8/bin/)

# Add superuser binaries to path
path+=(/sbin /usr/sbin)

# Add GNU coreutils to path on MacOS
if [[ -n $commands[brew] ]]; then
  path=($(brew --prefix coreutils)/libexec/gnubin $path)
fi

path=(~/.dotfiles/usr/bin ~/bin /usr/local/bin /usr/local/sbin $path)

# Add /usr/local/*/bin to path (e.g. /usr/local/apache2/bin, @bp)
for i in /usr/local/*/bin ; do
  path+=("$(readlink -f $i)")
done
unset i

# make path/PATH entries unique
typeset -U path


export EDITOR=vim
export GPGKEY='3FE63E00'

