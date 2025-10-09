###############################################################################
# Env settings and exports related to locale/language settings.
###############################################################################

# General case-insensitive globbing
shopt -s nocaseglob

# Do not complete when accidentally pressing tab on an empty line.
shopt -s no_empty_cmd_completion

# Do not overwrite files when redirecting using ">".
# Note that you can still override this with ">|".
set -o noclobber

# Prefer English and use UTF-8. The loop ensures the shell uses a locale that
# supports UTF-8 encoding and matches the user's language preference.
for lang in en_US en_GB en; do
  for encoding in UTF-8 utf8; do
    locale="${lang}.${encoding}"
    if locale -a | grep -qx "$locale"; then
      export LC_ALL="$locale"     # Overrides all other locale settings
      export LC_CTYPE="$locale"   # Set character encoding type
      export LC_COLLATE="$locale" # String sorting and comparison
      export LANG="$locale"       # Default locale for programs
      break 2
    fi
  done
done

unset lang encoding locale
