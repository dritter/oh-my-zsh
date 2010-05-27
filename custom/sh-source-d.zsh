# Load any files from ~/.sh/source.d/ (global to any shell)
# This includes aliases
for config_file (~/.sh/source.d/*) source $config_file
unset config_file
