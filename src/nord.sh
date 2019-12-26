#!/usr/bin/env bash
# Copyright (c) 2016-present Arctic Ice Studio <development@arcticicestudio.com>
# Copyright (c) 2016-present Sven Greb <code@svengreb.de>

# Project:    Nord GNOME Terminal
# Repository: https://github.com/arcticicestudio/nord-gnome-terminal
# License:    MIT

set -e

# Appends the given profile UUID to the profile list.
#
# @param $1 the UUID to be appended
# @return none
# @since 0.2.0
append_profile_uuid_to_list() {
  local uuid list
  uuid="$1"
  list=$(gsettings get "$GSETTINGS_PROFILELIST_PATH" list)
  gsettings set "$GSETTINGS_PROFILELIST_PATH" list "${list%]*}, '$uuid']"
}

# Writes the Nord GNOME Terminal theme colors and configurations as dconf key-value pairs to the target profile.
#
# @globread profile_name
# @return none
# @since 0.2.0
apply() {
  local \
    nord0="#2E3440" \
    nord1="#3B4252" \
    nord3="#4C566A" \
    nord4="#D8DEE9" \
    nord5="#E5E9F0" \
    nord6="#ECEFF4" \
    nord7="#8FBCBB" \
    nord8="#88C0D0" \
    nord9="#81A1C1" \
    nord11="#BF616A" \
    nord13="#EBCB8B" \
    nord14="#A3BE8C" \
    nord15="#B48EAD"
  local \
    nord0_rgb="rgb(46,52,64)"
    nord1_rgb="rgb(59,66,82)"
    nord4_rgb="rgb(216,222,233)"
    nord8_rgb="rgb(136,192,208)"

  _write palette "['$nord1', '$nord11', '$nord14', '$nord13', '$nord9', '$nord15', '$nord8', '$nord5', '$nord3', '$nord11', '$nord14', '$nord13', '$nord9', '$nord15', '$nord7', '$nord6']"
  log 4 "Applied Nord color palette"

  _write background-color "'$nord0'"
  _write foreground-color "'$nord4'"
  _write use-transparent-background "false"
  log 4 "Applied background- and foreground colors"

  _write bold-color "'$nord4'"
  _write bold-color-same-as-fg "true"
  log 4 "Applied bold color and configuration"

  _write use-theme-colors "false"
  _write use-theme-background "false"
  _write use-theme-transparency "false"
  log 4 "Applied system theme compability configuration"

  _write cursor-colors-set "true"
  _write cursor-foreground-color "'$nord1_rgb'"
  _write cursor-background-color "'$nord4_rgb'"
  log 4 "Applied cursor colors and configuration"

  _write highlight-colors-set "true"
  _write highlight-foreground-color "'$nord0_rgb'"
  _write highlight-background-color "'$nord8_rgb'"
  log 4 "Applied highlight colors and configuration"

  _write highlight-colors-set "true"
  _write highlight-foreground-color "'$nord0_rgb'"
  _write highlight-background-color "'$nord8_rgb'"
  log 4 "Applied highlight colors and configuration"

  _write "$NORD_GNOME_TERMINAL_VERSION_DCONF_KEY" "'$NORD_GNOME_TERMINAL_VERSION'"
  log 4 "Set Nord GNOME Terminal version key of the '$profile_name' profile"

  log 3 "Applied theme colors and configurations"
}

# Cleans up the script execution by unsetting declared functions and variables.
#
# @return none
# @since 0.2.0
cleanup() {
  log 4 "Cleaning up script execution by unsetting declared functions and variables"
  unset -v _cr _ct _ctb _ct_highlight _ct_primary _ctb_error _ctb_highlight _ctb_primary _ctb_success _ctb_warning
  unset -v NORD_GNOME_TERMINAL_SCRIPT_OPTS NORD_GNOME_TERMINAL_VERSION NORD_GNOME_TERMINAL_VERSION_DCONF_KEY NORD_PROFILE_VISIBLE_NAME log_level DEPENDENCIES DCONF_PROFILE_BASE_PATH GSETTINGS_PROFILELIST_PATH gnome_terminal_version profile_name profile_uuid
  unset -f append_profile_uuid_to_list apply check_migrated_version_comp cleanup clone_default_profile get_profiles get_profile_uuid_by_name log print_help validate_dependencies vercomp _write
}

# Clones the default profile, generates and saves the new UUID and adds it to the profile list.
#
# @globwrite profile_uuid
# @since 0.2.0
clone_default_profile() {
  local uuid
  uuid="$(gsettings get "$GSETTINGS_PROFILELIST_PATH" default | tr -d \')"
  profile_uuid="$(uuidgen)"
  dconf dump "$DCONF_PROFILE_BASE_PATH"/:"$uuid"/ | dconf load "$DCONF_PROFILE_BASE_PATH"/:"$profile_uuid"/
  dconf write "$DCONF_PROFILE_BASE_PATH"/:"$profile_uuid"/visible-name "'$NORD_PROFILE_VISIBLE_NAME'"
  append_profile_uuid_to_list "$profile_uuid"
  log 3 "Cloned the default profile '$uuid' with new UUID '$profile_uuid'"
}

# Prints a message with a prefixed label to STDOUT/STDERR for the given log level.
#
# When no log level is specified, "DEFAULT" is used.
# The minimum log level is defined by the "log_level" global.
#
# Log Levels:
#   0 ERROR
#   1 WARNING
#   2 SUCCESS
#   3 INFO
#   4 DEBUG
#
# @globread
#   log_level
#   _cr
#   _ct
#   _ctb
#   _ctb_error
#   _ctb_highlight
#   _ctb_primary
#   _ctb_success
#   _ctb_warning
# @return none
# @since 0.2.0
log () {
  declare -a label color
  local num_regex='^[0-9]+$'
  local level=$1
  label=([0]="[ERR]" [1]="[WARN]" [2]="[SUCCESS]" [3]="[INFO]" [4]="[DEBUG]")
  color=([0]="$_ctb_error" [1]="$_ctb_warning" [2]="$_ctb_success" [3]="$_ctb_primary" [4]="$_ctb_highlight")

  if [[ $level =~ $num_regex ]]; then
    shift
    if [[ -n ${log_level} && ${log_level} -ge ${level} ]]; then
      printf "${color[$level]}${label[$level]} ${_ct}%s${_cr}\n" "$@"
    fi
  else
    printf "${_ctb}> ${_ct}%s${_cr}\n" "$@"
  fi
}

# Validates all required dependencies.
#
# @param $1 array of required dependencies to validate
# @return 0 if all required dependencies are validated, 1 otherwise
# @since 0.2.0
validate_dependencies() {
  declare -a missing_deps deps=("${!1}")
  for exec in "${deps[@]}"; do
    if ! command -v "${exec}" > /dev/null 2>&1; then
      missing_deps+=(${exec})
    fi
  done
  if [ ${#missing_deps[*]} -eq 0 ]; then
    log 3 "Validated required dependencies: ${deps[*]}"
    return 0
  else
    log 1 "Missing required dependencies: ${_ct_highlight}${missing_deps[*]}${_cr}"
    return 1
  fi
}

# Shorthand function to write the given key-value pair to the profile.
#
# @globread DCONF_PROFILE_BASE_PATH profile_uuid
# @param $1 the profile key to be written
# @param $2 the value to be assigned to the given profile key
# @return none
# @since 0.2.0
_write() {
  local key="$1"
  local value="$2"
  dconf write "$DCONF_PROFILE_BASE_PATH/:$profile_uuid/$key" "$value"
}

# Catches terminal interrupt- and termination signals and prints a message before exiting the script execution.
#
# @return 1
# @since 0.2.0
trap 'printf "${_ctb_error}User aborted.${_cr}\n" && exit 1' SIGINT SIGTERM

# Exit hook that runs the 'cleanup' function before exiting the script.
#
# @since 0.2.0
trap cleanup EXIT

declare -a DEPENDENCIES profiles

_cr="\e[0m"
_ct="\e[0;37m"
_ctb="\e[1;37m"
_ct_highlight="\e[0;34m"
_ct_primary="\e[0;36m"
_ctb_error="\e[1;31m"
_ctb_highlight="\e[1;34m"
_ctb_primary="\e[1;36m"
_ctb_subtle="\e[1;30m"
_ctb_success="\e[1;32m"
_ctb_warning="\e[1;33m"

NORD_GNOME_TERMINAL_SCRIPT_OPTS=$(getopt -o hl:p: --long help,loglevel:,profile: -n 'nord.sh' -- "$@")
NORD_GNOME_TERMINAL_VERSION=0.1.0
NORD_GNOME_TERMINAL_VERSION_DCONF_KEY=nord-gnome-terminal-version
NORD_PROFILE_VISIBLE_NAME="Nord"
log_level=2

# List of required executable dependencies
DEPENDENCIES=(dconf expr gsettings uuidgen)

# The dconf- and GSettings paths
DCONF_PROFILE_BASE_PATH=/org/gnome/terminal/legacy/profiles:
GSETTINGS_PROFILELIST_PATH=org.gnome.Terminal.ProfilesList

# The detected GNOME Terminal version
gnome_terminal_version=

# The profile name and UUID to apply the theme on
profile_name=
profile_uuid=

if validate_dependencies DEPENDENCIES[@]; then
  clone_default_profile
  apply
  log 2 "Nord GNOME Terminal version $NORD_GNOME_TERMINAL_VERSION has been successfully applied to the newly created '$NORD_PROFILE_VISIBLE_NAME' profile"
  exit 0
else
  log 0 "Required dependencies were not fulfilled: ${DEPENDENCIES[*]}"
  exit 1
fi
