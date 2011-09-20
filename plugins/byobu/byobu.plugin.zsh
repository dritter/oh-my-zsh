# Add byobu binaries to the beginning of $PATH
path=($0:h/bin $path)

export BYOBU_PREFIX="$0:h"
