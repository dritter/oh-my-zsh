# Auto-expand "..." to "../..", "...." to "../../.." etc.
# It skips certain commands (git, tig, p4).
#
# resolve-alias is defined in a separate function.

local MATCH # keep the regex match from leaking to the environment.

# Skip pasted text.
if (( PENDING > 0 )); then
  zle self-insert
  return
fi

if [[ $LBUFFER =~ '(^|/| |	|'$'\n''|\||;|&)\.\.$' ]] \
  && ! [[ $(resolve-alias $LBUFFER) =~ '^(git|tig|p4)' ]]; then
  LBUFFER+=/
  zle self-insert
  zle self-insert
else
  zle self-insert
fi
