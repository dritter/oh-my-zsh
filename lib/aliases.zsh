# Push and pop directories on directory stack
alias pu='pushd'
alias po='popd'


# Super user
alias _='sudo'

#alias g='grep -in'

# Show history
alias history='fc -l 1'

# List direcory contents
alias lsa='ls -lah'
alias l='ls -la'
alias ll='ls -l'
alias sl=ls # often screw this up

alias afind='ack-grep -il'

# "fast find": filter out any dotfiles
alias ffind='find -mindepth 1 -name ".*" -prune'

alias x=extract
