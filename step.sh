#!/bin/bash

THIS_SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${THIS_SCRIPTDIR}/_bash_utils/utils.sh"
source "${THIS_SCRIPTDIR}/_bash_utils/formatted_output.sh"

# init / cleanup the formatted output
echo "" > "${formatted_output_file_path}"

if [ -z "${BITRISE_SOURCE_DIR}" ]; then
  write_section_to_formatted_output "# Error"
  write_section_start_to_formatted_output '* BITRISE_SOURCE_DIR input is missing'
  exit 1
fi

cd "${BITRISE_SOURCE_DIR}"

if ! hash carthage 2>/dev/null; then
  write_section_start_to_formatted_output "# Installing Carthage"

  print_and_do_command_exit_on_error brew install carthage

  if [ $? -ne 0 ]; then
	  write_section_to_formatted_output "# Error"
	  write_section_start_to_formatted_output '* Failed to install Carthage'
	  exit 1
  fi

  write_section_start_to_formatted_output "## Installed Carthage version"
  carthage_version=$(carthage version)
  write_section_start_to_formatted_output "    ${carthage_version}"

else
  write_section_to_formatted_output "*Skipping Carthage installation*"
fi

write_section_to_formatted_output "### Searching for cartfiles and bootstrapping the found ones"

if [ -n "${BITRISE_SOURCE_DIR}" ]; then
  write_section_to_formatted_output "# Using provisioning profile $CARTHAGE_PROVISIONING_PROFILE"
  export PROVISIONING_PROFILE="$CARTHAGE_PROVISIONING_PROFILE"
fi

for cartfile in $(find . -type f -iname 'Cartfile')
do
  cartcount=$[cartcount + 1]
  echo " (i) Cartfile found at: ${cartfile}"
  curr_cartfile_dir=$(dirname "${cartfile}")
  curr_cartfile_basename=$(basename "${cartfile}")
  echo " (i) Cartfile directory: ${curr_cartfile_dir}"

  echo
  echo " ===> Carthage bootstrap: ${cartfile}"
  cd "${curr_cartfile_dir}"
  fail_if_cmd_error "Failed to cd into dir: ${curr_cartfile_dir}"

  carthage bootstrap --platform "$CARTHAGE_PLATFORM" --verbose

  fail_if_cmd_error "Failed to carthage bootstrap"


  if [ $? -ne 0 ] ; then
    write_section_to_formatted_output "* Could not bootstrap cartfile: ${cartfile}"
    exit 1
  fi
  echo_string_to_formatted_output "* Bootstrapped cartfile: ${cartfile}"
done
unset IFS

write_section_to_formatted_output "**${cartcount} cartfile(s) found and installed**"

exit $?
