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

# Prefer English and use UTF-8.
printf -v available_locales ' %s ' "$(locale -a)"

for lang in en_US en_GB en; do
  for locale in "$lang".{UTF-8,utf8}; do
    if [[ "$available_locales" =~ $locale ]]; then
      export LC_ALL="$locale"
      export LANG="$lang"
      break 2
    fi
  done
done

unset available_locales lang locale
