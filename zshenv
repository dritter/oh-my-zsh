setopt noglobalrcs


# PATH handling (both for login, interactive and "other" shells):

# Add binaries from gems to path
path+=(/var/lib/gems/*/bin(NA))

# Add superuser binaries to path
path+=(/sbin /usr/sbin)

# Add GNU coreutils to path on MacOS
if [[ -n $commands[brew] ]]; then
  path=($(brew --prefix coreutils)/libexec/gnubin $path)
fi

path=(~/.dotfiles/usr/bin ~/bin /usr/local/bin /usr/local/sbin $path)

# Add /usr/local/*/bin to path (e.g. /usr/local/apache2/bin, this is used @bp)
path+=(/usr/local/*/bin(NA) /opt/*/bin(NA))

# Add any custom directories, which might exist
path+=(/opt/eclipse(NA))


# make path/PATH entries unique
typeset -U path


export EDITOR=vim
export GPGKEY='3FE63E00'

