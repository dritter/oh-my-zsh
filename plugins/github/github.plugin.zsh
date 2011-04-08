# add github completion function to path
fpath=($ZSH/plugins/github $fpath)

# Setup hub alias for git, if it is available, see http://github.com/defunkt/hub
if [ "$commands[(I)hub]" ]; then
	# eval `hub alias -s zsh`
	function git(){hub "$@"}
fi
