#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! hash carthage 2>/dev/null; then
  echo "=== Will install Carthage"
  brew install carthage
fi

echo "=== Will run Carthage boostrap for platform $CARTHAGE_PLATFORM"

for cartfile in $(find . -type f -iname 'Cartfile')
do
  cartcount=$[cartcount + 1]
  echo " (i) Cartfile found at: ${cartfile}"
  curr_cartfile_dir=$(dirname "${cartfile}")
  curr_cartfile_basename=$(basename "${cartfile}")
  echo " (i) Cartfile directory: ${curr_cartfile_dir}"

  (
    echo
    echo " ===> Carthage bootstrap: ${cartfile}"
    cd "${curr_cartfile_dir}"
    carthage bootstrap --platform "$CARTHAGE_PLATFORM" --verbose
  )

  if [ $? -ne 0 ] ; then
    echo "!!! Could not bootstrap cartfile: ${cartfile}"
    exit 1
  fi
  echo "* Bootstrapped cartfile: ${cartfile}"
done
unset IFS

echo "=== Finished running Carthage boostrap"

exit $?
