###############################################################################
# Env settings and exports related to locale/language settings.
###############################################################################

# Prefer English and use UTF-8. The loop ensures the shell uses a locale that
# supports UTF-8 encoding and matches the user's language preference.
# Confirmed functional on both macos and Arch Linux.
for lang in en_US en_GB en; do
  for encoding in UTF-8 utf8; do
    locale="${lang}.${encoding}"

    if locale -a | grep -qx "$locale"; then
      export LC_ALL="$locale" LANG="$locale"
      break 2
    fi
  done
done

unset lang encoding locale
