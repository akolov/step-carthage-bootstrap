#!/bin/bash

THIS_SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${THIS_SCRIPTDIR}/_bash_utils/utils.sh"
source "${THIS_SCRIPTDIR}/_bash_utils/formatted_output.sh"

# ------------------------------
# --- Utils - CleanUp

is_build_action_success=0
function finalcleanup {
  echo "-> finalcleanup"
  local fail_msg="$1"

  # unset UUID
  # rm "${CONFIG_provisioning_profiles_dir}/${PROFILE_UUID}.mobileprovision"
  # Keychain have to be removed - it's password protected
  #  and the password is only available in this step!
  keychain_fn "remove"

  # # Remove downloaded files
  # rm ${CERTIFICATE_PATH}
}

function CLEANUP_ON_ERROR_FN {
  local err_msg="$1"
  finalcleanup "${err_msg}"
}
set_error_cleanup_function CLEANUP_ON_ERROR_FN

# ------------------------------
# --- Utils - Keychain

function keychain_fn {
  if [[ "$1" == "add" ]] ; then
    # LC_ALL: required for tr, for more info: http://unix.stackexchange.com/questions/45404/why-cant-tr-read-from-dev-urandom-on-osx
    # export KEYCHAIN_PASSPHRASE="$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

    # Create the keychain
    print_and_do_command_exit_on_error security -v create-keychain -p "${KEYCHAIN_PASSPHRASE}" "${BITRISE_KEYCHAIN}"

    # Import to keychain
    print_and_do_command_exit_on_error security -v import "${CERTIFICATE_PATH}" -k "${BITRISE_KEYCHAIN}" -P "${XCODE_BUILDER_CERTIFICATE_PASSPHRASE}" -A

    # Unlock keychain
    print_and_do_command_exit_on_error security -v set-keychain-settings -lut 72000 "${BITRISE_KEYCHAIN}"
    print_and_do_command_exit_on_error security -v list-keychains -s "${BITRISE_KEYCHAIN}"
    print_and_do_command_exit_on_error security -v list-keychains
    print_and_do_command_exit_on_error security -v default-keychain -s "${BITRISE_KEYCHAIN}"
    print_and_do_command_exit_on_error security -v unlock-keychain -p "${KEYCHAIN_PASSPHRASE}" "${BITRISE_KEYCHAIN}"
  elif [[ "$1" == "remove" ]] ; then
    print_and_do_command_exit_on_error security -v delete-keychain "${BITRISE_KEYCHAIN}"
  fi
}

# ------------------------------
# --- Configs

CONFIG_provisioning_profiles_dir="${HOME}/Library/MobileDevice/Provisioning Profiles"
CONFIG_tmp_profile_dir="${HOME}/tmp_profiles"

# ------------------------------
# --- Main

# --- Create directory structure
print_and_do_command_exit_on_error mkdir -p "${CONFIG_provisioning_profiles_dir}"
print_and_do_command_exit_on_error mkdir -p "${CONFIG_tmp_profile_dir}"
print_and_do_command_exit_on_error mkdir -p "${XCODE_BUILDER_CERTIFICATES_DIR}"

write_section_to_formatted_output "# Configuration"

# --- Get certificate
echo "---> Downloading Certificate..."
export CERTIFICATE_PATH="${XCODE_BUILDER_CERTIFICATES_DIR}/Certificate.p12"
print_and_do_command curl -Lfso "${CERTIFICATE_PATH}" "${XCODE_BUILDER_CERTIFICATE_URL}"
cert_curl_result=$?
if [ ${cert_curl_result} -ne 0 ]; then
  echo " (i) First download attempt failed - retry..."
  sleep 5
  print_and_do_command_exit_on_error curl -Lfso "${CERTIFICATE_PATH}" "${XCODE_BUILDER_CERTIFICATE_URL}"
fi
echo "CERTIFICATE_PATH: ${CERTIFICATE_PATH}"
if [[ ! -f "${CERTIFICATE_PATH}" ]]; then
  finalcleanup "CERTIFICATE_PATH: File not found - failed to download"
  exit 1
else
  echo " -> CERTIFICATE_PATH: OK"
fi

# LC_ALL: required for tr, for more info: http://unix.stackexchange.com/questions/45404/why-cant-tr-read-from-dev-urandom-on-osx
keychain_pass="$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
export KEYCHAIN_PASSPHRASE="${keychain_pass}"
keychain_fn "add"


# Get identities from certificate
export CERTIFICATE_IDENTITY=$(security find-certificate -a ${BITRISE_KEYCHAIN} | grep -Ei '"labl"<blob>=".*"' | grep -oEi '=".*"' | grep -oEi '[^="]+' | head -n 1)
echo "CERTIFICATE_IDENTITY: $CERTIFICATE_IDENTITY"


# --- Get provisioning profile(s)
xcode_build_param_prov_profile_UUID=""
echo "---> Provisioning Profile handling..."
IFS='|' read -a prov_profile_urls <<< "${XCODE_BUILDER_PROVISION_URL}"
prov_profile_count="${#prov_profile_urls[@]}"
echo " (i) Provided Provisioning Profile count: ${prov_profile_count}"
for idx in "${!prov_profile_urls[@]}"
do
  a_profile_url="${prov_profile_urls[idx]}"
  echo " -> Downloading Provisioning Profile (${idx}): ${a_profile_url}"

  a_prov_profile_tmp_path="${CONFIG_tmp_profile_dir}/profile-${idx}.mobileprovision"
  echo " (i) a_prov_profile_tmp_path: ${a_prov_profile_tmp_path}"
  print_and_do_command curl -Lfso "${a_prov_profile_tmp_path}" "${a_profile_url}"
  prov_profile_curl_result=$?
  if [ ${prov_profile_curl_result} -ne 0 ]; then
    echo " (i) First download attempt failed - retry..."
    sleep 5
    print_and_do_command_exit_on_error curl -Lfso "${a_prov_profile_tmp_path}" "${a_profile_url}"
  fi
  if [[ ! -f "${a_prov_profile_tmp_path}" ]] ; then
    finalcleanup "a_prov_profile_tmp_path: File not found - failed to download"
    exit 1
  fi

  # Get UUID & install provisioning profile
  a_profile_uuid=$(/usr/libexec/PlistBuddy -c "Print UUID" /dev/stdin <<< $(/usr/bin/security cms -D -i "${a_prov_profile_tmp_path}"))
  fail_if_cmd_error "Failed to get UUID from Provisioning Profile: ${a_prov_profile_tmp_path} | Most likely the Certificate can't be used with this Provisioning Profile."
  echo " (i) a_profile_uuid: ${a_profile_uuid}"
  a_provisioning_profile_file_path="${CONFIG_provisioning_profiles_dir}/${a_profile_uuid}.mobileprovision"
  print_and_do_command_exit_on_error mv "${a_prov_profile_tmp_path}" "${a_provisioning_profile_file_path}"

  if [[ "${prov_profile_count}" == "1" ]] ; then
    # force use it (specify it as a build param)
    xcode_build_param_prov_profile_UUID="${a_profile_uuid}"
  fi
done
echo " (i) Available Provisioning Profiles:"
print_and_do_command_exit_on_error ls -l "${CONFIG_provisioning_profiles_dir}"

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

export CODE_SIGN_IDENTITY="${CERTIFICATE_IDENTITY}"
export PROVISIONING_PROFILE="${xcode_build_param_prov_profile_UUID}"
export OTHER_CODE_SIGN_FLAGS="--keychain ${BITRISE_KEYCHAIN}"

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

  print_and_do_command_exit_on_error carthage bootstrap --platform "$CARTHAGE_PLATFORM" --verbose

  if [ $? -ne 0 ] ; then
    write_section_to_formatted_output "* Could not bootstrap cartfile: ${cartfile}"
    exit 1
  fi
  echo_string_to_formatted_output "* Bootstrapped cartfile: ${cartfile}"
done
unset IFS

write_section_to_formatted_output "**${cartcount} cartfile(s) found and installed**"

finalcleanup

exit $?
