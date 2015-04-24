#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! hash carthage 2>/dev/null; then
  echo "=== Will install Carthage"
  brew install carthage
fi

echo "=== Will run Carthage boostrap for platform $CARTHAGE_PLATFORM in $THIS_SCRIPT_DIR"
carthage bootstrap --platform "$CARTHAGE_PLATFORM"
echo "=== Finished running Carthage boostrap"

exit $?
