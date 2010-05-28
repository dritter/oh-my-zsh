# Use VIM keymap
bindkey -v

# Re-add Ctrl-R
bindkey -M viins '^r' history-incremental-search-backward
bindkey -M vicmd '^r' history-incremental-search-backward

# Edit current line in $EDITOR
autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
bindkey -M vicmd 'u' undo # stacked undo!
bindkey -M vicmd 'q' push-line
bindkey -M viins 'jj' vi-cmd-mode
bindkey -M viins ' ' magic-space
bindkey -M viins '\C-i' complete-word

# insert key
bindkey '\e[2~' overwrite-mode
# delete key
bindkey '\e[3~' delete-char

# Special keys handling, at least required for delete-char with "bindkey -v".
# Via http://wiki.archlinux.org/index.php/Zsh#Key_Bindings
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "\e[5~" beginning-of-history
bindkey "\e[6~" end-of-history
bindkey "\e[3~" delete-char
bindkey "\e[2~" quoted-insert
bindkey "\e[5C" forward-word
bindkey "\eOc" emacs-forward-word
bindkey "\e[5D" backward-word
bindkey "\eOd" emacs-backward-word
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word
# for rxvt
bindkey "\e[8~" end-of-line
bindkey "\e[7~" beginning-of-line
# for non RH/Debian xterm, can't hurt for RH/Debian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line


# some more, via http://github.com/blueyed/dotfiles/blob/6750c9c9bc82f9ce9d727e026817ed48edb40ef1/zsh/config
bindkey '^[^[[D' backward-word
bindkey '^[^[[C' forward-word
bindkey '^[[5D' beginning-of-line
bindkey '^[[5C' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[^N' newtab
bindkey '^?' backward-delete-char 
