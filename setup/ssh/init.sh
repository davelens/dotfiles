#!/usr/bin/env bash
# Compatibility with old shell startup callers: configuration is installed only
# by setup/install. Do not rewrite SSH files or select keys when sourcing this.
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  printf '%s\n' 'SSH preferences are managed by setup/install; this entry point no longer writes configuration.' >&2
  exit 1
fi
