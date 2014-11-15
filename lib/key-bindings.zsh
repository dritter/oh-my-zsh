# TODO: Explain what some of this does..

bindkey -v
bindkey '\ew' kill-region
bindkey -s '\el' "ls\n"
# bindkey -s '\e.' "..\n"
bindkey '^r' history-incremental-search-backward

# up / down search in history for the current line's prefix
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
# Shift-up / Shift-down: consider first word only
bindkey '^[[1;2A' up-line-or-search
bindkey '^[[1;2B' down-line-or-search

# Remap default C-p / C-p from up-line-or-history.
bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search

bindkey "^[[H" beginning-of-line
bindkey "^[[1~" beginning-of-line
bindkey "^[OH" beginning-of-line
bindkey "^[[F"  end-of-line
bindkey "^[[4~" end-of-line
bindkey "^[OF" end-of-line
bindkey ' ' magic-space    # also do history expansion on space
bindkey '\e[2~' overwrite-mode # insert key
bindkey '\e[3~' delete-char    # delete key

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

bindkey '^[[Z' reverse-menu-complete

# Make the delete key (or Fn + Delete on the Mac) work instead of outputting a ~
bindkey '^?' backward-delete-char
bindkey "^[[3~" delete-char
bindkey "^[3;5~" delete-char
bindkey "\e[3~" delete-char

# consider emacs keybindings:

#bindkey -e  ## emacs key bindings
#
#bindkey '^[[A' up-line-or-search
#bindkey '^[[B' down-line-or-search
#bindkey '^[^[[C' emacs-forward-word
#bindkey '^[^[[D' emacs-backward-word
#
#bindkey -s '^X^Z' '%-^M'
#bindkey '^[e' expand-cmd-path
#bindkey '^[^I' reverse-menu-complete
#bindkey '^X^N' accept-and-infer-next-history
#bindkey '^W' kill-region
#bindkey '^I' complete-word
## Fix weird sequence that rxvt produces
#bindkey -s '^[[Z' '\t'
#


# from old bindkey.zsh:

# Use VIM keymap
# bindkey -v

# Re-add Ctrl-R
bindkey -M viins '^r' history-incremental-search-backward
bindkey -M vicmd '^r' history-incremental-search-backward

# Edit current line in $EDITOR
autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
bindkey -M vicmd 'u' undo # stacked undo!
bindkey -M vicmd 'q' push-line
# Map run-help also in vicmd mode.
bindkey -M vicmd "\eh" run-help
bindkey -M viins 'jk' vi-cmd-mode
# bindkey -M viins 'kj' vi-cmd-mode
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
# for non RH/Debian xterm, can't hurt for RH/Debian xterm (used by gnome-terminal)
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

# Overwrite vi-backward-kill-word, which stops at where insert mode was last entered.
bindkey '^w' backward-kill-word

# Useful bindings from emacs set.
bindkey "^X*"  expand-word
bindkey "^X^U" undo
bindkey "^Xu"  undo

autoload -U smart-insert-last-word
zle -N insert-last-assignment smart-insert-last-word
zstyle :insert-last-assignment match '[[:alpha:]][][[:alnum:]]#=*'
bindkey '\e=' insert-last-assignment

zle -N insert-last-word smart-insert-last-word
bindkey -M viins "^[." insert-last-word
