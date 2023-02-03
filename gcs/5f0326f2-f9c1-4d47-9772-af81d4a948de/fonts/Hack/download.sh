#!/usr/bin/env bash

# Set variables
REQUIREMENTS="awk curl fc-cache mkdir mktemp unlink unzip"
CURRENT_SCRIPT=$(basename "${BASH_SOURCE[0]}")
CURRENT_DIR="$(cd -P -- "$(dirname -- "$(command -v -- "$0" || true)")" && pwd -P)"
readonly REQUIREMENTS CURRENT_SCRIPT CURRENT_DIR

LATEST_RELEASE_INFO="https://api.github.com/repos/source-foundry/Hack/releases/latest"
readonly LATEST_RELEASE_INFO

say() {
  one_line='' col=''
  while [ -n "$1" ]; do
    case "$1" in
    -normal) col="\033[00m" ;;
    -black) col="\033[30;01m" ;;
    -red) col="\033[31;01m" ;;
    -green) col="\033[32;01m" ;;
    -yellow) col="\033[33;01m" ;;
    -blue) col="\033[34;01m" ;;
    -magenta) col="\033[35;01m" ;;
    -cyan) col="\033[36;01m" ;;
    -white) col="\033[37;01m" ;;
    -arrow1) col="\033[32;01m➜ \033[0m" ;;
    -arrow2) col="\033[32;01m» \033[0m" ;;
    -n)
      one_line=1
      shift
      continue
      ;;
    *)
      printf '%s' "${*}"
      shift
      continue
      ;;
    esac
    shift
    printf "%s${col}"
    printf "%s" "${*}"
    printf "\033[00m"
    shift
  done
  [ -z "${one_line}" ] && printf "\n"
}

# Cleanup working directories
_cleanup() {
  if [ -d "${*}" ]; then
    #say -normal "Removing directory: ${*}"
    rm -rf "${*}" || err "Unable to remove directory: ${*}"
  elif [ -f "${*}" ]; then
    #say -normal "Removing file: ${*}"
    unlink "${*}" || err "Unable to unlink: ${*}"
  fi
}

# Print error message to STDERR and exit
err() {
  _cleanup "${TEMP_RELEASE_DIR}" >/dev/null 2>&1
  say -red "${*}" >&2
  exit 1
}

# Help function
_help() {
  say -n -green "Basic usage: "
  say "$CURRENT_SCRIPT [options]"
  say "$CURRENT_SCRIPT -i, --install"
  say "$CURRENT_SCRIPT -h, --help"
  return 0
}

# Ensure requirements
_requirements() {
  say -n -cyan "Dependencies: "
  for tool in ${REQUIREMENTS}; do
    say -n "${tool}..."
    if command -v "${tool}" >/dev/null 2>&1; then
      say -n -green " ✔ "
    else
      err " ✘ "
    fi
  done
}

# Download URL
_download() {
  url="${1}"
  save_as="${2}"
  curl -sL "${1}" -o "${save_as}" || err "Unable to download: ${url}"
}

# Generate temporary filename
_mktemp_file() { mktemp; }

# Get item from latest release data
_get_item() {
  item="${1}"
  read_from="${2}"
  awk -F '"' "/${item}/ {print \$4}" "${read_from}"
}

# Extract fonts archive
_extract() {
  archive="${1}"
  extract_to="${2}"
  unzip -o "${archive}" -d "${extract_to}" >/dev/null 2>&1
}

# Prepare fonts and release directories.
_prepare_fonts() {
  TEMP_LATEST_INFO=$(_mktemp_file)
  TEMP_RELEASE_DIR=$(mktemp -d)
  TEMP_FONTS_ARCHIVE_1=$(_mktemp_file)
  TEMP_FONTS_ARCHIVE_2=$(_mktemp_file)

  say -normal
  say -n -cyan "Retrieving latest release info: "
  say -normal "${LATEST_RELEASE_INFO}"
  _download "${LATEST_RELEASE_INFO}" "${TEMP_LATEST_INFO}"

  TAG_NAME=$(_get_item "tag_name" "${TEMP_LATEST_INFO}")
  say -n -cyan "Latest release: "
  say -green "${TAG_NAME}"

  BROWSER_URL_1=$(_get_item "browser_download_url.*webfonts.zip" "${TEMP_LATEST_INFO}")
  BROWSER_URL_2=$(_get_item "browser_download_url.*ttf.zip" "${TEMP_LATEST_INFO}")
  say -n -cyan "Downloading: "
  say -normal "${BROWSER_URL_1}"
  say -normal "${BROWSER_URL_2}"
  _download "${BROWSER_URL_1}" "${TEMP_FONTS_ARCHIVE_1}"
  _download "${BROWSER_URL_2}" "${TEMP_FONTS_ARCHIVE_2}"

  LATEST_RELEASE_DIR="${CURRENT_DIR}/${TAG_NAME}"

  if [ ! -d "${LATEST_RELEASE_DIR}" ]; then
    say -n -cyan "Creating directories: "
    say -normal "${LATEST_RELEASE_DIR}"
    mkdir -p "${LATEST_RELEASE_DIR}" >/dev/null 2>&1 || err "Unable to create fonts directory: ${LATEST_RELEASE_DIR}"
  fi
}

# Build fonts cache
_build_fonts_cache() { fc-cache -f || err "Unable to build fonts cache"; }

_prepare() {
  _requirements
  _prepare_fonts

  say -n -cyan "Extracting to: "
  say -normal "${TEMP_RELEASE_DIR}"
  _extract "${TEMP_FONTS_ARCHIVE_1}" "${TEMP_RELEASE_DIR}"
  _extract "${TEMP_FONTS_ARCHIVE_2}" "${TEMP_RELEASE_DIR}"

  if [ -d "${TEMP_RELEASE_DIR}" ]; then
    if [ -d "${TEMP_RELEASE_DIR}/web" ]; then
      say -green "Updating webfonts..."
      mv -un "${TEMP_RELEASE_DIR}/web" "${LATEST_RELEASE_DIR}"
    fi
    if [ -d "${TEMP_RELEASE_DIR}/ttf" ]; then
      say -green "Updating ttf..."
      mv -un "${TEMP_RELEASE_DIR}/ttf" "${LATEST_RELEASE_DIR}"
    fi
    say -n -cyan "Installed to: "
    say -normal "${LATEST_RELEASE_DIR}"
  else
    err "Unable to find directory: ${TEMP_RELEASE_DIR}"
  fi
  say -cyan "Cleaning up..."
  _cleanup "${TEMP_LATEST_INFO}"
  _cleanup "${TEMP_FONTS_ARCHIVE_1}"
  _cleanup "${TEMP_FONTS_ARCHIVE_2}"
  return 0
}

_do_options() {
  [ $# = 0 ] && _help
  ex_code=$?
  while [ $# -gt 0 ]; do
    case "$1" in
    -h | --help)
      _help
      ex_code=$?
      ;;
    -i | --install)
      _prepare "$@"
      ex_code=$?
      ;;
    *) err "Unknown option." ;;
    esac
    shift
  done
  return "${ex_code:-0}"
}

main() {
  _do_options "$@"
  [ -n "${ex_code}" ] && exit "${ex_code}"
}

while true; do
  main "$@"
done
