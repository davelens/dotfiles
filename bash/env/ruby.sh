###############################################################################
# Env settings and exports related to Ruby - This gets its own section! <3
###############################################################################

# Configure the garbage collector for local development.
# Basically these following settings reduce interruptions due to GC.
# The aim is to improve request/response time in local development.
export RUBY_GC_HEAP_INIT_SLOTS=80000          # Larger initial heap (default is lowish)
export RUBY_GC_HEAP_FREE_SLOTS=20000          # Keep more free slots to reduce GC runs
export RUBY_GC_HEAP_GROWTH_FACTOR=1.25        # Less heap expansion (default = 1.8!)
export RUBY_GC_HEAP_GROWTH_MAX_SLOTS=40000    # Limit max heap growth per step
export RUBY_GC_MALLOC_LIMIT=128000000         # Delay GC runs for memory allocations
export RUBY_GC_MALLOC_LIMIT_MAX=256000000     # Wait longer to trigger GC
export RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=1.2 # Bigger, gradual malloc limits
# No automatic garbage collection when requiring.
# Prevent garbage collection from interfering during gem loading.
# Don't compact the heap (useful for long-running processes).
export RUBY_GC_AUTO_COMPACT=0
export RUBY_GC_PROFILER=0 # No unnecessary profiling overhead.
# 3.1+ provides YJIT to give us a speed boost.
export RUBY_YJIT_ENABLE=1
export RUBY_YJIT_STATS=0
export RUBY_YJIT_MIN_CODE_SIZE=16384
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
