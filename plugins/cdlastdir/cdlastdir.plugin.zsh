#!/bin/zsh
#
# Remember current working directory (cwd) in the file named by
# $_zsh_plugin_lastdir (via chpwd hook) and change to it during startup.
#

_zsh_plugin_lastdir=~/.lastdir

[ -f $_zsh_plugin_lastdir ] && cd $(< $_zsh_plugin_lastdir)

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_update_lastdir
chpwd_update_lastdir () {
	pwd > $_zsh_plugin_lastdir
}
