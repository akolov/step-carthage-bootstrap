#!/bin/bash

if ! hash carthage 2>/dev/null; then
  brew install carthage
fi

carthage bootstrap --platform "$CARTHAGE_PLATFORM"

exit $?
