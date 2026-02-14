###############################################################################
# Env settings and exports related to Ruby - This gets its own section! <3
###############################################################################

# Ruby 3.3+ has significantly improved GC defaults with Variable Width
# allocation. We trust those defaults instead of manually tuning heap/malloc
# limits, like I used to.

# 3.1+ provides YJIT to give us a speed boost.
export RUBY_YJIT_ENABLE=1
# ZJIT is still new and not faster than YJIT *yet*.
# Keeping it here so I don't forget to experiment later.
# export RUBY_ZJIT_ENABLE=1

# Lower value triggers major GC (old objects) more often, reducing memory usage
# but increasing CPU load. Raise for better performance (less frequent GC),
# lower for less memory usage. Default is 2.0; 1.5 is a good starting point for
# local development.
export RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=1.5

# Make sure bootsnap caches to the right location.
export BOOTSNAP_CACHE_DIR="$XDG_CACHE_HOME"

# Don't scan for system gems when bundling.
export BUNDLE_DISABLE_SHARED_GEMS=1

# Fix annoying Spring forking errors on Apple silicon.
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# So fresh terminal windows hook spring logs into the project's log folder.
export SPRING_LOG="$PWD/log/spring.log"
export SPRING_TMP_PATH="/tmp"

# Compilation configuration options for fresh Ruby installations.
if [ -n "$BREW_PATH" ]; then
  # Configure compilation options for Ruby installs via mise/ruby-build.
  # Only add libraries that are actually installed via Homebrew.
  RUBY_CONFIGURE_OPTS=""

  # OpenSSL - SSL/TLS support
  if brew --prefix openssl &>/dev/null; then
    RUBY_CONFIGURE_OPTS+="--with-openssl-dir=$(brew --prefix openssl) "
  fi

  # Readline - IRB/console line editing support
  if brew --prefix readline &>/dev/null; then
    RUBY_CONFIGURE_OPTS+="--with-readline-dir=$(brew --prefix readline) "
  fi

  # libyaml - YAML parsing (Psych gem)
  if brew --prefix libyaml &>/dev/null; then
    RUBY_CONFIGURE_OPTS+="--with-libyaml-dir=$(brew --prefix libyaml) "
  fi

  # Remove trailing space
  RUBY_CONFIGURE_OPTS="${RUBY_CONFIGURE_OPTS% }"
  export RUBY_CONFIGURE_OPTS
fi
