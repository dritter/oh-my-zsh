# Set prefix to byobu (this should work across different shells, e.g. bash, too)
if [ -n "$BASH_SOURCE" ]; then
  SELF_PATH="$BASH_SOURCE" # required for "source .." in bash
else
  SELF_PATH="$0"
fi
export BYOBU_PREFIX=$(dirname $(readlink -f "$SELF_PATH"))
# $( cd -P -- "$(dirname -- "$(command -v -- "$SELF_PATH")")" && pwd -P )

# Add byobu binaries to the beginning of $PATH
PATH="$BYOBU_PREFIX/bin:$PATH"
