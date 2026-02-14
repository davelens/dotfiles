###############################################################################
# Shell options (shopt) and settings (set) that configure bash behavior.
###############################################################################

# General case-insensitive globbing
shopt -s nocaseglob

# Do not complete when accidentally pressing tab on an empty line.
shopt -s no_empty_cmd_completion

# Do not overwrite files when redirecting using ">".
# Note that you can still override this with ">|".
set -o noclobber
