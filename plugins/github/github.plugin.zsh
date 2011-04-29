# add github completion function to path
if [ "$commands[(I)hub]" ] && [ "$commands[(I)ruby]" ]; then
	# eval `hub alias -s zsh`
	function git(){hub "$@"}
fi

