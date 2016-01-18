#!/bin/bash
set -e

# Figure out where this script is located.
SELFDIR="`dirname \"$0\"`"
ROOTDIR="`cd \"$SELFDIR/..\" && pwd`"

# Tell Bundler where the Gemfile and gems are.
export BUNDLE_GEMFILE="$ROOTDIR/lib/vendor/Gemfile"
unset BUNDLE_IGNORE_CONFIG

# Run the actual app using the bundled Ruby interpreter, with Bundler activated.
exec "$ROOTDIR/lib/ruby/bin/ruby" -rbundler/setup  -rreadline -I$ROOTDIR/lib/app/lib "$ROOTDIR/lib/app/bin/lyp" "$@"